extends Control

@onready var name_input = $VBoxContainer/NameInput
@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var day_option = $VBoxContainer/HBoxContainer/DayOption
@onready var month_option = $VBoxContainer/HBoxContainer/MonthOption
@onready var year_option = $VBoxContainer/HBoxContainer/YearOption

@onready var upload_button = $VBoxContainer/UploadPhotoButton
@onready var file_dialog = $VBoxContainer/FileDialog
@onready var error_label = $VBoxContainer/ErrorLabel
@onready var register_button = $VBoxContainer/RegisterButton

var profile_picture_path = ""

func _ready():
	register_button.pressed.connect(_on_register_button_pressed)
	upload_button.pressed.connect(_on_upload_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	for i in range(1, 32):
		day_option.add_item(str(i))
	for i in range(1, 13):
		month_option.add_item(str(i))
	for i in range(1900, 2040):
		year_option.add_item(str(i))
	
	Firebase.Auth.signup_succeeded.connect(_on_user_signed_up)
	Firebase.Auth.signup_failed.connect(_on_sign_up_failed)

# --- Subir foto ---
func _on_upload_button_pressed():
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	profile_picture_path = path
	$VBoxContainer/FileNameLabel.text = path.get_file()

# --- Validaciones y registro ---
func _on_register_button_pressed():
	var year = int(year_option.get_item_text(year_option.selected))
	var current_year = Time.get_datetime_dict_from_system().year
	if current_year - year < 18:
		error_label.text = "Error: Debes ser mayor de 18 años."
		return
		
	if profile_picture_path.is_empty():
		error_label.text = "Error: Debes seleccionar una foto de perfil."
		return

	var name = name_input.text
	var email = email_input.text
	var password = password_input.text

	if name.is_empty() or email.is_empty() or password.is_empty():
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

# --- Registro completado ---
func _on_user_signed_up(user_data: Dictionary):
	var uid = user_data.get("uid", user_data.get("localId", user_data.get("localid", null)))
	if uid == null:
		error_label.text = "Error: UID no recibido."
		push_warning("Firebase no devolvió UID: %s" % str(user_data))
		return

	print("¡Admin registrado! UID:", uid)
	error_label.text = "Subiendo foto de perfil..."

	# --- Subir foto a Firebase Storage ---
	var file_name = profile_picture_path.get_file()
	var storage_path = "profile_pictures/%s/%s" % [uid, file_name]

	# Crear referencia a esa ruta en el Storage
	var ref = Firebase.Storage.ref(storage_path)

	# Leer el archivo local como bytes
	var file = FileAccess.open(profile_picture_path, FileAccess.READ)
	if file == null:
		error_label.text = "❌ No se pudo abrir la imagen local."
		return

	var file_data = file.get_buffer(file.get_length())
	file.close()

	# Crear encabezados
	var headers = PackedStringArray(["Content-Type: image/png"]) # o image/png si aplica

	# Subir el archivo al Storage
	var upload_result = await Firebase.Storage._upload(file_data, headers, ref, false)

	if upload_result == null or (typeof(upload_result) == TYPE_DICTIONARY and upload_result.has("error")):
		error_label.text = "❌ Error al subir la foto a Firebase Storage."
		print("Error al subir:", upload_result)
		return

	# Obtener URL pública de descarga
	var url_result = await Firebase.Storage._download(ref, false, true)
	if url_result == null or url_result == "":
		error_label.text = "⚠️ No se pudo obtener el enlace de descarga."
		return

	var download_url = url_result
	print("📸 URL pública de la imagen:", download_url)

	error_label.text = "Guardando datos del administrador..."

	var new_admin_data = {
		"username": name_input.text,
		"email": email_input.text,
		"role": "admin",
		"profile_picture_url": download_url,
		"created_at": Time.get_unix_time_from_system()
	}

	await save_admin_to_firestore(uid, new_admin_data)

	print("✅ Datos del admin guardados correctamente.")
	error_label.text = "Registro exitoso."
	get_tree().change_scene_to_file("res://scenes/login.tscn")

# --- Error de registro ---
func _on_sign_up_failed(error_code, error_message):
	print("Error de registro de admin:", error_message)
	error_label.text = "Error: " + error_message

# --- Guardar datos en Firestore (REST API) ---
func save_admin_to_firestore(uid: String, data: Dictionary) -> void:
	var project_id = "avatarsvsrooksproject" 
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, uid]
	var headers = ["Content-Type: application/json"]


	var body_dict = {
		"fields": {
			"username": {"stringValue": data["username"]},
			"email": {"stringValue": data["email"]},
			"role": {"stringValue": data["role"]},
			"profile_picture_url": {"stringValue": data["profile_picture_url"]},
			"created_at": {"integerValue": str(data["created_at"])}
		}
	}

	var body = JSON.stringify(body_dict)

	var request := HTTPRequest.new()
	add_child(request)
	var err = await request.request(url, headers, HTTPClient.METHOD_PATCH, body)

	if err != OK:
		push_error("Error al guardar datos del admin en Firestore: %s" % err)
	else:
		print("✅ Datos del admin guardados correctamente en Firestore.")
