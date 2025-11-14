extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var first_name_input: LineEdit = $VBoxContainer/FirstNameInput
@onready var last_name_input: LineEdit = $VBoxContainer/LastNameInput
@onready var nationality_input: LineEdit = $VBoxContainer/NationalityInput
@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var day_option: OptionButton = $VBoxContainer/HBoxContainer/DayOption
@onready var month_option: OptionButton = $VBoxContainer/HBoxContainer/MonthOption
@onready var year_option: OptionButton = $VBoxContainer/HBoxContainer/YearOption
@onready var upload_button: Button = $VBoxContainer/UploadPhotoButton
@onready var file_dialog: FileDialog = $VBoxContainer/FileDialog
@onready var file_name_label: Label = $VBoxContainer/FileNameLabel
@onready var google_button: Button = $VBoxContainer/GoogleButton
@onready var register_button: Button = $VBoxContainer/RegisterButton
@onready var to_login_button: Button = $VBoxContainer/ToLoginButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput

var profile_picture_path: String = ""

func _ready() -> void:
	# Llenar selects de fecha
	for i in range(1, 32):
		day_option.add_item(str(i))
	for i in range(1, 13):
		month_option.add_item(str(i))
	for i in range(1900, 2040):
		year_option.add_item(str(i))

	# Conexiones
	upload_button.pressed.connect(_on_upload_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	register_button.pressed.connect(_on_register_button_pressed)
	google_button.pressed.connect(_on_google_button_pressed)
	to_login_button.pressed.connect(_on_to_login_button_pressed)

	if Firebase and Firebase.Auth:
		Firebase.Auth.signup_succeeded.connect(_on_user_signed_up)
		Firebase.Auth.signup_failed.connect(_on_sign_up_failed)
		Firebase.Auth.login_succeeded.connect(_on_user_signed_in)

func _on_to_login_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_upload_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	profile_picture_path = path
	file_name_label.text = path.get_file()

func _on_register_button_pressed() -> void:
	var year_str: String = year_option.get_item_text(year_option.selected)
	var year: int = int(year_str)
	var current_year: int = Time.get_datetime_dict_from_system().year
	if current_year - year < 18:
		error_label.text = "Error: Debes ser mayor de 18 años."
		return

	var username: String = name_input.text.strip_edges()
	var first_name: String = first_name_input.text.strip_edges()
	var last_name: String = last_name_input.text.strip_edges()
	var nationality: String = nationality_input.text.strip_edges()
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text

	if username == "" or first_name == "" or last_name == "" or nationality == "" or email == "" or password == "":
		error_label.text = "Completa todos los campos (incluida la contraseña)."
		return

	if profile_picture_path.is_empty() or not AuthUtils.is_valid_image_path(profile_picture_path):
		error_label.text = "Sube una imagen .png o .jpg"
		return

	var available: bool = await AuthUtils.is_username_available(username)
	if not available:
		error_label.text = "Ese nombre de usuario ya existe."
		return

	var pw_chk: Dictionary = AuthUtils.validate_password(password)
	if not bool(pw_chk.get("ok", false)):
		var errs: Array = pw_chk.get("errors", [])
		error_label.text = "Contraseña no cumple:\n" + "\n".join(errs)
		return

	error_label.text = "Registrando admin…"
	Firebase.Auth.signup_with_email_and_password(email, password)

func _on_user_signed_up(user_data: Dictionary) -> void:
	var uid_var: Variant = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid_var == null:
		error_label.text = "Error: UID no recibido."
		return
	var uid: String = str(uid_var)

	error_label.text = "Subiendo foto…"
	var file_name: String = profile_picture_path.get_file()
	var storage_path: String = "profile_pictures/%s/%s" % [uid, file_name]
	var download_url: String = await AuthUtils.upload_image_and_get_url(profile_picture_path, storage_path)
	if download_url == "":
		error_label.text = "Error al subir la foto."
		return

	error_label.text = "Guardando datos…"
	await _save_admin_to_firestore(uid, {
		"username": name_input.text.strip_edges(),
		"email": email_input.text.strip_edges(),
		"role": "admin",
		"profile_picture_url": download_url,
		"profile_picture_path": storage_path,
		"first_name": first_name_input.text.strip_edges(),
		"last_name": last_name_input.text.strip_edges(),
		"nationality": nationality_input.text.strip_edges()
	})
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_google_button_pressed() -> void:
	var username: String = name_input.text.strip_edges()
	var first_name: String = first_name_input.text.strip_edges()
	var last_name: String = last_name_input.text.strip_edges()
	var nationality: String = nationality_input.text.strip_edges()

	if username == "" or first_name == "" or last_name == "" or nationality == "":
		error_label.text = "Completa username, nombre, apellidos y nacionalidad."
		return

	var available: bool = await AuthUtils.is_username_available(username)
	if not available:
		error_label.text = "Ese nombre de usuario ya existe."
		return

	error_label.text = "Abriendo Google…"
	var provider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider)

func _on_user_signed_in(user_data: Dictionary) -> void:
	var uid_var: Variant = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid_var == null:
		error_label.text = "Error: UID no recibido (Google)."
		return
	var uid: String = str(uid_var)

	var download_url: String = ""
	if profile_picture_path != "":
		var file_name: String = profile_picture_path.get_file()
		var storage_path: String = "profile_pictures/%s/%s" % [uid, file_name]
		download_url = await AuthUtils.upload_image_and_get_url(profile_picture_path, storage_path)
	else:
		download_url = str(user_data.get("photourl", user_data.get("photoURL", "")))

	await _save_admin_to_firestore(uid, {
		"username": name_input.text.strip_edges(),
		"email": str(user_data.get("email", email_input.text.strip_edges())),
		"role": "admin",
		"profile_picture_url": download_url,
		"profile_picture_path": ("" if profile_picture_path == "" else "profile_pictures/%s/%s" % [uid, profile_picture_path.get_file()]),
		"first_name": first_name_input.text.strip_edges(),
		"last_name": last_name_input.text.strip_edges(),
		"nationality": nationality_input.text.strip_edges()
	})
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_sign_up_failed(_error_code, error_message: String) -> void:
	error_label.text = "Error de registro: " + error_message

func _save_admin_to_firestore(uid: String, data: Dictionary) -> void:
	var full_name: String = (str(data.get("first_name","")) + " " + str(data.get("last_name",""))).strip_edges()
	var out: Dictionary = {
		"username": str(data.get("username","")),
		"email": str(data.get("email","")),
		"role": "admin",
		"profile_picture_url": str(data.get("profile_picture_url","")),
		"profile_picture_path": str(data.get("profile_picture_path","")),
		"name": full_name,
		"first_name": str(data.get("first_name","")),
		"last_name": str(data.get("last_name","")),
		"nationality": str(data.get("nationality","")),
		"created_at": int(Time.get_unix_time_from_system())
	}
	var users: Variant = Firebase.Firestore.collection("users")
	await users.set_doc(uid, out)
