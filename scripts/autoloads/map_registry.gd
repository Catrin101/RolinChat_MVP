# scripts/autoloads/map_registry.gd
extends Node

## MapRegistry - Registro de todos los mapas disponibles
## Permite seleccionar mapas al crear salas

# ===== ESTRUCTURA DE MAPA =====
class MapInfo:
	var map_id: String
	var display_name: String
	var description: String
	var thumbnail_path: String
	var scene_path: String
	var max_players: int
	var spawn_count: int
	
	func _init(id: String, name: String, desc: String, thumb: String, scene: String, max_p: int = 8, spawns: int = 8):
		map_id = id
		display_name = name
		description = desc
		thumbnail_path = thumb
		scene_path = scene
		max_players = max_p
		spawn_count = spawns

# ===== MAPAS REGISTRADOS =====
var registered_maps: Dictionary = {}
var default_map_id: String = "default_lobby"

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_register_default_maps()
	print("[MapRegistry] Mapas registrados: ", registered_maps.size())

# ===== REGISTRO DE MAPAS =====

func _register_default_maps() -> void:
	# Mapa por defecto - Lobby Básico
	register_map(MapInfo.new(
		"default_lobby",
		"Lobby Básico",
		"Un espacio simple para comenzar tu aventura de rol",
		"res://assets/maps/thumbnails/lobby_basic.png",
		"res://scenes/maps/default_lobby.tscn",
		8,
		8
	))
	
	# Mapa 2 - Taverna Medieval
	register_map(MapInfo.new(
		"medieval_tavern",
		"Taverna del Dragón Dorado",
		"Una acogedora taberna con mesas, barras y chimenea",
		"res://assets/maps/thumbnails/tavern.png",
		"res://scenes/maps/medieval_tavern.tscn",
		10,
		10
	))
	
	# Mapa 3 - Plaza de la Ciudad
	register_map(MapInfo.new(
		"city_plaza",
		"Plaza Central",
		"Una plaza pública con fuente, bancos y árboles",
		"res://assets/maps/thumbnails/plaza.png",
		"res://scenes/maps/city_plaza.tscn",
		12,
		12
	))
	
	# Mapa 4 - Bosque Encantado
	register_map(MapInfo.new(
		"enchanted_forest",
		"Bosque Místico",
		"Un claro en el bosque con hongos gigantes y árboles antiguos",
		"res://assets/maps/thumbnails/forest.png",
		"res://scenes/maps/enchanted_forest.tscn",
		6,
		6
	))
	
	# Mapa 5 - Castillo Real
	register_map(MapInfo.new(
		"royal_castle",
		"Salón del Trono",
		"El gran salón del castillo con alfombras y columnas",
		"res://assets/maps/thumbnails/castle.png",
		"res://scenes/maps/royal_castle.tscn",
		8,
		8
	))

## Registra un nuevo mapa
func register_map(map_info: MapInfo) -> void:
	registered_maps[map_info.map_id] = map_info
	print("[MapRegistry] Mapa registrado: ", map_info.display_name)

## Obtiene información de un mapa
func get_map_info(map_id: String) -> MapInfo:
	return registered_maps.get(map_id, null)

## Obtiene lista de todos los mapas
func get_all_maps() -> Array:
	return registered_maps.values()

## Obtiene IDs de todos los mapas
func get_map_ids() -> Array:
	return registered_maps.keys()

## Verifica si un mapa existe
func map_exists(map_id: String) -> bool:
	return registered_maps.has(map_id)

## Obtiene el mapa por defecto
func get_default_map() -> MapInfo:
	return registered_maps.get(default_map_id, null)
