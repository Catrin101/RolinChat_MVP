extends Area2D

## Trigger placed on objects to detect nearby players and start interactions.

@onready var prompt: Label = %Prompt
var players_in_range: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name.to_int() > 0: # It's a player avatar
		players_in_range.append(body)
		_update_prompt()

func _on_body_exited(body: Node2D) -> void:
	players_in_range.erase(body)
	_update_prompt()

func _update_prompt() -> void:
	# Only show prompt if local player is in range
	var local_id = str(multiplayer.get_unique_id())
	var local_present = false
	for p in players_in_range:
		if p.name == local_id:
			local_present = true
			break
	
	prompt.visible = local_present and players_in_range.size() >= 2

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and prompt.visible:
		_start_interaction()

func _start_interaction() -> void:
	# In a real game, this would open a menu to select the action.
	# For the MVP, we pick the first compatible action for demonstration.
	var p1 = players_in_range[0]
	var p2 = players_in_range[1]
	
	var p1_id = p1.name.to_int()
	var p2_id = p2.name.to_int()
	
	var p1_info = NetworkManager.players.get(p1_id, {})
	var p2_info = NetworkManager.players.get(p2_id, {})
	
	var compatible = InteractionManager.get_compatible_actions(p1_info, p2_info)
	
	if compatible.size() > 0:
		_trigger_joint_scene.rpc(compatible[0].id, p1_id, p2_id)
	else:
		print("No hay acciones compatibles entre estos jugadores.")

@rpc("any_peer", "call_local", "reliable")
func _trigger_joint_scene(action_id: String, p1_id: int, p2_id: int) -> void:
	var overlay_scene = load("res://scenes/ui/joint_scene_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	get_tree().root.add_child(overlay)
	
	var action = null
	for a in ConfigLoader.get_all_acciones():
		if a.id == action_id:
			action = a
			break
	
	if action:
		overlay.display_action(
			action,
			NetworkManager.get_player_name(p1_id),
			NetworkManager.get_player_name(p2_id)
		)
