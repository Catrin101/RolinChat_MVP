# scripts/world/world_controller.gd
extends Node2D

## WorldController - Gestiona el mundo del juego
## Spawn de jugadores, sincronización y gestión del mapa

# ===== ESCENAS PRECARGADAS =====
const AVATAR_DISPLAY_SCENE := preload("res://scenes/avatar_display.tscn")

# ===== NODOS =====
@onready var tilemap: TileMap = $TileMap
@onready var players_container: Node2D = $PlayersContainer
@onready var camera: Camera2D = $Camera2D

# ===== SPAWN POINTS =====
var spawn_points: Array[Vector2] = [
	Vector2(200, 200),
	Vector2(300, 200),
	Vector2(400, 200),
	Vector2(200, 300),
	Vector2(300, 300),
	Vector2(400, 300),
	Vector2(200, 400),
	Vector2(300, 400)
]

var used_spawn_indices: Array[int] = []

# ===== JUGADORES =====
# Dictionary: { peer_id: AvatarDisplay_instance }
var spawned_players: Dictionary = {}

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_load_selected_map()
	_spawn_local_player()
	_request_existing_players()

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)
	EventBus.avatar_changed.connect(_on_avatar_changed)
	
	# Señales de networking específicas
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

## Carga el mapa seleccionado por el host
func _load_selected_map() -> void:
	var map_id := GameManager.get_current_map_id()
	var map_info = MapRegistry.get_map_info(map_id)
	
	if not map_info:
		push_error("[WorldController] Mapa no encontrado: ", map_id)
		map_id = "default_lobby"
		map_info = MapRegistry.get_default_map()
	
	print("[WorldController] Cargando mapa: ", map_info.display_name)
	
	# Cargar escena del mapa si existe
	if ResourceLoader.exists(map_info.scene_path):
		var map_scene_packed = load(map_info.scene_path)
		var map_scene = map_scene_packed.instantiate()
		
		# Buscar TileMap en el mapa
		var loaded_tilemap = map_scene.get_node_or_null("TileMap")
		if loaded_tilemap:
			# Reemplazar el TileMap actual
			if tilemap:
				tilemap.queue_free()
			tilemap = loaded_tilemap
		
		# El mapa puede contener otros elementos (decoración, objetos)
		# Los agregamos como hijos
		for child in map_scene.get_children():
			if child != loaded_tilemap: # No duplicar el tilemap
				map_scene.remove_child(child)
				add_child(child)
		
		map_scene.queue_free()
	else:
		push_warning("[WorldController] Escena de mapa no existe: ", map_info.scene_path)
		# Usar el TileMap por defecto que ya existe en la escena

# ===== SPAWN DE JUGADORES =====

## Spawnea al jugador local
func _spawn_local_player() -> void:
	var local_peer_id := multiplayer.get_unique_id()
	var spawn_pos := _get_spawn_position()
	
	_spawn_player(local_peer_id, GameManager.local_avatar_data, spawn_pos, true)
	
	print("[WorldController] Jugador local spawneado en: ", spawn_pos)

## Solicita la lista de jugadores existentes (para clientes que se unen)
func _request_existing_players() -> void:
	if not GameManager.is_host:
		# Esperar un momento para que el servidor esté listo
		await get_tree().create_timer(0.5).timeout
		_request_player_list.rpc_id(1)

## RPC para solicitar lista de jugadores (cliente → servidor)
@rpc("any_peer", "reliable")
func _request_player_list() -> void:
	if not GameManager.is_host:
		return
	
	var sender_id := multiplayer.get_remote_sender_id()
	
	# Enviar cada jugador existente al nuevo cliente
	for peer_id in GameManager.connected_players.keys():
		if peer_id != sender_id and spawned_players.has(peer_id):
			var player_avatar = spawned_players[peer_id]
			var player_data := GameManager.get_player_data(peer_id)
			var position: Vector2 = player_avatar.global_position
			
			_sync_spawn_player.rpc_id(sender_id, peer_id, player_data, position)

## Spawnea un jugador (lógica local)
func _spawn_player(peer_id: int, avatar_data: Dictionary, position: Vector2, is_local: bool = false) -> void:
	# Evitar duplicados
	if spawned_players.has(peer_id):
		push_warning("[WorldController] Jugador ya spawneado: ", peer_id)
		return
	
	# Instanciar avatar
	var avatar_display: AvatarDisplay = AVATAR_DISPLAY_SCENE.instantiate()
	avatar_display.name = "Player_" + str(peer_id)
	avatar_display.setup(peer_id, avatar_data, is_local)
	avatar_display.global_position = position
	
	players_container.add_child(avatar_display)
	spawned_players[peer_id] = avatar_display
	
	print("[WorldController] Jugador spawneado - ID: ", peer_id, " Nombre: ", avatar_data.get("nombre"))

