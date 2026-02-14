# scripts/autoloads/network_manager.gd
extends Node

## Gestor centralizado de networking
## Maneja creación/unión a salas, sincronización y RPCs

# ===== SEÑALES =====
signal room_created(code: String)
signal room_joined()
signal connection_failed(reason: String)
signal player_list_updated(players: Dictionary)
signal player_connected(peer_id: int, player_name: String)
signal player_left(peer_id: int, player_name: String)
signal host_disconnected()

# ===== CONSTANTES =====
const DEFAULT_PORT := 7777
const MAX_PLAYERS := 8
const PROTOCOL_VERSION := "1.0"

# ===== ESTADO =====
var peer: ENetMultiplayerPeer = null
var room_code: String = ""
var is_host: bool = false
var players: Dictionary = {}
var local_player_name: String = ""
var local_avatar_data: Dictionary = {}

# ===== CICLO DE VIDA =====
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("[NetworkManager] Inicializado correctamente")

# ===== API PÚBLICA =====

func create_room(player_name: String, avatar_data: Dictionary = {}) -> String:
	if peer != null:
		push_error("[NetworkManager] Ya estás en una sala")
		return ""
	
	if player_name.strip_edges().is_empty():
		push_error("[NetworkManager] El nombre del jugador no puede estar vacío")
		return ""
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	
	if error != OK:
		push_error("[NetworkManager] Error creando servidor: " + str(error))
		peer = null
		return ""
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	local_player_name = player_name
	local_avatar_data = avatar_data
	room_code = _generate_room_code()
	
	players[1] = {
		"peer_id": 1,
		"player_name": player_name,
		"avatar_data": avatar_data
	}
	
	print("[NetworkManager] Sala creada exitosamente")
	print("[NetworkManager] Código de sala: ", room_code)
	
	room_created.emit(room_code)
	player_list_updated.emit(players)
	
	return room_code

func join_room(code: String, player_name: String, avatar_data: Dictionary = {}) -> void:
	if peer != null:
		push_error("[NetworkManager] Ya estás en una sala")
		connection_failed.emit("Ya estás conectado a una sala")
		return
	
	if not _validate_room_code(code):
		push_error("[NetworkManager] Código de sala inválido: " + code)
		connection_failed.emit("Código de sala inválido")
		return
	
	if player_name.strip_edges().is_empty():
		push_error("[NetworkManager] El nombre del jugador no puede estar vacío")
		connection_failed.emit("Nombre de jugador inválido")
		return
	
	local_player_name = player_name
	local_avatar_data = avatar_data
	room_code = code
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(code, DEFAULT_PORT)
	
	if error != OK:
		push_error("[NetworkManager] Error conectando al servidor: " + str(error))
		peer = null
		connection_failed.emit("Error de conexión al servidor")
		return
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	
	print("[NetworkManager] Intentando conectar a sala: ", code)

func leave_room() -> void:
	if peer == null:
		return
	
	print("[NetworkManager] Saliendo de la sala...")
	
	peer.close()
	peer = null
	multiplayer.multiplayer_peer = null
	room_code = ""
	players.clear()
	is_host = false
	
	print("[NetworkManager] Desconectado correctamente")

func get_players() -> Dictionary:
	return players.duplicate()

func get_player_data(peer_id: int) -> Dictionary:
	return players.get(peer_id, {})

func get_player_name(peer_id: int) -> String:
	var player_data = players.get(peer_id, {})
	return player_data.get("player_name", "Desconocido")

# ===== CALLBACKS DE MULTIPLAYER =====

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer conectado: ", id)

func _on_peer_disconnected(id: int) -> void:
	var player_name = get_player_name(id)
	print("[NetworkManager] Peer desconectado: ", id, " (", player_name, ")")
	
	if players.has(id):
		players.erase(id)
		player_list_updated.emit(players)
		player_left.emit(id, player_name)

func _on_connected_to_server() -> void:
	print("[NetworkManager] Conectado al servidor exitosamente")
	_register_player.rpc_id(1, local_player_name, local_avatar_data)

func _on_connection_failed() -> void:
	print("[NetworkManager] Fallo en la conexión")
	peer = null
	multiplayer.multiplayer_peer = null
	connection_failed.emit("No se pudo conectar al servidor. Verifica el código.")

func _on_server_disconnected() -> void:
	print("[NetworkManager] El servidor se desconectó")
	peer = null
	multiplayer.multiplayer_peer = null
	players.clear()
	host_disconnected.emit()

# ===== RPCs =====

@rpc("any_peer", "call_remote", "reliable")
func _register_player(player_name: String, avatar_data: Dictionary) -> void:
	if not is_host:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	print("[NetworkManager] Registrando jugador: ", player_name, " (ID: ", sender_id, ")")
	
	var final_name = _ensure_unique_name(player_name)
	
	players[sender_id] = {
		"peer_id": sender_id,
		"player_name": final_name,
		"avatar_data": avatar_data
	}
	
	_update_player_list.rpc(players)
	_confirm_registration.rpc_id(sender_id, final_name)
	
	player_list_updated.emit(players)
	player_connected.emit(sender_id, final_name)

@rpc("authority", "call_local", "reliable")
func _update_player_list(new_players: Dictionary) -> void:
	players = new_players
	player_list_updated.emit(players)
	print("[NetworkManager] Lista de jugadores actualizada: ", players.keys())

@rpc("authority", "call_remote", "reliable")
func _confirm_registration(assigned_name: String) -> void:
	local_player_name = assigned_name
	print("[NetworkManager] Registro confirmado con nombre: ", assigned_name)
	room_joined.emit()

# ===== MÉTODOS PRIVADOS =====

func _generate_room_code() -> String:
	var ip_addresses = IP.get_local_addresses()
	
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			return ip
	
	if ip_addresses.size() > 0:
		return ip_addresses[0]
	
	return "127.0.0.1"

func _validate_room_code(code: String) -> bool:
	if code.strip_edges().is_empty():
		return false
	
	var parts = code.split(".")
	if parts.size() != 4:
		return false
	
	for part in parts:
		if not part.is_valid_int():
			return false
		var num = int(part)
		if num < 0 or num > 255:
			return false
	
	return true

func _ensure_unique_name(player_name: String) -> String:
	var base_name = player_name
	var counter = 2
	var final_name = base_name
	
	while _name_exists(final_name):
		final_name = base_name + " (" + str(counter) + ")"
		counter += 1
	
	return final_name

func _name_exists(name: String) -> bool:
	for player_data in players.values():
		if player_data.get("player_name", "") == name:
			return true
	return false
