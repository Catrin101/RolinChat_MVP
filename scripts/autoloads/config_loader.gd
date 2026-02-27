extends Node

## Singleton to load and provide access to global JSON configuration files.

var razas_db: Dictionary = {}
var sexos_db: Dictionary = {}
var acciones_db: Array = []

func _ready() -> void:
	load_all_configs()

func load_all_configs() -> void:
	razas_db = _load_json("res://data/razas.json").get("razas", {}).reduce(func(acc, item):
		acc[item.id] = item
		return acc
	, {})
	
	sexos_db = _load_json("res://data/sexos.json").get("sexos", {}).reduce(func(acc, item):
		acc[item.id] = item
		return acc
	, {})
	
	acciones_db = _load_json("res://data/acciones_rol.json").get("acciones", [])
	
	print("[ConfigLoader] Data loaded successfully.")
	print("  - Razas: ", razas_db.keys().size())
	print("  - Sexos: ", sexos_db.keys().size())
	print("  - Acciones: ", acciones_db.size())

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		printerr("[ConfigLoader] File not found: ", path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK:
		printerr("[ConfigLoader] JSON Parse Error at line ", json.get_error_line(), ": ", json.get_error_message())
		return {}
	
	return json.data

func get_raza(id: String) -> Dictionary:
	return razas_db.get(id, {})

func get_sexo(id: String) -> Dictionary:
	return sexos_db.get(id, {})

func get_all_razas() -> Array:
	return razas_db.values()

func get_all_sexos() -> Array:
	return sexos_db.values()

func get_all_acciones() -> Array:
	return acciones_db