## RPC para sincronizar spawn entre todos los clientes
@rpc("authority", "reliable")
func _sync_spawn_player(peer_id: int, avatar_data: Dictionary, position: Vector2) -> void:
	_spawn_player(peer_id, avatar_data, position, false)

# ===== CALLBACKS DE NETWORKING =====

func _on_peer_connected(id: int) -> void:
	if not GameManager.is_host:
		return
	
	# Esperar a que el jugador registre su avatar
	await get_tree().create_timer(0.5).timeout
	
	var avatar_data := GameManager.get_player_data(id)
	
	if avatar_data.is_empty():
		push_warning("[WorldController] Avatar data no disponible para peer: ", id)
		return
	
	var spawn_pos := _get_spawn_position()
	
	# Spawnear localmente
	_spawn_player(id, avatar_data, spawn_pos, false)
	
	# Sincronizar con todos los clientes
	_sync_spawn_player.rpc(id, avatar_data, spawn_pos)

func _on_peer_disconnected(id: int) -> void:
	_despawn_player(id)

func _on_player_connected(peer_id: int, player_name: String) -> void:
	# Ya manejado por _on_peer_connected
	pass

func _on_player_disconnected(peer_id: int) -> void:
	_despawn_player(peer_id)

func _on_avatar_changed(peer_id: int, avatar_data: Dictionary) -> void:
	# Actualizar avatar existente
	if spawned_players.has(peer_id):
		var player_avatar: AvatarDisplay = spawned_players[peer_id]
		player_avatar.update_avatar_data(avatar_data)

# ===== DESPAWN DE JUGADORES =====

func _despawn_player(peer_id: int) -> void:
	if spawned_players.has(peer_id):
		var player_avatar = spawned_players[peer_id]
		player_avatar.queue_free()
		spawned_players.erase(peer_id)
		
		print("[WorldController] Jugador despawneado: ", peer_id)

# ===== GESTIÓN DE SPAWN POINTS =====

func _get_spawn_position() -> Vector2:
	# Buscar spawn point libre
	for i in range(spawn_points.size()):
		if i not in used_spawn_indices:
			used_spawn_indices.append(i)
			return spawn_points[i]
	
	# Si todos están ocupados, usar uno aleatorio
	var random_index := randi() % spawn_points.size()
	return spawn_points[random_index]

# ===== SINCRONIZACIÓN DE POSICIÓN =====

## Actualiza la posición de un jugador remoto
@rpc("any_peer", "unreliable")
func sync_player_position(peer_id: int, position: Vector2) -> void:
	if spawned_players.has(peer_id):
		var player_avatar: AvatarDisplay = spawned_players[peer_id]
		player_avatar.update_position(position)

# ===== INTERACCIÓN ENTRE JUGADORES =====

## Solicita interacción con otro jugador
func request_interaction(target_peer_id: int) -> void:
	var local_peer_id := multiplayer.get_unique_id()
	_request_interaction_rpc.rpc_id(target_peer_id, local_peer_id)

## RPC para solicitar interacción
@rpc("any_peer", "reliable")
func _request_interaction_rpc(actor_peer_id: int) -> void:
	var target_peer_id := multiplayer.get_unique_id()
	
	# Verificar distancia
	if not _are_players_close(actor_peer_id, target_peer_id):
		EventBus.emit_system_message("El jugador está muy lejos")
		return
	
	# Emitir señal para mostrar selector de acciones
	EventBus.interaction_requested.emit(actor_peer_id, target_peer_id, "")

## Verifica si dos jugadores están cerca
func _are_players_close(peer_id_a: int, peer_id_b: int, max_distance: float = 100.0) -> bool:
	if not spawned_players.has(peer_id_a) or not spawned_players.has(peer_id_b):
		return false
	
	var pos_a: Vector2 = spawned_players[peer_id_a].global_position
	var pos_b: Vector2 = spawned_players[peer_id_b].global_position
	
	return pos_a.distance_to(pos_b) <= max_distance

## Obtiene jugadores cercanos al peer dado
func get_nearby_players(peer_id: int, max_distance: float = 100.0) -> Array:
	var nearby := []
	
	if not spawned_players.has(peer_id):
		return nearby
	
	var origin_pos: Vector2 = spawned_players[peer_id].global_position
	
	for other_peer_id in spawned_players.keys():
		if other_peer_id == peer_id:
			continue
		
		var other_pos: Vector2 = spawned_players[other_peer_id].global_position
		
		if origin_pos.distance_to(other_pos) <= max_distance:
			nearby.append({
				"peer_id": other_peer_id,
				"avatar_data": GameManager.get_player_data(other_peer_id),
				"distance": origin_pos.distance_to(other_pos)
			})
	
	# Ordenar por distancia
	nearby.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	return nearby
