extends Node

var CLIENT_ID = "94d167584ebe44a9b0ce6230f00bdc68"
var CLIENT_SECRET = "0b95f9be11db4c2c8d1388cc629a58e2"
var ACCESS_TOKEN = ""
var TOKEN_EXPIRATION = 0

const TOKEN_URL = "https://accounts.spotify.com/api/token"
const SEARCH_URL = "https://api.spotify.com/v1/search"

func _ready():
	await refresh_token()

func refresh_token():
	var request = HTTPRequest.new()
	add_child(request)
	
	var auth_string = CLIENT_ID + ":" + CLIENT_SECRET
	var auth_bytes = auth_string.to_utf8_buffer()
	var auth_base64 = Marshalls.raw_to_base64(auth_bytes)

	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Authorization: Basic " + auth_base64
	]

	var body = "grant_type=client_credentials"
	var err = request.request(TOKEN_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("Error al solicitar token de Spotify")
		return
	
	var result = await request.request_completed
	var response = JSON.parse_string(result[3].get_string_from_utf8())
	
	if response and response.has("access_token"):
		ACCESS_TOKEN = response["access_token"]
		TOKEN_EXPIRATION = Time.get_unix_time_from_system() + int(response["expires_in"])
		print("✅ Token de Spotify obtenido correctamente.")
	else:
		push_error("No se pudo obtener el token de Spotify")

func search_song(query: String) -> Dictionary:
	if ACCESS_TOKEN == "" or Time.get_unix_time_from_system() >= TOKEN_EXPIRATION:
		await refresh_token()

	var request = HTTPRequest.new()
	add_child(request)
	var headers = ["Authorization: Bearer " + ACCESS_TOKEN]
	var url = SEARCH_URL + "?q=" + query.uri_encode() + "&type=track&limit=1"

	var err = request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Error al buscar canción en Spotify")
		return {}

	var result = await request.request_completed
	var response = JSON.parse_string(result[3].get_string_from_utf8())
	request.queue_free()

	if response and response.has("tracks") and not response["tracks"]["items"].is_empty():
		return response["tracks"]["items"][0]
	else:
		return {}
