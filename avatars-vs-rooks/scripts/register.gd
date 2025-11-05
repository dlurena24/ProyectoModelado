extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var register_button: Button = $VBoxContainer/RegisterButton
@onready var google_button: Button = $VBoxContainer/GoogleButton
@onready var to_login_button: Button = $VBoxContainer/ToLoginButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel

func _ready() -> void:
	register_button.pressed.connect(_on_register_button_pressed)
	google_button.pressed.connect(_on_google_register_pressed)
	to_login_button.pressed.connect(_on_to_login_button_pressed)
	if Firebase and Firebase.Auth:
		Firebase.Auth.signup_succeeded.connect(_on_user_signed_up)
		Firebase.Auth.signup_failed.connect(_on_sign_up_failed)
		Firebase.Auth.login_succeeded.connect(_on_user_signed_in)
		Firebase.Auth.login_failed.connect(_on_sign_in_failed)

func _on_register_button_pressed() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text
	var username: String = name_input.text.strip_edges()
	if email.is_empty() or password.is_empty() or username.is_empty():
		error_label.text = "Completa usuario, correo y contraseña."
		return
	var pw: Dictionary = AuthUtils.validate_password(password)
	if not bool(pw.get("ok", false)):
		var errs: Array = pw.get("errors", [])
		error_label.text = "Contraseña no cumple:\n" + "\n".join(errs)
		return
	error_label.text = "Registrando…"
	Firebase.Auth.signup_with_email_and_password(email, password)

func _on_user_signed_up(user_data: Dictionary) -> void:
	# UID
	var uid_var: Variant = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid_var == null:
		error_label.text = "Error: UID no recibido."
		return
	var uid: String = str(uid_var)

	# Crea/actualiza el documento del usuario con el username elegido
	var users: Variant = Firebase.Firestore.collection("users")
	await users.set_doc(uid, {
		"username": name_input.text.strip_edges(),
		"email": email_input.text.strip_edges(),
		"role": "user",
		"profile_picture_url": "",  # correo+pass no trae foto por defecto
		"created_at": int(Time.get_unix_time_from_system())
	})

	# Pasamos al login (mantienes tu flujo actual)
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_google_register_pressed() -> void:
	error_label.text = "Abriendo Google…"
	var provider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider)

func _on_user_signed_in(_user_data: Dictionary) -> void:
	# Después de Google, pasa a login para flujos comunes
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_sign_up_failed(_code, msg: String) -> void:
	error_label.text = "Error de registro: " + msg

func _on_sign_in_failed(_code, msg: String) -> void:
	error_label.text = "Error con Google: " + msg

func _on_to_login_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/login.tscn")
