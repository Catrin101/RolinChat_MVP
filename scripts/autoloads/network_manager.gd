# scripts/autoloads/network_manager.gd
extends Node

## NetworkManager - Gestión de conexiones Host-Client (MVP)
## Implementa networking básico usando ENetMultiplayerPeer

# ===== CONSTANTES =====
const DEFAULT_PORT := 7777
const MAX_CLIENTS := 10

# ===== ESTADO DE RED =====
var peer: ENetMultiplayerPeer = null
var is_server: bool = false

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ===== SEÑALES =====
signal player_position_updated(peer_id: int, position: Vector2)

# ===== CREACIÓN DE SALA (HOST) =====

## Crea una sala como servidor
func create_room() -> String:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	
	if error != OK:
		EventBus.emit_connection_error("No se pudo crear el servidor")
		return ""
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	
	# Generar código de sala (IP:Puerto simplificado)
	var room_code := _generate_room_code()
	GameManager.current_room_code = room_code
	GameManager.is_host = true
	GameManager.local_peer_id = multiplayer.get_unique_id()
	
	# Registrar al host como jugador
	GameManager.register_player(GameManager.local_peer_id, GameManager.local_avatar_data)
	
	EventBus.room_created.emit(room_code)
	EventBus.emit_system_message("Sala creada con código: " + room_code)
	
	print("[NetworkManager] Sala creada - Código: ", room_code)
	return room_code

# ===== UNIRSE A SALA (CLIENT) =====

## Se une a una sala existente usando código
func join_room(room_code: String) -> void:
	var connection_data := _parse_room_code(room_code)
	
	if connection_data.is_empty():
		EventBus.emit_connection_error("Código de sala inválido")
		return
	
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(connection_data["ip"], connection_data["port"])
	
	if error != OK:
		EventBus.emit_connection_error("No se pudo conectar al servidor")
		return
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	GameManager.is_host = false
	
	print("[NetworkManager] Conectando a sala: ", room_code)

# ===== SALIR DE SALA =====

## Desconecta del servidor y limpia el estado
func leave_room() -> void:
	if peer != null:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	is_server = false
	
	GameManager.reset_session()
	EventBus.emit_system_message("Has salido de la sala")
	
	print("[NetworkManager] Desconectado de la sala")

# ===== SINCRONIZACIÓN DE AVATARES =====

## El cliente envía su avatar al servidor cuando se conecta
@rpc("any_peer", "reliable")
func register_avatar(avatar_data: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	
	print("[NetworkManager] Avatar recibido de peer ", sender_id)
	GameManager.register_player(sender_id, avatar_data)
	EventBus.avatar_loaded.emit(sender_id)
	
	# Notificar a todos los clientes sobre el nuevo jugador
	if is_server:
		_sync_player_joined.rpc(sender_id, avatar_data)

## Sincroniza la unión de un jugador a todos los clientes
@rpc("authority", "reliable")
func _sync_player_joined(peer_id: int, avatar_data: Dictionary) -> void:
	GameManager.register_player(peer_id, avatar_data)
	EventBus.player_connected.emit(peer_id, avatar_data.get("nombre", "Desconocido"))

## Sincroniza el cambio de avatar de un jugador
@rpc("any_peer", "reliable")
func sync_avatar_change(avatar_data: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	
	GameManager.register_player(sender_id, avatar_data)
	EventBus.avatar_changed.emit(sender_id, avatar_data)
	
	print("[NetworkManager] Avatar actualizado para peer ", sender_id)

# ===== SISTEMA DE CHAT =====

## Envía un mensaje de chat a todos los jugadores
@rpc("any_peer", "reliable")
func send_chat_message(text: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	var sender_data := GameManager.get_player_data(sender_id)
	var sender_name := sender_data.get("nombre", "Desconocido")
	
	# Reenviar a todos los clientes
	if is_server:
		_receive_chat_message.rpc(sender_name, text)
		# El servidor también debe recibir el mensaje
		_receive_chat_message(sender_name, text)

## Recibe un mensaje de chat (llamado por el servidor)
@rpc("authority", "reliable")
func _receive_chat_message(sender_name: String, text: String) -> void:
	EventBus.message_received.emit(sender_name, text)

# ===== SINCRONIZACIÓN DE POSICIÓN (BÁSICA) =====

## Sincroniza la posición de un jugador
@rpc("any_peer", "unreliable")
func sync_position(position: Vector2) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	
	# Reenviar a todos los demás clientes
	if is_server:
		_update_player_position.rpc(sender_id, position)

## Actualiza la posición de un jugador en todos los clientes
@rpc("authority", "unreliable")
func _update_player_position(peer_id: int, position: Vector2) -> void:
	# Emitir señal para que los avatares se actualicen
	player_position_updated.emit(peer_id, position)

# ===== CALLBACKS DE NETWORKING =====

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer conectado: ", id)
	
	# Si somos el servidor, enviamos la lista actual de jugadores al nuevo cliente
	if is_server:
		_send_existing_players_to_new_client(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer desconectado: ", id)
	
	var player_data := GameManager.get_player_data(id)
	var player_name := player_data.get("nombre", "Desconocido")
	
	GameManager.unregister_player(id)
	EventBus.player_disconnected.emit(id)
	EventBus.emit_system_message(player_name + " se ha desconectado")

func _on_connected_to_server() -> void:
	print("[NetworkManager] Conectado al servidor")
	
	GameManager.local_peer_id = multiplayer.get_unique_id()
	GameManager.register_player(GameManager.local_peer_id, GameManager.local_avatar_data)
	
	# Enviar nuestro avatar al servidor
	register_avatar.rpc_id(1, GameManager.local_avatar_data)
	
	EventBus.room_joined.emit(GameManager.current_room_code)
	EventBus.emit_system_message("Conectado a la sala")

func _on_connection_failed() -> void:
	print("[NetworkManager] Conexión fallida")
	EventBus.emit_connection_error("No se pudo conectar a la sala")
	peer = null

func _on_server_disconnected() -> void:
	print("[NetworkManager] Servidor desconectado")
	EventBus.emit_system_message("El host ha cerrado la sala")
	leave_room()

# ===== MÉTODOS PRIVADOS =====

## Genera un código de sala simple (8 caracteres alfanuméricos)
func _generate_room_code() -> String:
	const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code := ""
	for i in range(8):
		code += CHARS[randi() % CHARS.length()]
	return code

## Parsea un código de sala en IP:Puerto
func _parse_room_code(code: String) -> Dictionary:
	# Por ahora usamos localhost por defecto
	# En producción, esto requeriría un servidor de matchmaking
	return {
		"ip": "127.0.0.1",
		"port": DEFAULT_PORT
	}

## Envía la lista de jugadores existentes a un nuevo cliente
func _send_existing_players_to_new_client(new_client_id: int) -> void:
	for peer_id in GameManager.connected_players.keys():
		if peer_id != new_client_id:
			var player_data := GameManager.get_player_data(peer_id)
			_sync_player_joined.rpc_id(new_client_id, peer_id, player_data)
