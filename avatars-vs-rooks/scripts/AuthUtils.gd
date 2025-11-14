extends Node

const PROJECT_ID := "avatarsvsrooksproject"

# --- Validación de contraseñas (ejemplo robusto) ---
func validate_password(pwd: String) -> Dictionary:
	var errors: PackedStringArray = []
	if pwd.length() < 12:
		errors.append("- mínimo 12 caracteres")
	var re_digits: RegEx = RegEx.new(); re_digits.compile("\\d")
	var re_upper: RegEx = RegEx.new();  re_upper.compile("[A-Z]")
	var re_special: RegEx = RegEx.new(); re_special.compile("[^A-Za-z0-9]")
	if re_digits.search_all(pwd).size() < 1: errors.append("- al menos 1 dígito")
	if re_upper.search_all(pwd).size() < 1: errors.append("- al menos 1 mayúscula")
	if re_special.search_all(pwd).size() < 1: errors.append("- al menos 1 símbolo")
	return {"ok": errors.is_empty(), "errors": errors}

# --- ¿username disponible? (Firestore runQuery) ---
func is_username_available(username: String) -> bool:
	var url: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % PROJECT_ID
	var body: Dictionary = {
		"structuredQuery": {
			"from": [{"collectionId": "users"}],
			"where": {
				"fieldFilter": {
					"field": {"fieldPath": "username"},
					"op": "EQUAL",
					"value": {"stringValue": username}
				}
			},
			"limit": 1
		}
	}
	var headers: Array[String] = ["Content-Type: application/json"]
	if Firebase and Firebase.Auth and Firebase.Auth.auth.has("idtoken"):
		headers.append("Authorization: Bearer " + str(Firebase.Auth.auth["idtoken"]))

	var req: HTTPRequest = HTTPRequest.new()
	get_tree().root.add_child(req)
	var err: int = req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK: 
		req.queue_free()
		return true

	var args: Array = await req.request_completed
	req.queue_free()

	if args.size() < 4: 
		return true
	var text: String = (args[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)

	if parsed is Array:
		for row in (parsed as Array):
			if row is Dictionary and row.has("document"):
				return false
	return true

# --- Validación extensión de imagen ---
func is_valid_image_path(path: String) -> bool:
	if path.is_empty():
		return false
	var ext: String = path.get_extension().to_lower()
	return ext == "png" or ext == "jpg" or ext == "jpeg"

# --- Subir imagen a Storage y obtener downloadURL ---
# storage_path: ej. "profile_pictures/<uid>/<filename>"
func upload_image_and_get_url(local_path: String, storage_path: String) -> String:
	# ref es un objeto propio del plugin; lo dejamos sin tipar estricto
	var ref = Firebase.Storage.ref(storage_path)
	var put_res: Variant = await ref.put_file(local_path)
	if put_res == null:
		push_error("Fallo al subir a Storage.")
		return ""
	var url_var: Variant = await ref.get_download_url()
	var url: String = String(url_var)
	return url
