extends Resource
class_name AvatarData

## Resource class defining the structure of a character avatar based on JSON specifications.

@export var id: String = ""
@export var nombre: String = "Nuevo Personaje"
@export var descripcion: String = ""
@export var imagen_url: String = ""
@export var raza_id: String = "humano"
@export var sexo_id: String = "masculino"

func _init(_id: String = "", _nombre: String = "Nuevo Personaje", _descripcion: String = "", _imagen_url: String = "", _raza_id: String = "humano", _sexo_id: String = "masculino") -> void:
	self.id = _id if _id != "" else str(UUID_Utils.v4())

	self.nombre = _nombre
	self.descripcion = _descripcion
	self.imagen_url = _imagen_url
	self.raza_id = _raza_id
	self.sexo_id = _sexo_id

func to_dict() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"descripcion": descripcion,
		"imagen_url": imagen_url,
		"raza_id": raza_id,
		"sexo_id": sexo_id
	}

static func from_dict(data: Dictionary) -> AvatarData:
	return AvatarData.new(
		data.get("id", ""),
		data.get("nombre", "Sin Nombre"),
		data.get("descripcion", ""),
		data.get("imagen_url", ""),
		data.get("raza_id", "humano"),
		data.get("sexo_id", "masculino")
	)

func save_to_json(path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	
	var json_string = JSON.stringify(to_dict(), "\t")
	file.store_string(json_string)
	return OK

static func load_from_json(path: String) -> AvatarData:
	if not FileAccess.file_exists(path):
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK:
		return null
	
	return AvatarData.from_dict(json.data)
