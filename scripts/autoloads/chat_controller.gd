extends Node

## Singleton to handle chat messages and roleplay commands.

signal message_received(sender_id: int, message: String, type: String)

enum MsgType {IC, OOC, ACTION, DICE}

@onready var network_manager = get_node("/root/NetworkManager")

func send_message(text: String) -> void:
	var id = multiplayer.get_unique_id()
	_receive_message.rpc(id, text)

@rpc("any_peer", "call_local", "reliable")
func _receive_message(sender_id: int, text: String) -> void:
	var parsed = _parse_command(text)
	message_received.emit(sender_id, parsed.text, parsed.type)

func _parse_command(text: String) -> Dictionary:
	var type = "IC"
	var final_text = text
	
	if text.begins_with("//") or text.begins_with("/ooc "):
		type = "OOC"
		final_text = text.trim_prefix("//").trim_prefix("/ooc ")
	elif text.begins_with("/me "):
		type = "ACTION"
		final_text = text.trim_prefix("/me ")
	elif text.begins_with("/roll "):
		type = "DICE"
		final_text = _handle_roll(text.trim_prefix("/roll "))
	
	return {"text": final_text, "type": type}

func _handle_roll(dice_expr: String) -> String:
	# Basic XdY parser
	var parts = dice_expr.split("d")
	if parts.size() != 2: return "Error en formato de dado"
	
	var count = int(parts[0])
	var sides = int(parts[1])
	
	if count <= 0 or sides <= 0: return "Valores inválidos"
	if count > 20: return "Demasiados dados (max 20)"
	
	var results = []
	var total = 0
	for i in range(count):
		var r = (randi() % sides) + 1
		results.append(str(r))
		total += r
	
	return "lanzó %sd%s: [%s] = %d" % [str(count), str(sides), ", ".join(results), total]
