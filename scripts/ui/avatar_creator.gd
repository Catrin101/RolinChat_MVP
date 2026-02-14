# scripts/ui/avatar_creator.gd
extends Control

## AvatarCreator - UI para crear y editar avatares
## Permite configurar nombre, raza, sexo e imagen

# ===== NODOS =====
@onready var name_input: LineEdit = %NameInput
@onready var description_input: TextEdit = %DescriptionInput
@onready var image_url_input: LineEdit = %ImageUrlInput

@onready var raza_option: OptionButton = %RazaOption
@onready var sexo_option: OptionButton = %SexoOption

@onready var preview_image: TextureRect = %PreviewImage
@onready var load_image_button: Button = %LoadImageButton
@onready var test_url_button: Button = %TestUrlButton

@onready var save_button: Button = %SaveButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel

@onready var avatar_list: ItemList = %AvatarList
@onready var load_avatar_button: Button = %LoadAvatarButton
@onready var delete_avatar_button: Button = %DeleteAvatarButton

@onready var http_request: HTTPRequest = %HTTPRequest

# ===== ESTADO =====
var current_avatar: Dictionary = {}
var preview_texture: Texture2D = null
var selected_avatar_filename: String = ""

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_populate_options()
	_load_current_avatar()
	_refresh_avatar_list()
	
	if http_request:
		http_request.request_completed.connect(_on_image_test_completed)

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	load_image_button.pressed.connect(_on_load_image_pressed)
	test_url_button.pressed.connect(_on_test_url_pressed)
	
	load_avatar_button.pressed.connect(_on_load_avatar_pressed)
	delete_avatar_button.pressed.connect(_on_delete_avatar_pressed)
	avatar_list.item_selected.connect(_on_avatar_selected)

# ===== POBLACIÓN DE OPCIONES =====

func _populate_options() -> void:
	# Llenar opciones de raza
	raza_option.clear()
	for raza in DataManager.razas:
		raza_option.add_item(raza.get("nombre", ""), raza_option.item_count)
		raza_option.set_item_metadata(raza_option.item_count - 1, raza.get("id", ""))
	
	# Llenar opciones de sexo
	sexo_option.clear()
	for sexo in DataManager.sexos:
		sexo_option.add_item(sexo.get("nombre", ""), sexo_option.item_count)
		sexo_option.set_item_metadata(sexo_option.item_count - 1, sexo.get("id", ""))

# ===== CARGA Y GUARDADO =====

func _load_current_avatar() -> void:
	current_avatar = GameManager.local_avatar_data.duplicate()
	_display_avatar(current_avatar)

func _display_avatar(avatar_data: Dictionary) -> void:
	name_input.text = avatar_data.get("nombre", "")
	description_input.text = avatar_data.get("descripcion", "")
	image_url_input.text = avatar_data.get("imagen_url", "")
	
	# Seleccionar raza
	var raza_id := avatar_data.get("raza_id", "humano")
	for i in range(raza_option.item_count):
		if raza_option.get_item_metadata(i) == raza_id:
			raza_option.select(i)
			break
	
	# Seleccionar sexo
	var sexo_id := avatar_data.get("sexo_id", "masculino")
	for i in range(sexo_option.item_count):
		if sexo_option.get_item_metadata(i) == sexo_id:
			sexo_option.select(i)
			break
	
	# Cargar preview de imagen
	_load_preview_image(avatar_data.get("imagen_url", ""))

func _load_preview_image(image_path: String) -> void:
	if image_path.is_empty():
		preview_image.texture = null
		return
	
	# Si es URL, usar HTTPRequest
	if image_path.begins_with("http://") or image_path.begins_with("https://"):
		_set_status("Cargando imagen desde URL...", Color.YELLOW)
		return # La carga se maneja en test_url
	
	# Si es recurso o archivo local
	if image_path.begins_with("res://"):
		if ResourceLoader.exists(image_path):
			preview_texture = load(image_path)
			preview_image.texture = preview_texture
			_set_status("Imagen cargada", Color.GREEN)
		else:
			_set_status("Recurso no encontrado", Color.RED)
	elif FileAccess.file_exists(image_path):
		var image := Image.new()
		if image.load(image_path) == OK:
			preview_texture = ImageTexture.create_from_image(image)
			preview_image.texture = preview_texture
			_set_status("Imagen cargada", Color.GREEN)
		else:
			_set_status("Error cargando imagen", Color.RED)
	else:
		_set_status("Archivo no encontrado", Color.RED)

# ===== CALLBACKS DE BOTONES =====

