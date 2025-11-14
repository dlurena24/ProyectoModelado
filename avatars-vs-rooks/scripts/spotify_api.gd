extends Node

# ====== Credenciales / Endpoints ======
var CLIENT_ID: String = "94d167584ebe44a9b0ce6230f00bdc68"
var CLIENT_SECRET: String = "0b95f9be11db4c2c8d1388cc629a58e2"

var ACCESS_TOKEN: String = ""
var TOKEN_EXPIRATION: int = 0  # unix time (s)

const TOKEN_URL := "https://accounts.spotify.com/api/token"
const SEARCH_URL := "https://api.spotify.com/v1/search"
const TRACK_URL  := "https://api.spotify.com/v1/tracks/"

# ====== Reproducción ======
var player: AudioStreamPlayer
const DEFAULT_STREAM_PATH := "res://music/Defauls.mp3"  # pista local por defecto

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

	# Obtener token y reproducir lo último o el default
	await _ensure_token()
	await auto_play_last_or_default()

# =====================   API SPOTIFY   ==========================

func _ensure_token() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	if ACCESS_TOKEN == "" or now >= TOKEN_EXPIRATION:
		await refresh_token()

func refresh_token() -> void:
	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)

	var auth_raw: String = "%s:%s" % [CLIENT_ID, CLIENT_SECRET]
	# Godot 4: usar Marshalls.raw_to_base64 para codificar el buffer UTF-8
	var auth_b64: String = Marshalls.raw_to_base64(auth_raw.to_utf8_buffer())
	var headers: Array = [
		"Authorization: Basic " + auth_b64,
		"Content-Type: application/x-www-form-urlencoded"
	]
	var body: String = "grant_type=client_credentials"

	var err: int = req.request(TOKEN_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("Spotify: fallo al iniciar token")
		req.queue_free()
		return

	var args: Array = await req.request_completed
	req.queue_free()
	if args.size() < 4:
		push_error("Spotify: respuesta inválida al pedir token")
		return

	var code: int = int(args[1])
	var text: String = (args[3] as PackedByteArray).get_string_from_utf8()
	var j: Variant = JSON.parse_string(text)
	if code >= 200 and code < 300 and j is Dictionary and (j as Dictionary).has("access_token"):
		ACCESS_TOKEN = str(j["access_token"])
		var expires_in: int = int((j as Dictionary).get("expires_in", 3600))
		TOKEN_EXPIRATION = int(Time.get_unix_time_from_system()) + max(0, expires_in - 30)
	else:
		push_error("Spotify: no se pudo obtener access_token")

func search_track(query: String) -> Dictionary:
	await _ensure_token()

	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	var headers: Array = ["Authorization: Bearer " + ACCESS_TOKEN]
	var url: String = SEARCH_URL + "?q=" + query.uri_encode() + "&type=track&limit=1"

	var err: int = req.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Spotify: error al consultar búsqueda")
		req.queue_free()
		return {}

	var args: Array = await req.request_completed
	req.queue_free()
	if args.size() < 4:
		return {}

	var response: Variant = JSON.parse_string((args[3] as PackedByteArray).get_string_from_utf8())
	if response is Dictionary \
	and (response as Dictionary).has("tracks") \
	and (response as Dictionary)["tracks"].has("items") \
	and not (response as Dictionary)["tracks"]["items"].is_empty():
		return (response as Dictionary)["tracks"]["items"][0]
	return {}

func get_track_by_id(track_id: String) -> Dictionary:
	await _ensure_token()

	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	var headers: Array = ["Authorization: Bearer " + ACCESS_TOKEN]
	var url: String = TRACK_URL + track_id

	var err: int = req.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Spotify: error al traer track por id")
		req.queue_free()
		return {}

	var args: Array = await req.request_completed
	req.queue_free()
	if args.size() < 4:
		return {}

	var response: Variant = JSON.parse_string((args[3] as PackedByteArray).get_string_from_utf8())
	if response is Dictionary and (response as Dictionary).has("id"):
		return response
	return {}

# ================================================================
# =====================   REPRODUCCIÓN   =========================
# ================================================================
func play_track_preview_from_search(query: String) -> bool:
	var item: Dictionary = await search_track(query)
	if item.is_empty():
		return await _play_default()

	var preview_url: String = str(item.get("preview_url", ""))
	if preview_url == "":
		# No todas las canciones tienen preview; usa default
		return await _play_default()

	# Guardar como "última canción" (URL pública del track completo)
	var ex: Variant = item.get("external_urls", {})
	var track_url: String = ""
	if ex is Dictionary:
		track_url = str((ex as Dictionary).get("spotify", ""))

	if track_url != "":
		GlobalSettings.current_settings["spotify_url"] = track_url
		await GlobalSettings.save_user_theme_to_firestore()

	return await _play_preview(preview_url)

func auto_play_last_or_default() -> bool:
	# reproducir última guardada si existe
	var last: String = str(GlobalSettings.current_settings.get("spotify_url", ""))
	if last != "":
		var id: String = _extract_track_id(last)
		if id != "":
			var item: Dictionary = await get_track_by_id(id)
			if not item.is_empty():
				var preview_url: String = str(item.get("preview_url", ""))
				if preview_url != "":
					return await _play_preview(preview_url)

	# si no hay guardado o no hay preview, usa default local
	return await _play_default()

func stop() -> void:
	if player:
		player.stop()

# ------------------------------------------------
# Helpers de reproducción
# ------------------------------------------------
func _play_preview(preview_url: String) -> bool:
	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	var err: int = req.request(preview_url, [], HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Spotify: no se pudo descargar preview")
		req.queue_free()
		return false

	var args: Array = await req.request_completed
	req.queue_free()
	if args.size() < 4:
		return false

	var bytes: PackedByteArray = args[3]
	# Los previews de Spotify son MP3 (30 s)
	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	stream.data = bytes

	player.stream = stream
	player.play()
	return true

func _play_default() -> bool:
	if ResourceLoader.exists(DEFAULT_STREAM_PATH):
		var stream: Resource = ResourceLoader.load(DEFAULT_STREAM_PATH)
		if stream:
			player.stream = stream
			player.play()
			return true
	return false

# ------------------------------------------------
# Parser de track id
# ------------------------------------------------
func _extract_track_id(s: String) -> String:
	# Soporta:
	#  - https://open.spotify.com/track/{id}?...
	#  - spotify:track:{id}
	if s.find("open.spotify.com/track/") >= 0:
		var i: int = s.find("open.spotify.com/track/") + "open.spotify.com/track/".length()
		var rest: String = s.substr(i, s.length() - i)
		var q: int = rest.find("?")
		return rest if q == -1 else rest.substr(0, q)
	if s.begins_with("spotify:track:"):
		return s.substr(14, s.length() - 14)
	return ""
