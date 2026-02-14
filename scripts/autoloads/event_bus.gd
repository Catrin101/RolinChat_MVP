# scripts/autoloads/event_bus.gd
extends Node

## EventBus simplificado para el MVP
## Centraliza todas las señales del juego para desacoplar sistemas

# ===== SEÑALES DE NETWORKING =====
signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal room_created(room_code: String)
signal room_joined(room_code: String)
signal connection_failed(error_message: String)

# ===== SEÑALES DE AVATARES =====
signal avatar_changed(peer_id: int, avatar_data: Dictionary)
signal avatar_loaded(peer_id: int)

# ===== SEÑALES DE CHAT =====
signal message_received(sender_name: String, text: String)
signal system_message(text: String)

# ===== SEÑALES DE INTERACCIÓN =====
signal interaction_requested(actor_peer_id: int, target_peer_id: int, action_id: String)
signal interaction_accepted(actor_peer_id: int, target_peer_id: int, action_id: String)
signal interaction_rejected(actor_peer_id: int, target_peer_id: int)
signal animation_overlay_shown(image_url: String, action_name: String)
signal animation_overlay_closed()

# ===== SEÑALES DE MAPA =====
signal map_loaded(map_name: String)
signal player_spawned(peer_id: int, position: Vector2)

# ===== MÉTODOS AUXILIARES =====

## Emite un mensaje de sistema en el chat
func emit_system_message(text: String) -> void:
	system_message.emit(text)

## Emite un mensaje de error de conexión
func emit_connection_error(error_text: String) -> void:
	connection_failed.emit(error_text)
	system_message.emit("[color=red]ERROR: " + error_text + "[/color]")
