extends Node2D

const PLAYER_SCENE = preload("res://scenes/game_world/player_avatar.tscn")

@onready var players_container: Node2D = %PlayersContainer
@onready var spawn_point: Marker2D = %SpawnPoint
@onready var chat_log: RichTextLabel = %ChatLog
@onready var chat_input: LineEdit = %ChatInput

func _ready() -> void:
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	ChatController.message_received.connect(_on_message_received)
	
	chat_input.text_submitted.connect(_on_chat_submitted)
	
	# Spawn existing players (if any)
	for id in NetworkManager.players:
		_spawn_player(id)
	
	# Spawn self if not already there
	if not players_container.has_node(str(multiplayer.get_unique_id())):
		_spawn_player(multiplayer.get_unique_id())

func _on_player_connected(id: int, _info: Dictionary) -> void:
	_spawn_player(id)

func _on_player_disconnected(id: int) -> void:
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func _spawn_player(id: int) -> void:
	if players_container.has_node(str(id)): return
	
	var p = PLAYER_SCENE.instantiate()
	p.name = str(id)
	players_container.add_child(p)
	p.position = spawn_point.position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func _on_chat_submitted(text: String) -> void:
	if text.strip_edges() == "": return
	ChatController.send_message(text)
	chat_input.clear()

func _on_message_received(sender_id: int, message: String, type: String) -> void:
	var sender_name = NetworkManager.get_player_name(sender_id)
	var color = "white"
	var prefix = ""
	
	match type:
		"OOC":
			color = "gray"
			prefix = "(OOC) "
		"ACTION":
			color = "orange"
			prefix = "* "
		"DICE":
			color = "green"
			prefix = "🎲 "
	
	var formatted = "[color=%s]%s%s: %s[/color]" % [color, prefix, sender_name, message]
	chat_log.append_text(formatted + "\n")