func _on_save_pressed() -> void:
	var avatar_name := name_input.text.strip_edges()
	
	if avatar_name.is_empty():
		_set_status("El nombre no puede estar vacío", Color.RED)
		return
	
	if image_url_input.text.strip_edges().is_empty():
		_set_status("Debes especificar una imagen", Color.RED)
		return
	
	# Construir datos del avatar
	current_avatar = {
		"id": current_avatar.get("id", GameManager._generate_uuid()),
		"nombre": avatar_name,
		"descripcion": description_input.text.strip_edges(),
		"imagen_url": image_url_input.text.strip_edges(),
		"raza_id": raza_option.get_item_metadata(raza_option.selected),
		"sexo_id": sexo_option.get_item_metadata(sexo_option.selected)
	}
	
	# Guardar
	var filename := avatar_name.to_lower().replace(" ", "_") + ".json"
	if GameManager.save_avatar(current_avatar, filename):
		_set_status("Avatar guardado: " + avatar_name, Color.GREEN)
		
		# Actualizar avatar local
		GameManager.change_local_avatar(current_avatar)
		
		# Refrescar lista
		_refresh_avatar_list()
	else:
		_set_status("Error al guardar avatar", Color.RED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_load_image_pressed() -> void:
	_set_status("Abre un diálogo de archivo en tu OS y copia la ruta completa aquí", Color.CYAN)
	# En MVP no usamos FileDialog nativo, el usuario pega la ruta manualmente

func _on_test_url_pressed() -> void:
	var url := image_url_input.text.strip_edges()
	
	if url.is_empty():
		_set_status("Ingresa una URL primero", Color.RED)
		return
	
	if not url.begins_with("http://") and not url.begins_with("https://"):
		_set_status("La URL debe comenzar con http:// o https://", Color.RED)
		return
	
	_set_status("Probando URL...", Color.YELLOW)
	http_request.request(url)

func _on_image_test_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_set_status("Error: No se pudo descargar la imagen (código " + str(response_code) + ")", Color.RED)
		return
	
	var image := Image.new()
	var error := OK
	
	# Detectar formato
	var first_bytes := body.slice(0, 4).get_string_from_ascii()
	
	if first_bytes.begins_with("\x89PNG"):
		error = image.load_png_from_buffer(body)
	elif first_bytes.begins_with("\xFF\xD8"):
		error = image.load_jpg_from_buffer(body)
	else:
		error = image.load_webp_from_buffer(body)
	
	if error != OK:
		_set_status("Error: Formato de imagen no soportado", Color.RED)
		return
	
	preview_texture = ImageTexture.create_from_image(image)
	preview_image.texture = preview_texture
	_set_status("¡Imagen válida! Tamaño: " + str(image.get_width()) + "x" + str(image.get_height()), Color.GREEN)

# ===== GESTIÓN DE LISTA DE AVATARES =====

func _refresh_avatar_list() -> void:
	avatar_list.clear()
	
	var avatars := GameManager.list_saved_avatars()
	
	for avatar_info in avatars:
		var avatar_data: Dictionary = avatar_info["data"]
		var display_name := avatar_data.get("nombre", "Sin Nombre")
		avatar_list.add_item(display_name)
		avatar_list.set_item_metadata(avatar_list.item_count - 1, avatar_info["filename"])

func _on_avatar_selected(index: int) -> void:
	selected_avatar_filename = avatar_list.get_item_metadata(index)
	load_avatar_button.disabled = false
	delete_avatar_button.disabled = false

func _on_load_avatar_pressed() -> void:
	if selected_avatar_filename.is_empty():
		return
	
	var filepath := GameManager.PROFILES_DIR + selected_avatar_filename
	current_avatar = GameManager._load_avatar_from_file(filepath)
	
	if not current_avatar.is_empty():
		_display_avatar(current_avatar)
		_set_status("Avatar cargado: " + current_avatar.get("nombre"), Color.GREEN)

func _on_delete_avatar_pressed() -> void:
	if selected_avatar_filename.is_empty():
		return
	
	var filepath := GameManager.PROFILES_DIR + selected_avatar_filename
	
	if DirAccess.remove_absolute(filepath) == OK:
		_set_status("Avatar eliminado", Color.GREEN)
		_refresh_avatar_list()
		selected_avatar_filename = ""
		load_avatar_button.disabled = true
		delete_avatar_button.disabled = true
	else:
		_set_status("Error al eliminar avatar", Color.RED)

# ===== UTILIDADES =====

func _set_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
