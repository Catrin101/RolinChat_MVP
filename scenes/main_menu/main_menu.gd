extends Control

@onready var create_btn: Button = %CreateBtn
@onready var join_btn: Button = %JoinBtn
@onready var avatar_btn: Button = %AvatarBtn
@onready var ip_input: LineEdit = %IPInput
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	create_btn.pressed.connect(_on_create_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	avatar_btn.pressed.connect(_on_avatar_pressed)
	
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.connection_successful.connect(_on_connection_success)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_create_pressed() -> void:
	if not AvatarManager.get_active_avatar():
		status_label.text = "Error: Configura tu avatar primero."
		return
	
	NetworkManager.create_room()

func _on_join_pressed() -> void:
	if not AvatarManager.get_active_avatar():
		status_label.text = "Error: Configura tu avatar primero."
		return
		
	var ip = ip_input.text.strip_edges()
	if ip == "": ip = "127.0.0.1"
	NetworkManager.join_room(ip)
	status_label.text = "Conectando..."

func _on_avatar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/avatar_creator/avatar_creator.tscn")

func _on_room_created(code: String) -> void:
	status_label.text = "Sala creada! Código: " + code
	# For MVP, we go directly to the lobby
	get_tree().change_scene_to_file("res://scenes/game_world/lobby.tscn")

func _on_connection_success() -> void:
	get_tree().change_scene_to_file("res://scenes/game_world/lobby.tscn")

func _on_connection_failed() -> void:
	status_label.text = "Error: No se pudo conectar."
