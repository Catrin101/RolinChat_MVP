# scripts/autoloads/data_manager.gd
extends Node

## DataManager - Carga y valida JSONs de configuración
## Responsable de cargar: razas.json, sexos.json, acciones_rol.json

# ===== RUTAS DE ARCHIVOS =====
const RAZAS_PATH := "res://data/razas.json"
const SEXOS_PATH := "res://data/sexos.json"
const ACCIONES_PATH := "res://data/acciones_rol.json"

# ===== DATOS CARGADOS =====
var razas: Array = []
var sexos: Array = []
var acciones_rol: Array = []

# ===== ESTADO =====
var is_loaded := false

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	load_all_data()

## Carga todos los archivos JSON necesarios
func load_all_data() -> void:
	print("[DataManager] Cargando datos...")
	
	razas = _load_json_file(RAZAS_PATH, "razas")
	sexos = _load_json_file(SEXOS_PATH, "sexos")
	acciones_rol = _load_json_file(ACCIONES_PATH, "acciones_rol")
	
	if razas.is_empty() or sexos.is_empty() or acciones_rol.is_empty():
		push_error("[DataManager] ERROR: Archivos JSON faltantes o vacíos")
		is_loaded = false
	else:
		is_loaded = true
		print("[DataManager] Datos cargados correctamente:")
		print("  - Razas: ", razas.size())
		print("  - Sexos: ", sexos.size())
		print("  - Acciones de Rol: ", acciones_rol.size())

# ===== MÉTODOS DE CONSULTA =====

## Obtiene una raza por ID
func get_raza_by_id(raza_id: String) -> Dictionary:
	for raza in razas:
		if raza.get("id") == raza_id:
			return raza
	push_warning("[DataManager] Raza no encontrada: " + raza_id)
	return {}

## Obtiene un sexo por ID
func get_sexo_by_id(sexo_id: String) -> Dictionary:
	for sexo in sexos:
		if sexo.get("id") == sexo_id:
			return sexo
	push_warning("[DataManager] Sexo no encontrado: " + sexo_id)
	return {}

## Obtiene una acción por ID
func get_accion_by_id(accion_id: String) -> Dictionary:
	for accion in acciones_rol:
		if accion.get("id") == accion_id:
			return accion
	push_warning("[DataManager] Acción no encontrada: " + accion_id)
	return {}

## Filtra acciones compatibles con dos avatares dados
## actor_data y target_data deben tener campos "raza_id" y "sexo_id"
func get_compatible_actions(actor_data: Dictionary, target_data: Dictionary) -> Array:
	if not is_loaded:
		push_error("[DataManager] Datos no cargados")
		return []
	
	var compatible := []
	
	for accion in acciones_rol:
		if _is_action_compatible(accion, actor_data, target_data):
			compatible.append(accion)
	
	return compatible

# ===== MÉTODOS PRIVADOS =====

## Verifica si una acción es compatible con dos avatares
func _is_action_compatible(accion: Dictionary, actor: Dictionary, target: Dictionary) -> bool:
	# Verificar estructura
	if not accion.has("combinaciones_sexo") or not accion.has("combinaciones_raza"):
		return false
	
	var actor_sexo: String = str(actor.get("sexo_id", ""))
	var actor_raza: String = str(actor.get("raza_id", ""))
	var target_sexo: String = str(target.get("sexo_id", ""))
	var target_raza: String = str(target.get("raza_id", ""))
	
	# Verificar compatibilidad de sexo
	var sexo_compatible := false
	for combinacion in accion["combinaciones_sexo"]:
		if combinacion is Array and combinacion.size() == 2:
			if (combinacion[0] == actor_sexo and combinacion[1] == target_sexo) or \
			   (combinacion[0] == target_sexo and combinacion[1] == actor_sexo):
				sexo_compatible = true
				break
	
	if not sexo_compatible:
		return false
	
	# Verificar compatibilidad de raza
	var raza_compatible := false
	for combinacion in accion["combinaciones_raza"]:
		if combinacion is Array and combinacion.size() == 2:
			if (combinacion[0] == actor_raza and combinacion[1] == target_raza) or \
			   (combinacion[0] == target_raza and combinacion[1] == actor_raza):
				raza_compatible = true
				break
	
	return raza_compatible

## Carga un archivo JSON y valida su contenido
func _load_json_file(path: String, expected_key: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("[DataManager] Archivo no encontrado: " + path)
		return []
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataManager] No se pudo abrir: " + path)
		return []
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	
	if error != OK:
		push_error("[DataManager] Error parseando " + path + " en línea " + str(json.get_error_line()) + ": " + json.get_error_message())
		return []
	
	var data = json.data
	
	# Validar estructura
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[DataManager] JSON inválido (no es Dictionary): " + path)
		return []
	
	if not data.has(expected_key):
		push_error("[DataManager] JSON no contiene clave '" + expected_key + "': " + path)
		return []
	
	if typeof(data[expected_key]) != TYPE_ARRAY:
		push_error("[DataManager] La clave '" + expected_key + "' no es Array: " + path)
		return []
	
	return data[expected_key]
