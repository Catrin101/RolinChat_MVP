# scripts/ui/map_selector.gd
extends Control

## MapSelector - UI para seleccionar mapa al crear sala
## Muestra miniaturas y descripciones de mapas disponibles

# ===== SEÑALES =====
signal map_selected(map_id: String)
signal cancelled()

# ===== NODOS =====
@onready var maps_grid: GridContainer = %MapsGrid
@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton

# ===== CONSTANTES =====
const MAP_BUTTON_SCENE = preload("res://scenes/ui/map_button.tscn")

# ===== ESTADO =====
var selected_map_id: String = ""

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_populate_maps()

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)

# ===== POBLACIÓN DE MAPAS =====

func _populate_maps() -> void:
	# Limpiar grid
	for child in maps_grid.get_children():
		child.queue_free()
	
	# Obtener mapas registrados
	var maps := MapRegistry.get_all_maps()
	
	if maps.is_empty():
		push_error("[MapSelector] No hay mapas registrados")
		return
	
	# Crear botón para cada mapa
	for map_info in maps:
		_create_map_button(map_info)

func _create_map_button(map_info) -> void:
	# Crear contenedor del botón
	var button_container := PanelContainer.new()
	button_container.custom_minimum_size = Vector2(200, 250)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	button_container.add_child(vbox)
	
	# Thumbnail
	var thumbnail := TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(180, 120)
	thumbnail.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Intentar cargar thumbnail
	if FileAccess.file_exists(map_info.thumbnail_path):
		thumbnail.texture = load(map_info.thumbnail_path)
	else:
		# Crear thumbnail placeholder
		var placeholder := _create_placeholder_texture()
		thumbnail.texture = placeholder
	
	vbox.add_child(thumbnail)
	
	# Nombre del mapa
	var name_label := Label.new()
	name_label.text = map_info.display_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# Descripción
	var desc_label := Label.new()
	desc_label.text = map_info.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 40)
	vbox.add_child(desc_label)
	
	# Info de jugadores
	var info_label := Label.new()
	info_label.text = "Máx. %d jugadores | %d spawns" % [map_info.max_players, map_info.spawn_count]
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	# Botón de selección
	var select_button := Button.new()
	select_button.text = "Seleccionar"
	select_button.pressed.connect(func(): _on_map_selected(map_info.map_id))
	vbox.add_child(select_button)
	
	maps_grid.add_child(button_container)

func _create_placeholder_texture() -> ImageTexture:
	var img := Image.create(180, 120, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.3, 0.4))
	return ImageTexture.create_from_image(img)

# ===== CALLBACKS =====

func _on_map_selected(map_id: String) -> void:
	selected_map_id = map_id
	map_selected.emit(map_id)
	queue_free()

func _on_close_pressed() -> void:
	cancelled.emit()
	queue_free()
