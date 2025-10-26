extends Control

@onready var name_input = $VBoxContainer/NameInput
@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var register_button = $VBoxContainer/RegisterButton
@onready var google_button = $VBoxContainer/GoogleButton   
@onready var to_login_button = $VBoxContainer/ToLoginButton
@onready var error_label = $VBoxContainer/ErrorLabel

func _ready():
	register_button.pressed.connect(_on_register_button_pressed)
	google_button.pressed.connect(_on_google_register_pressed)
	to_login_button.pressed.connect(_on_to_login_button_pressed)
	
	Firebase.Auth.signup_succeeded.connect(_on_user_signed_up)
	Firebase.Auth.signup_failed.connect(_on_sign_up_failed)
	Firebase.Auth.login_succeeded.connect(_on_user_signed_in)
	Firebase.Auth.login_failed.connect(_on_sign_in_failed)
	GlobalSettings.update_theme()

# --- REGISTRO CON CORREO Y CONTRASEÑA ---
func _on_register_button_pressed():
	var username = name_input.text
	var email = email_input.text
	var password = password_input.text

	if username.is_empty() or email.is_empty() or password.is_empty():
		error_label.text = "Todos los campos son obligatorios."
		return
	if not "@" in email:
		error_label.text = "Por favor, ingresa un correo válido."
		return
	if password.length() < 6:
		error_label.text = "La contraseña debe tener al menos 6 caracteres."
		return

	error_label.text = "Registrando..."
	Firebase.Auth.signup_with_email_and_password(email, password)

# --- REGISTRO / LOGIN CON GOOGLE ---
func _on_google_register_pressed():
	error_label.text = "Abriendo autenticación con Google..."
	var provider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider)

# --- GUARDAR EN FIRESTORE (tanto para Google como email) ---
func save_user_to_firestore(uid: String, data: Dictionary, role: String = "user") -> void:
	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, uid]
	var headers = ["Content-Type: application/json"]

	var body_dict = {
		"fields": {
			"username": {"stringValue": data.get("username", "Usuario")},
			"email": {"stringValue": data.get("email", "")},
			"role": {"stringValue": role},
			"profile_picture_url": {"stringValue": data.get("photoURL", "")},
			"created_at": {"integerValue": str(Time.get_unix_time_from_system())}
		}
	}

	var body = JSON.stringify(body_dict)
	var request := HTTPRequest.new()
	add_child(request)
	var err = await request.request(url, headers, HTTPClient.METHOD_PATCH, body)
	if err != OK:
		push_error("Error al guardar en Firestore: %s" % err)
	else:
		print("✅ Usuario guardado en Firestore correctamente.")

# --- CUANDO SE CREA CON EMAIL ---
func _on_user_signed_up(user_data: Dictionary):
	var uid = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid == null:
		error_label.text = "Error: UID no recibido."
		push_warning("Firebase no devolvió un UID: %s" % str(user_data))
		return

	print("¡Usuario registrado con éxito! UID:", uid)
	error_label.text = "Guardando datos..."

	var user_data_dict = {
		"username": name_input.text,
		"email": email_input.text
	}
	await save_user_to_firestore(uid, user_data_dict)
	get_tree().change_scene_to_file("res://scenes/login.tscn")

# --- CUANDO SE REGISTRA O INICIA SESIÓN CON GOOGLE ---
func _on_user_signed_in(user_data: Dictionary):
	var uid = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid == null:
		error_label.text = "Error: UID no recibido."
		return

	print("✅ Sesión iniciada con Google. UID:", uid)
	error_label.text = "Guardando datos de Google..."

	await save_user_to_firestore(uid, user_data)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- ERRORES ---
func _on_sign_up_failed(_error_code, error_message):
	print("❌ Error de registro:", error_message)
	if "EMAIL_EXISTS" in error_message:
		error_label.text = "Este correo ya está registrado."
	else:
		error_label.text = "Error: " + error_message

func _on_sign_in_failed(_error_code, error_message):
	print("❌ Error al iniciar sesión con Google:", error_message)
	error_label.text = "Error: " + error_message

# --- CAMBIAR A LOGIN ---
func _on_to_login_button_pressed():
	get_tree().change_scene_to_file("res://scenes/login.tscn")
