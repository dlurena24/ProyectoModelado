extends Node

const PROJECT_ID := "avatarsvsrooksproject"

# ---------- helpers ----------
func _s(v: Variant) -> String:
	if v == null:
		return ""
	var t := str(v)
	return "" if t == "<null>" else t

func _auth_headers() -> Array[String]:
	var headers: Array[String] = ["Content-Type: application/json"]
	if Firebase and Firebase.Auth and Firebase.Auth.auth:
		var a: Dictionary = Firebase.Auth.auth
		var t: String = ""
		if a.has("idtoken"):
			t = str(a["idtoken"])
		elif a.has("idToken"):
			t = str(a["idToken"])
		elif a.has("id_token"):
			t = str(a["id_token"])
		if t != "":
			headers.append("Authorization: Bearer " + t)
	return headers

func _http_json(method: int, url: String, body: Dictionary = {}) -> Dictionary:
	var req: HTTPRequest = HTTPRequest.new()
	get_tree().root.add_child(req)
	var payload: String = "" if method == HTTPClient.METHOD_GET else JSON.stringify(body)
	var err: int = req.request(url, _auth_headers(), method, payload)
	if err != OK:
		req.queue_free()
		return {"ok": false, "code": -1, "json": null, "raw": "", "error": "init failed"}
	var args: Array = await req.request_completed
	req.queue_free()
	var code: int = int(args[1])
	var text: String = (args[3] as PackedByteArray).get_string_from_utf8()
	var json: Variant = JSON.parse_string(text)
	return {"ok": code >= 200 and code < 300, "code": code, "json": json, "raw": text}

func _has_plugin() -> bool:
	return Firebase != null and Firebase.has_method("get") and Firebase.has_node("Firestore")

# ---------- convertidores REST ----------
func _fs_value(v: Variant) -> Dictionary:
	match typeof(v):
		TYPE_STRING:
			return {"stringValue": str(v)}
		TYPE_BOOL:
			return {"booleanValue": bool(v)}
		TYPE_INT:
			return {"integerValue": str(int(v))}
		TYPE_FLOAT:
			return {"doubleValue": float(v)}
		TYPE_DICTIONARY:
			return {"mapValue": {"fields": _fs_dict(v)}}
		TYPE_ARRAY:
			var vals: Array = []
			for x in (v as Array):
				vals.append(_fs_value(x))
			return {"arrayValue": {"values": vals}}
		_:
			if v is Color:
				return {"stringValue": (v as Color).to_html()}
			return {"stringValue": str(v)}

func _fs_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		out[str(k)] = _fs_value(d[k])
	return out

# ---------- USERS ----------
func get_user_profile(uid: String) -> Dictionary:
	if _has_plugin():
		var coll: Variant = Firebase.Firestore.collection("users")
		var doc: Variant = await coll.get_doc(uid)
		if doc == null:
			return {}
		return {
			"uid": uid,
			"role": _s(doc.get_value("role")),
			"username": _s(doc.get_value("username")),
			"name": _s(doc.get_value("name")),
			"profile_picture_url": _s(doc.get_value("profile_picture_url")),
			"profile_picture_path": _s(doc.get_value("profile_picture_path"))
		}
	# REST fallback
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [PROJECT_ID, uid]
	var res: Dictionary = await _http_json(HTTPClient.METHOD_GET, url)
	if not res["ok"] or res["json"] == null or not (res["json"] is Dictionary) or not (res["json"] as Dictionary).has("fields"):
		return {}
	var f: Dictionary = (res["json"] as Dictionary)["fields"]
	return {
		"uid": uid,
		"role": f.get("role", {}).get("stringValue", "user"),
		"username": f.get("username", {}).get("stringValue", ""),
		"name": f.get("name", {}).get("stringValue", ""),
		"profile_picture_url": f.get("profile_picture_url", {}).get("stringValue", ""),
		"profile_picture_path": f.get("profile_picture_path", {}).get("stringValue", "")
	}

