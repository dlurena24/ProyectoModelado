extends Control

@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var login_button: Button = $VBoxContainer/LoginButton
@onready var to_register_button: Button = $VBoxContainer/ToRegisterButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var google_login_button: Button = $VBoxContainer/GoogleLoginButton
@onready var to_admin_register_button: Button = $VBoxContainer/ToAdminRegisterButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_button_pressed)
	to_register_button.pressed.connect(_on_to_register_button_pressed)
	google_login_button.pressed.connect(_on_google_login_pressed)
	to_admin_register_button.pressed.connect(_on_to_admin_register_button_pressed)

	if Firebase and Firebase.Auth:
		Firebase.Auth.login_succeeded.connect(_on_user_signed_in)
		Firebase.Auth.login_failed.connect(_on_sign_in_failed)

func _on_login_button_pressed() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text
	if email.is_empty() or password.is_empty():
		error_label.text = "Debes ingresar correo y contraseña."
		return
	error_label.text = "Iniciando sesión..."
	Firebase.Auth.login_with_email_and_password(email, password)

func _on_google_login_pressed() -> void:
	error_label.text = "Abriendo autenticación con Google..."
	var provider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider)

func _on_to_register_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register.tscn")

func _on_to_admin_register_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/admin_register.tscn")

func _on_user_signed_in(user_data: Dictionary) -> void:
	var uid_var: Variant = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid_var == null:
		error_label.text = "Error al autenticar. UID vacío."
		return
	var uid: String = String(uid_var)

	error_label.text = "Cargando perfil..."
	GlobalSettings.set_current_user(uid)

	# Comprueba si existe doc; si no, lo crea
	var users = Firebase.Firestore.collection("users")
	var existing: FirestoreDocument = await users.get_doc(uid)
	if existing == null:
		var base_username: String = str(user_data.get("displayName", "Usuario"))
		if base_username.is_empty():
			var email_fb: String = str(user_data.get("email", email_input.text))
			base_username = email_fb.split("@")[0] if "@" in email_fb else "Usuario"
		await users.set_doc(uid, {
			"username": base_username,
			"email": user_data.get("email", email_input.text),
			"role": "user",
			"profile_picture_url": user_data.get("photoURL", user_data.get("photourl","")),
			"created_at": int(Time.get_unix_time_from_system())
		})

	# Carga settings y perfil (plugin)
	await GlobalSettings.load_user_settings_from_firestore(uid)
	await GlobalSettings.load_user_profile(uid)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_sign_in_failed(_error_code, error_message: String) -> void:
	if "INVALID_PASSWORD" in error_message or "INVALID_LOGIN_CREDENTIALS" in error_message:
		error_label.text = "Contraseña incorrecta."
	elif "USER_NOT_FOUND" in error_message or "EMAIL_NOT_FOUND" in error_message:
		error_label.text = "No se encontró un usuario con ese correo."
	else:
		error_label.text = "Error: " + error_message
