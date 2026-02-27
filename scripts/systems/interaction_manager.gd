extends Node

## Singleton to handle the filtering and triggering of joint roleplay actions.

func get_compatible_actions(p1_info: Dictionary, p2_info: Dictionary) -> Array:
	var p1_data = AvatarData.from_dict(p1_info.get("avatar", {}))
	var p2_data = AvatarData.from_dict(p2_info.get("avatar", {}))
	
	var all_actions = ConfigLoader.get_all_acciones()
	var compatible = []
	
	for action in all_actions:
		if _is_compatible(action, p1_data, p2_data):
			compatible.append(action)
			
	return compatible

func _is_compatible(action: Dictionary, p1: AvatarData, p2: AvatarData) -> bool:
	# 1. Check Sex combinations
	var sex_match = false
	var combo_sexos = action.get("combinaciones_sexo", [])
	for combo in combo_sexos:
		if (combo[0] == p1.sexo_id and combo[1] == p2.sexo_id) or \
		   (combo[0] == p2.sexo_id and combo[1] == p1.sexo_id):
			sex_match = true
			break
	
	if not sex_match: return false
	
	# 2. Check Race combinations
	var race_match = false
	var combo_razas = action.get("combinaciones_raza", [])
	for combo in combo_razas:
		if (combo[0] == p1.raza_id and combo[1] == p2.raza_id) or \
		   (combo[0] == p2.raza_id and combo[1] == p1.raza_id):
			race_match = true
			break
			
	return race_match
