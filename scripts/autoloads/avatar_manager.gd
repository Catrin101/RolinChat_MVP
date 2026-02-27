extends Node

## Singleton to manage local character profiles and the active avatar.

const PROFILES_DIR = "user://profiles/"

signal avatar_changed(new_avatar: AvatarData)
signal profiles_updated

var current_avatar: AvatarData = null
var available_profiles: Array[String] = []

func _ready() -> void:
	_ensure_dir_exists()
	refresh_profiles()
	
	# Load default or last used if needed
	if available_profiles.size() > 0:
		load_profile(available_profiles[0])

func _ensure_dir_exists() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)

func refresh_profiles() -> void:
	available_profiles.clear()
	var dir = DirAccess.open(PROFILES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				available_profiles.append(file_name.replace(".json", ""))
			file_name = dir.get_next()
	
	profiles_updated.emit()

func save_profile(avatar: AvatarData) -> void:
	var path = PROFILES_DIR + avatar.nombre + ".json"
	var error = avatar.save_to_json(path)
	if error == OK:
		print("[AvatarManager] Profile saved: ", avatar.nombre)
		refresh_profiles()
	else:
		printerr("[AvatarManager] Failed to save profile: ", error)

func load_profile(profile_name: String) -> void:
	var path = PROFILES_DIR + profile_name + ".json"
	var avatar = AvatarData.load_from_json(path)
	if avatar:
		current_avatar = avatar
		avatar_changed.emit(current_avatar)
		print("[AvatarManager] Profile loaded: ", profile_name)
	else:
		printerr("[AvatarManager] Failed to load profile: ", profile_name)

func delete_profile(profile_name: String) -> void:
	var path = PROFILES_DIR + profile_name + ".json"
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(PROFILES_DIR)
		dir.remove(profile_name + ".json")
		refresh_profiles()
		print("[AvatarManager] Profile deleted: ", profile_name)

func get_active_avatar() -> AvatarData:
	return current_avatar
