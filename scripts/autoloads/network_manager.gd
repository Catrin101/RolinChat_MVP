extends Node

## Singleton to handle High-Level Multiplayer and Room Management.

const PORT = 7777
const MAX_CLIENTS = 8

signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_failed
signal connection_successful
signal room_created(code: String)

var players: Dictionary = {} # peer_id -> { "name": "...", "avatar": AvatarData }
var room_code: String = ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## --- HOST LOGIC ---

func create_room() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		printerr("[NetworkManager] Failed to create server: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	room_code = _generate_room_code()
	
	# Register host (self)
	var host_info = _get_local_player_info()
	players[1] = host_info
	
	room_created.emit(room_code)
	print("[NetworkManager] Room created with code: ", room_code)

func _generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(8):
		code += chars[randi() % chars.length()]
	return code

## --- CLIENT LOGIC ---

func join_room(address: String = "127.0.0.1") -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		printerr("[NetworkManager] Failed to create client: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("[NetworkManager] Joining room at: ", address)

## --- MULTIPLAYER CALLBACKS ---

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer connected: ", id)
	# Send our info to the new peer
	register_player.rpc_id(id, _get_local_player_info())

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer disconnected: ", id)
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	print("[NetworkManager] Connected to server successfully.")
	connection_successful.emit()

func _on_connection_failed() -> void:
	printerr("[NetworkManager] Connection failed.")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	printerr("[NetworkManager] Server disconnected.")
	players.clear()
	server_disconnected.emit()

## --- DATA SKEW / SYNC ---

@rpc("any_peer", "call_local")
func register_player(info: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1 # Local call
	
	players[sender_id] = info
	player_connected.emit(sender_id, info)
	print("[NetworkManager] Player registered: ", info.name, " (", sender_id, ")")

func _get_local_player_info() -> Dictionary:
	var avatar = AvatarManager.get_active_avatar()
	return {
		"name": avatar.nombre if avatar else "Jugador",
		"avatar": avatar.to_dict() if avatar else {}
	}

func get_player_name(id: int) -> String:
	return players.get(id, {}).get("name", "Desconocido")
