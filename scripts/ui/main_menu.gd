# scripts/ui/main_menu.gd
extends Control

## MainMenu - Pantalla principal del MVP
## Permite crear salas, unirse a salas y gestionar avatares

# ===== NODOS =====
@onready var create_room_button: Button = %CreateRoomButton
@onready var join_room_button: Button = %JoinRoomButton
@onready var manage_avatar_button: Button = %ManageAvatarButton
@onready var quit_button: Button = %QuitButton

@onready var join_panel: Panel = %JoinPanel
@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var join_confirm_button: Button = %JoinConfirmButton
@onready var join_cancel_button: Button = %JoinCancelButton

@onready var status_label: Label = %StatusLabel

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_hide_join_panel()
	_update_status()
	
	# Conectar señales de networking
	EventBus.room_created.connect(_on_room_created)
	EventBus.room_joined.connect(_on_room_joined)
	EventBus.connection_failed.connect(_on_connection_failed)

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	create_room_button.pressed.connect(_on_create_room_pressed)
	join_room_button.pressed.connect(_on_join_room_pressed)
	manage_avatar_button.pressed.connect(_on_manage_avatar_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	join_confirm_button.pressed.connect(_on_join_confirm_pressed)
	join_cancel_button.pressed.connect(_on_join_cancel_pressed)
	
	room_code_input.text_submitted.connect(_on_room_code_submitted)

# ===== CALLBACKS DE BOTONES =====

func _on_create_room_pressed() -> void:
	_set_status("Creando sala...", Color.YELLOW)
	_disable_buttons()
	
	# Crear sala
	var room_code := NetworkManager.create_room()
	
	if room_code.is_empty():
		_set_status("Error al crear sala", Color.RED)
		_enable_buttons()
		return
	
	# La señal room_created manejará el resto

func _on_join_room_pressed() -> void:
	join_panel.show()
	room_code_input.grab_focus()
	_disable_main_buttons()

func _on_manage_avatar_pressed() -> void:
	# Cambiar a escena de gestión de avatares
	get_tree().change_scene_to_file("res://scenes/ui/avatar_creator.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_join_confirm_pressed() -> void:
	var code := room_code_input.text.strip_edges().to_upper()
	
	if code.is_empty():
		_set_status("Ingresa un código de sala", Color.RED)
		return
	
	if code.length() != 8:
		_set_status("Código inválido (debe tener 8 caracteres)", Color.RED)
		return
	
	_set_status("Conectando...", Color.YELLOW)
	_disable_buttons()
	
	# Intentar unirse
	NetworkManager.join_room(code)
	
	# Esperar resultado (señal connection_failed o room_joined)

func _on_join_cancel_pressed() -> void:
	_hide_join_panel()
	_enable_main_buttons()
	_set_status("")

func _on_room_code_submitted(text: String) -> void:
	_on_join_confirm_pressed()

# ===== CALLBACKS DE NETWORKING =====

func _on_room_created(room_code: String) -> void:
	_set_status("¡Sala creada! Código: " + room_code, Color.GREEN)
	
	# Mostrar diálogo con el código
	_show_room_code_dialog(room_code)
	
	# Esperar un momento antes de cambiar de escena
	await get_tree().create_timer(2.0).timeout
	
	# Cambiar a escena del mundo
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _on_room_joined(room_code: String) -> void:
	_set_status("¡Conectado a sala!", Color.GREEN)
	
	await get_tree().create_timer(1.0).timeout
	
	# Cambiar a escena del mundo
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _on_connection_failed(error_message: String) -> void:
	_set_status("Error: " + error_message, Color.RED)
	_enable_buttons()
	_hide_join_panel()

# ===== MÉTODOS DE UI =====

func _update_status() -> void:
	var avatar := GameManager.local_avatar_data
	var avatar_name := avatar.get("nombre", "Sin Avatar")
	_set_status("Avatar actual: " + avatar_name, Color.WHITE)

func _set_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)

func _disable_buttons() -> void:
	create_room_button.disabled = true
	join_room_button.disabled = true
	manage_avatar_button.disabled = true
	join_confirm_button.disabled = true

func _enable_buttons() -> void:
	create_room_button.disabled = false
	join_room_button.disabled = false
	manage_avatar_button.disabled = false
	join_confirm_button.disabled = false

func _disable_main_buttons() -> void:
	create_room_button.disabled = true
	join_room_button.disabled = true
	manage_avatar_button.disabled = true

func _enable_main_buttons() -> void:
	create_room_button.disabled = false
	join_room_button.disabled = false
	manage_avatar_button.disabled = false

func _hide_join_panel() -> void:
	join_panel.hide()
	room_code_input.text = ""

func _show_room_code_dialog(code: String) -> void:
	# Crear diálogo temporal para mostrar código
	var dialog := AcceptDialog.new()
	dialog.title = "Sala Creada"
	dialog.dialog_text = "Código de sala:\n\n" + code + "\n\nComparte este código con tus amigos"
	dialog.ok_button_text = "Copiar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Copiar código al portapapeles
	dialog.confirmed.connect(func(): DisplayServer.clipboard_set(code))
	
	# Auto-destruir el diálogo
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
