extends Control

@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var login_button = $VBoxContainer/LoginButton
@onready var to_register_button = $VBoxContainer/ToRegisterButton
@onready var error_label = $VBoxContainer/ErrorLabel
@onready var google_login_button = $VBoxContainer/GoogleLoginButton
@onready var to_admin_register_button = $VBoxContainer/ToAdminRegisterButton

func _ready():
	login_button.pressed.connect(_on_login_button_pressed)
	to_register_button.pressed.connect(_on_to_register_button_pressed)
	google_login_button.pressed.connect(_on_google_login_pressed)
	to_admin_register_button.pressed.connect(_on_to_admin_register_button_pressed)
	
	# Señales de Firebase Auth
	Firebase.Auth.login_succeeded.connect(_on_user_signed_in)
	Firebase.Auth.login_failed.connect(_on_sign_in_failed)

# --- BOTONES ---
func _on_login_button_pressed():
	var email = email_input.text
	var password = password_input.text

	if email.is_empty() or password.is_empty():
		error_label.text = "Debes ingresar correo y contraseña."
		return

	error_label.text = "Iniciando sesión..."
	Firebase.Auth.login_with_email_and_password(email, password)

func _on_google_login_pressed():
	var provider = Firebase.Auth.get_GoogleProvider()
	error_label.text = "Abriendo autenticación con Google..."
	Firebase.Auth.get_auth_localhost(provider)  # inicia login en navegador

func _on_to_register_button_pressed():
	get_tree().change_scene_to_file("res://scenes/register.tscn")

func _on_to_admin_register_button_pressed():
	get_tree().change_scene_to_file("res://scenes/admin_register.tscn")

# --- SESIÓN EXITOSA ---
func _on_user_signed_in(user_data: Dictionary):
	print_debug("Datos recibidos del login: ", user_data)

	var uid = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid == null:
		push_warning("No se recibió UID. Datos: %s" % str(user_data))
		error_label.text = "Error al autenticar. Intenta de nuevo."
		return

	print("✅ Inicio de sesión exitoso. UID:", uid)
	error_label.text = "Cargando configuración del usuario..."
	
	# Guardamos el UID globalmente
	GlobalSettings.current_user_uid = uid
	
	# Cargamos desde Firestore los datos del tema y configuración completa
	await GlobalSettings.load_user_theme_from_firestore(uid)
	await GlobalSettings.load_user_settings_from_firestore(uid)
	
	# Aplicar tema y configuración cargada
	GlobalSettings.update_theme()

	# --- Verificar si el usuario existe en Firestore ---
	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, uid]
	var headers = ["Content-Type: application/json"]

	var get_request := HTTPRequest.new()
	add_child(get_request)
	var err = get_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		error_label.text = "Error al cargar datos del usuario."
		get_request.queue_free()
		return
	
	var signal_args = await get_request.request_completed
	var response_code = signal_args[1]
	var body_bytes = signal_args[3]
	var response_text = body_bytes.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	get_request.queue_free()

	if response_code != 200 or json == null or not json.has("fields"):
		print("⚠️ Usuario no encontrado en Firestore. Creando nuevo documento...")
		
		var new_user_data = {
			"fields": {
				"username": {"stringValue": user_data.get("displayName", "Usuario")},
				"email": {"stringValue": user_data.get("email", email_input.text)},
				"role": {"stringValue": "user"},
				"profile_picture_url": {"stringValue": user_data.get("photoURL", "")},
				"created_at": {"integerValue": str(Time.get_unix_time_from_system())}
			}
		}

		var create_request := HTTPRequest.new()
		add_child(create_request)
		var body_str = JSON.stringify(new_user_data)
		var create_err = create_request.request(url, headers, HTTPClient.METHOD_PATCH, body_str)
		if create_err != OK:
			error_label.text = "Error al guardar datos del usuario."
			create_request.queue_free()
			return

		await create_request.request_completed
		create_request.queue_free()

		print("✅ Usuario nuevo creado en Firestore (rol: user).")
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		# Usuario existente
		var fields = json["fields"]
		var role = fields.get("role", {}).get("stringValue", "user")
		print("🧾 Rol detectado:", role)
		if role == "admin":
			get_tree().change_scene_to_file("res://scenes/admin_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- ERROR DE LOGIN ---
func _on_sign_in_failed(_error_code, error_message):
	print("❌ Error de inicio de sesión:", error_message)
	if "INVALID_PASSWORD" in error_message or "INVALID_LOGIN_CREDENTIALS" in error_message:
		error_label.text = "Contraseña incorrecta."
	elif "USER_NOT_FOUND" in error_message or "EMAIL_NOT_FOUND" in error_message:
		error_label.text = "No se encontró un usuario con ese correo."
	else:
		error_label.text = "Error: " + error_message