func get_user_settings(uid: String) -> Dictionary:
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [PROJECT_ID, uid]
	var res: Dictionary = await _http_json(HTTPClient.METHOD_GET, url)
	if not res["ok"] or res["json"] == null or not (res["json"] is Dictionary) or not (res["json"] as Dictionary).has("fields"):
		return {}
	var fields: Dictionary = (res["json"] as Dictionary)["fields"]
	if not (fields.has("settings") and fields["settings"].has("mapValue")):
		return {}
	var sfields: Dictionary = fields["settings"]["mapValue"]["fields"]
	var out: Dictionary = {
		"theme": sfields.get("theme", {}).get("stringValue", "Oscuro"),
		"spotify_url": sfields.get("spotify_url", {}).get("stringValue", ""),
		"music_enabled": sfields.get("music_enabled", {}).get("booleanValue", false),
		"volume_db": int(sfields.get("volume_db", {}).get("integerValue", "0")),
		"resolution_index": int(sfields.get("resolution_index", {}).get("integerValue", "0")),
		"colors": []
	}
	if sfields.has("colors") and sfields["colors"].has("arrayValue") and sfields["colors"]["arrayValue"].has("values"):
		var arr: Array = []
		for entry in sfields["colors"]["arrayValue"]["values"]:
			arr.append(entry.get("stringValue", ""))
		out["colors"] = arr
	return out

# PATCH (merge) con updateMask para NO pisar otros campos del doc
func upsert_user(uid: String, data: Dictionary) -> bool:
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [PROJECT_ID, uid]

	# Construimos updateMask.fieldPaths con las claves top-level del body (p.ej. settings, theme_background, theme_text)
	var masks: Array[String] = []
	for k in data.keys():
		masks.append("updateMask.fieldPaths=" + String(k).uri_encode())

	if masks.size() > 0:
		url += "?" + "&".join(masks)

	var body: Dictionary = {"fields": _fs_dict(data)}
	var res: Dictionary = await _http_json(HTTPClient.METHOD_PATCH, url, body)
	return bool(res["ok"])

# Alias para actualizaciones parciales simples
func update_user_fields(uid: String, fields: Dictionary) -> bool:
	return await upsert_user(uid, fields)

# ---------- HALL OF FAME ----------
func submit_run(uid: String, username: String, time_ms: int) -> bool:
	var doc_id: String = "%s-%d" % [uid, Time.get_unix_time_from_system()]
	var data: Dictionary = {
		"uid": uid,
		"username": username,
		"time_ms": int(time_ms),
		"created_at": int(Time.get_unix_time_from_system())
	}
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/runs?documentId=%s" % [PROJECT_ID, doc_id]
	var body: Dictionary = {"fields": _fs_dict(data)}
	var res: Dictionary = await _http_json(HTTPClient.METHOD_POST, url, body)
	return bool(res["ok"])

func get_top_runs(limit_count: int = 100) -> Array:
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % PROJECT_ID
	var body: Dictionary = {
		"structuredQuery": {
			"from": [{"collectionId": "runs"}],
			"orderBy": [{"field": {"fieldPath": "time_ms"}, "direction": "ASCENDING"}],
			"limit": limit_count
		}
	}
	var res: Dictionary = await _http_json(HTTPClient.METHOD_POST, url, body)
	if not res["ok"] or res["json"] == null or not (res["json"] is Array):
		return []
	var out2: Array = []
	for row in (res["json"] as Array):
		if row is Dictionary and row.has("document"):
			var f: Dictionary = row["document"]["fields"]
			out2.append({
				"uid": f.get("uid", {}).get("stringValue", ""),
				"username": f.get("username", {}).get("stringValue", ""),
				"time_ms": int(f.get("time_ms", {}).get("integerValue", "0")),
				"created_at": int(f.get("created_at", {}).get("integerValue", "0"))
			})
	return out2
