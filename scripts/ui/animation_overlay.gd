# scripts/ui/animation_overlay.gd
extends Control

## AnimationOverlay - Ventana flotante que muestra acciones de rol
## Aparece cuando dos jugadores interactúan y muestra la imagen de la acción

# ===== NODOS =====
@onready var background_panel: Panel = %BackgroundPanel
@onready var action_image: TextureRect = %ActionImage
@onready var action_name_label: Label = %ActionNameLabel
@onready var participants_label: Label = %ParticipantsLabel
@onready var close_button: Button = %CloseButton
@onready var http_request: HTTPRequest = %HTTPRequest

# ===== ESTADO =====
var current_action_data: Dictionary = {}
var actor_data: Dictionary = {}
var target_data: Dictionary = {}

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	hide()
	close_button.pressed.connect(_on_close_pressed)
	
	if http_request:
		http_request.request_completed.connect(_on_image_downloaded)
	
	# Conectar señales de EventBus
	EventBus.animation_overlay_shown.connect(_on_show_animation)

# ===== MOSTRAR OVERLAY =====

## Muestra el overlay con una acción específica
func show_animation(action_data: Dictionary, actor: Dictionary, target: Dictionary) -> void:
	current_action_data = action_data
	actor_data = actor
	target_data = target
	
	# Configurar textos
	action_name_label.text = action_data.get("nombre", "Acción Desconocida")
	
	var actor_name := actor.get("nombre", "Desconocido")
	var target_name := target.get("nombre", "Desconocido")
	participants_label.text = "%s y %s" % [actor_name, target_name]
	
	# Cargar imagen
	var image_url := action_data.get("imagen_url", "")
	_load_action_image(image_url)
	
	# Mostrar overlay
	show()
	
	# Emitir señal
	EventBus.animation_overlay_shown.emit(image_url, action_data.get("nombre", ""))

func _on_show_animation(image_url: String, action_name: String) -> void:
	# Esta función puede ser usada para sincronizar entre clientes
	pass

# ===== CARGA DE IMAGEN =====

func _load_action_image(image_path: String) -> void:
	if image_path.is_empty():
		_set_default_image()
		return
	
	# Detectar tipo de ruta
	if image_path.begins_with("http://") or image_path.begins_with("https://"):
		_load_from_url(image_path)
	elif image_path.begins_with("res://"):
		_load_from_resource(image_path)
	else:
		_load_from_file(image_path)

func _load_from_url(url: String) -> void:
	if not http_request:
		_set_default_image()
		return
	
	action_image.texture = null
	var error := http_request.request(url)
	
	if error != OK:
		push_error("[AnimationOverlay] Error al iniciar descarga de imagen")
		_set_default_image()

func _on_image_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("[AnimationOverlay] Error descargando imagen: ", response_code)
		_set_default_image()
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
		push_error("[AnimationOverlay] Error cargando buffer de imagen")
		_set_default_image()
		return
	
	var texture := ImageTexture.create_from_image(image)
	action_image.texture = texture

func _load_from_resource(path: String) -> void:
	if ResourceLoader.exists(path):
		action_image.texture = load(path)
	else:
		push_error("[AnimationOverlay] Recurso no encontrado: ", path)
		_set_default_image()

func _load_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("[AnimationOverlay] Archivo no encontrado: ", path)
		_set_default_image()
		return
	
	var image := Image.new()
	if image.load(path) == OK:
		action_image.texture = ImageTexture.create_from_image(image)
	else:
		push_error("[AnimationOverlay] Error cargando imagen: ", path)
		_set_default_image()

func _set_default_image() -> void:
	# Crear una imagen placeholder
	var img := Image.create(512, 512, false, Image.FORMAT_RGB8)
	img.fill(Color(0.2, 0.2, 0.3))
	action_image.texture = ImageTexture.create_from_image(img)

# ===== CERRAR OVERLAY =====

func _on_close_pressed() -> void:
	hide()
	EventBus.animation_overlay_closed.emit()

# ===== INPUT =====

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		accept_event()
