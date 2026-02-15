# scripts/systems/avatar/avatar_display.gd
extends CharacterBody2D
class_name AvatarDisplay

## AvatarDisplay - Representa visualmente un avatar en el mapa
## Carga y muestra la imagen estática del avatar

# ===== CONSTANTES =====
const MOVE_SPEED := 150.0
const DEFAULT_TEXTURE := preload("res://assets/default_avatar.png")

# ===== NODOS =====
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var http_request: HTTPRequest = $HTTPRequest

# ===== PROPIEDADES =====
var peer_id: int = 0
var avatar_data: Dictionary = {}
var is_local_player: bool = false

# Textura cargada
var loaded_texture: Texture2D = null

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	if http_request:
		http_request.request_completed.connect(_on_image_downloaded)

## Inicializa el avatar con sus datos
func setup(player_peer_id: int, player_avatar_data: Dictionary, is_local: bool = false) -> void:
	peer_id = player_peer_id
	avatar_data = player_avatar_data
	is_local_player = is_local
	
	# Configurar nombre
	if label:
		label.text = avatar_data.get("nombre", "Sin Nombre")
	
	# Cargar imagen
	_load_avatar_image()
	
	# Si es el jugador local, configurar cámara
	if is_local_player:
		_setup_local_player()
	else:
		# Si es remoto, escuchar actualizaciones de posición
		if NetworkManager.has_signal("player_position_updated"):
			NetworkManager.player_position_updated.connect(_on_remote_position_updated)

# ===== CARGA DE IMAGEN =====

## Carga la imagen del avatar (desde URL o archivo local)
func _load_avatar_image() -> void:
	var image_path: String = str(avatar_data.get("imagen_url", ""))
	
	if image_path.is_empty():
		_set_default_texture()
		return
	
	# Detectar si es URL o ruta local
	if image_path.begins_with("http://") or image_path.begins_with("https://"):
		_load_from_url(image_path)
	elif image_path.begins_with("res://"):
		_load_from_resource(image_path)
	elif image_path.begins_with("user://"):
		_load_from_user_directory(image_path)
	else:
		# Intentar cargar como archivo local del sistema
		_load_from_local_file(image_path)

## Carga imagen desde URL
func _load_from_url(url: String) -> void:
	if not http_request:
		push_error("[AvatarDisplay] HTTPRequest node no encontrado")
		_set_default_texture()
		return
	
	print("[AvatarDisplay] Descargando imagen: ", url)
	var error := http_request.request(url)
	
	if error != OK:
		push_error("[AvatarDisplay] Error al iniciar descarga: ", error)
		_set_default_texture()

## Callback cuando se descarga la imagen
func _on_image_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("[AvatarDisplay] Error descargando imagen: ", response_code)
		_set_default_texture()
		return
	
	var image := Image.new()
	var error := OK
	
	# Intentar diferentes formatos por magic bytes
	if body.size() >= 4 and body[0] == 0x89 and body[1] == 0x50 and body[2] == 0x4E and body[3] == 0x47:
		error = image.load_png_from_buffer(body)
	elif body.size() >= 2 and body[0] == 0xFF and body[1] == 0xD8:
		error = image.load_jpg_from_buffer(body)
	else:
		# Intentar WebP o fallbacks
		error = image.load_webp_from_buffer(body)
	
	if error != OK:
		push_error("[AvatarDisplay] Error cargando buffer de imagen")
		_set_default_texture()
		return
	
	loaded_texture = ImageTexture.create_from_image(image)
	sprite.texture = loaded_texture
	print("[AvatarDisplay] Imagen cargada desde URL")

## Carga imagen desde recursos del proyecto (res://)
func _load_from_resource(path: String) -> void:
	if ResourceLoader.exists(path):
		loaded_texture = load(path)
		sprite.texture = loaded_texture
		print("[AvatarDisplay] Imagen cargada desde recursos: ", path)
	else:
		push_error("[AvatarDisplay] Recurso no encontrado: ", path)
		_set_default_texture()

## Carga imagen desde directorio de usuario (user://)
func _load_from_user_directory(path: String) -> void:
	var real_path := ProjectSettings.globalize_path(path)
	_load_from_local_file(real_path)

## Carga imagen desde archivo local del sistema
func _load_from_local_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("[AvatarDisplay] Archivo no encontrado: ", path)
		_set_default_texture()
		return
	
	var image := Image.new()
	var error := OK
	
	# Detectar extensión
	var extension := path.get_extension().to_lower()
	
	match extension:
		"png":
			error = image.load(path)
		"jpg", "jpeg":
			error = image.load(path)
		"webp":
			error = image.load(path)
		_:
			push_error("[AvatarDisplay] Formato no soportado: ", extension)
			_set_default_texture()
			return
	
	if error != OK:
		push_error("[AvatarDisplay] Error cargando archivo: ", path)
		_set_default_texture()
		return
	
	loaded_texture = ImageTexture.create_from_image(image)
	sprite.texture = loaded_texture
	print("[AvatarDisplay] Imagen cargada desde archivo local: ", path)

## Establece la textura por defecto
func _set_default_texture() -> void:
	sprite.texture = DEFAULT_TEXTURE
	print("[AvatarDisplay] Usando textura por defecto")

# ===== CONFIGURACIÓN LOCAL =====

## Configura el avatar como jugador local
func _setup_local_player() -> void:
	# Agregar cámara
	var camera := Camera2D.new()
	camera.enabled = true
	add_child(camera)
	
	# Cambiar color del label para distinguir
	if label:
		label.add_theme_color_override("font_color", Color.YELLOW)

# ===== MOVIMIENTO =====

func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
	
	var input_vector := Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	input_vector = input_vector.normalized()
	
	velocity = input_vector * MOVE_SPEED
	move_and_slide()
	
	# Sincronizar posición con el servidor
	if input_vector != Vector2.ZERO:
		NetworkManager.sync_position.rpc_id(1, global_position)

## Actualiza la posición (llamado por red)
func update_position(new_position: Vector2) -> void:
	if is_local_player:
		return # No actualizar nuestra propia posición desde red
	
	# Interpolar suavemente
	global_position = global_position.lerp(new_position, 0.25)

## Actualiza los datos del avatar
func update_avatar_data(new_avatar_data: Dictionary) -> void:
	avatar_data = new_avatar_data
	
	if label:
		label.text = avatar_data.get("nombre", "Sin Nombre")
	
	_load_avatar_image()

## Callback para actualización de posición remota
func _on_remote_position_updated(id: int, pos: Vector2) -> void:
	if id == peer_id and not is_local_player:
		update_position(pos)
