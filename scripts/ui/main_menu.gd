# scripts/ui/main_menu.gd
extends Control

# ===== REFERENCIAS A NODOS =====
@onready var create_room_button: Button = $MarginContainer/VBoxContainer/CreateRoomButton
@onready var join_room_button: Button = $MarginContainer/VBoxContainer/JoinRoomButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

@onready var room_code_panel: Panel = $RoomCodePanel
@onready var room_code_label: Label = $RoomCodePanel/VBoxContainer/CodeLabel
@onready var copy_code_button: Button = $RoomCodePanel/VBoxContainer/CopyButton
@onready var start_button: Button = $RoomCodePanel/VBoxContainer/StartButton

@onready var join_panel: Panel = $JoinPanel
@onready var code_input: LineEdit = $JoinPanel/VBoxContainer/CodeInput
@onready var connect_button: Button = $JoinPanel/VBoxContainer/ConnectButton
@onready var cancel_button: Button = $JoinPanel/VBoxContainer/CancelButton

@onready var error_label: Label = $ErrorLabel

# ===== ESTADO =====
var current_room_code: String = ""

# ===== CICLO DE VIDA =====
func _ready() -> void:
	room_code_panel.hide()
	join_panel.hide()
	error_label.hide()
	
	create_room_button.pressed.connect(_on_create_room_pressed)
	join_room_button.pressed.connect(_on_join_room_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	copy_code_button.pressed.connect(_on_copy_code_pressed)
	start_button.pressed.connect(_on_start_game_pressed)
	
	connect_button.pressed.connect(_on_connect_pressed)
	cancel_button.pressed.connect(_on_cancel_join_pressed)
	
	code_input.text_changed.connect(_on_code_input_changed)
	
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	connect_button.disabled = true
	
	print("[MainMenu] Menú principal inicializado")

# ===== CALLBACKS DE BOTONES =====

func _on_create_room_pressed() -> void:
	print("[MainMenu] Creando sala...")
	error_label.hide()
	
	var player_name = "Host"
	var avatar_data = {}
	
	var code = NetworkManager.create_room(player_name, avatar_data)
	
	if code.is_empty():
		show_error("Error al crear la sala. Intenta de nuevo.")

func _on_join_room_pressed() -> void:
	print("[MainMenu] Mostrando panel de unirse...")
	join_panel.show()
	code_input.grab_focus()

func _on_quit_pressed() -> void:
	print("[MainMenu] Saliendo del juego...")
	get_tree().quit()

func _on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(current_room_code)
	print("[MainMenu] Código copiado al portapapeles: ", current_room_code)
	
	copy_code_button.text = "¡Copiado!"
	await get_tree().create_timer(1.0).timeout
	copy_code_button.text = "Copiar Código"

func _on_start_game_pressed() -> void:
	print("[MainMenu] Iniciando juego...")
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connect_pressed() -> void:
	var code = code_input.text.strip_edges()
	print("[MainMenu] Conectando a sala: ", code)
	
	error_label.hide()
	
	var player_name = "Player"
	var avatar_data = {}
	
	NetworkManager.join_room(code, player_name, avatar_data)

func _on_cancel_join_pressed() -> void:
	join_panel.hide()
	code_input.clear()

func _on_code_input_changed(new_text: String) -> void:
	connect_button.disabled = new_text.strip_edges().is_empty()

# ===== CALLBACKS DE NETWORK =====

func _on_room_created(code: String) -> void:
	print("[MainMenu] Sala creada con código: ", code)
	
	current_room_code = code
	room_code_label.text = "Código de Sala:\n" + code
	
	room_code_panel.show()
	
	create_room_button.hide()
	join_room_button.hide()

func _on_room_joined() -> void:
	print("[MainMenu] Unido a sala exitosamente")
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_failed(reason: String) -> void:
	print("[MainMenu] Conexión fallida: ", reason)
	show_error(reason)

# ===== MÉTODOS AUXILIARES =====

func show_error(message: String) -> void:
	error_label.text = message
	error_label.show()
	
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(error_label):
		error_label.hide()
