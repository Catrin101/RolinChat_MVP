# scripts/autoloads/game_manager.gd
extends Node

## GameManager - Estado global del juego (MVP simplificado)
## Almacena información de la sesión actual

# ===== CONSTANTES =====
const PROFILES_DIR := "user://profiles/"
const DEFAULT_AVATAR_IMAGE := "res://assets/default_avatar.png"

# ===== ESTADO DE LA SESIÓN =====
var local_peer_id: int = 0
var is_host: bool = false
var current_room_code: String = ""
var current_map: String = ""

# ===== PERFIL DEL JUGADOR LOCAL =====
var local_avatar_data: Dictionary = {}

# ===== PERFILES DE JUGADORES CONECTADOS =====
# Dictionary con estructura: { peer_id: avatar_data }
var connected_players: Dictionary = {}

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_ensure_profiles_directory()
	_load_last_used_avatar()

# ===== GESTIÓN DE PERFILES =====

## Asegura que exista el directorio de perfiles
func _ensure_profiles_directory() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_absolute(PROFILES_DIR)
		print("[GameManager] Directorio de perfiles creado: ", PROFILES_DIR)

## Carga el último avatar usado (o crea uno por defecto)
func _load_last_used_avatar() -> void:
	var last_profile_path := PROFILES_DIR + "last_used.json"
	
	if FileAccess.file_exists(last_profile_path):
		local_avatar_data = _load_avatar_from_file(last_profile_path)
		print("[GameManager] Avatar cargado: ", local_avatar_data.get("nombre", "Sin nombre"))
	else:
		local_avatar_data = _create_default_avatar()
		save_avatar(local_avatar_data, "last_used.json")
		print("[GameManager] Avatar por defecto creado")

## Crea un avatar por defecto
func _create_default_avatar() -> Dictionary:
	return {
		"id": _generate_uuid(),
		"nombre": "Jugador",
		"descripcion": "Un aventurero sin nombre",
		"imagen_url": DEFAULT_AVATAR_IMAGE,
		"raza_id": "humano",
		"sexo_id": "masculino"
	}

## Guarda un avatar en un archivo
func save_avatar(avatar_data: Dictionary, filename: String) -> bool:
	var filepath := PROFILES_DIR + filename
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	
	if file == null:
		push_error("[GameManager] No se pudo guardar avatar: " + filepath)
		return false
	
	var json_string := JSON.stringify(avatar_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("[GameManager] Avatar guardado: ", filepath)
	return true

## Carga un avatar desde un archivo
func _load_avatar_from_file(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	
	if file == null:
		push_error("[GameManager] No se pudo cargar avatar: " + filepath)
		return _create_default_avatar()
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	
	if error != OK:
		push_error("[GameManager] Error parseando avatar: " + filepath)
		return _create_default_avatar()
	
	return json.data

## Lista todos los avatares guardados
func list_saved_avatars() -> Array:
	var profiles := []
	var dir := DirAccess.open(PROFILES_DIR)
	
	if dir == null:
		return profiles
	
	dir.list_dir_begin()
	var filename := dir.get_next()
	
	while filename != "":
		if filename.ends_with(".json"):
			var avatar_data := _load_avatar_from_file(PROFILES_DIR + filename)
			if not avatar_data.is_empty():
				profiles.append({
					"filename": filename,
					"data": avatar_data
				})
		filename = dir.get_next()
	
	return profiles

## Cambia el avatar activo del jugador local
func change_local_avatar(avatar_data: Dictionary) -> void:
	local_avatar_data = avatar_data
	save_avatar(avatar_data, "last_used.json")
	
	# Notificar al servidor si estamos conectados
	if local_peer_id != 0:
		EventBus.avatar_changed.emit(local_peer_id, avatar_data)

# ===== GESTIÓN DE JUGADORES CONECTADOS =====

## Registra un jugador conectado
func register_player(peer_id: int, avatar_data: Dictionary) -> void:
	connected_players[peer_id] = avatar_data
	print("[GameManager] Jugador registrado: ", peer_id, " - ", avatar_data.get("nombre"))

## Elimina un jugador desconectado
func unregister_player(peer_id: int) -> void:
	if connected_players.has(peer_id):
		var player_name := connected_players[peer_id].get("nombre", "Desconocido")
		connected_players.erase(peer_id)
		print("[GameManager] Jugador eliminado: ", peer_id, " - ", player_name)

## Obtiene los datos de un jugador por peer_id
func get_player_data(peer_id: int) -> Dictionary:
	if peer_id == local_peer_id:
		return local_avatar_data
	return connected_players.get(peer_id, {})

## Limpia todos los jugadores conectados (al salir de sala)
func clear_connected_players() -> void:
	connected_players.clear()
	print("[GameManager] Lista de jugadores limpiada")

# ===== UTILIDADES =====

## Genera un UUID simple
func _generate_uuid() -> String:
	var uuid := ""
	for i in range(32):
		uuid += str(randi() % 16)
		if i == 7 or i == 11 or i == 15 or i == 19:
			uuid += "-"
	return uuid

## Resetea el estado del juego (al salir de sala)
func reset_session() -> void:
	local_peer_id = 0
	is_host = false
	current_room_code = ""
	current_map = ""
	clear_connected_players()
	print("[GameManager] Sesión reseteada")
