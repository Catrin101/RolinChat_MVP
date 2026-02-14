# scripts/ui/hud_controller.gd
extends Control

## HUDController - Gestiona la interfaz superior del mundo
## Muestra código de sala, contador de jugadores y botón de salir

# ===== NODOS =====
@onready var room_code_label: Label = %RoomCodeLabel
@onready var players_count_label: Label = %PlayersCountLabel
@onready var leave_button: Button = %LeaveButton
@onready var interact_button: Button = %InteractButton

# ===== ESTADO =====
var nearby_player_peer_id: int = 0

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_update_room_info()
	_update_players_count()
	
	# Conectar señales de EventBus
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	leave_button.pressed.connect(_on_leave_pressed)
	interact_button.pressed.connect(_on_interact_pressed)

# ===== ACTUALIZACIÓN DE UI =====

func _update_room_info() -> void:
	var room_code := GameManager.current_room_code
	
	if room_code.is_empty():
		room_code_label.text = "Sala: Local"
	else:
		room_code_label.text = "Sala: " + room_code

func _update_players_count() -> void:
	var player_count := GameManager.connected_players.size()
	players_count_label.text = "Jugadores: %d/8" % player_count

# ===== DETECCIÓN DE JUGADORES CERCANOS =====

func _process(delta: float) -> void:
	_check_nearby_players()

func _check_nearby_players() -> void:
	var world_controller = get_tree().current_scene
	
	if not world_controller or not world_controller.has_method("get_nearby_players"):
		return
	
	var local_peer_id := multiplayer.get_unique_id()
	var nearby_players = world_controller.get_nearby_players(local_peer_id, 80.0)
	
	if nearby_players.size() > 0:
		nearby_player_peer_id = nearby_players[0]["peer_id"]
		var player_name: String = str(nearby_players[0]["avatar_data"].get("nombre", "Jugador"))
		
		interact_button.text = "Interactuar con " + player_name + " [E]"
		interact_button.show()
	else:
		nearby_player_peer_id = 0
		interact_button.hide()

# ===== INPUT =====

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if interact_button.visible:
			_on_interact_pressed()

# ===== CALLBACKS =====

func _on_leave_pressed() -> void:
	# Mostrar diálogo de confirmación
	var dialog := ConfirmationDialog.new()
	dialog.title = "Salir de la Sala"
	dialog.dialog_text = "¿Estás seguro de que quieres salir?"
	dialog.ok_button_text = "Salir"
	dialog.cancel_button_text = "Cancelar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(_confirm_leave)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func _confirm_leave() -> void:
	NetworkManager.leave_room()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_interact_pressed() -> void:
	if nearby_player_peer_id == 0:
		return
	
	# Solicitar interacción
	var world_controller = get_tree().current_scene
	
	if world_controller and world_controller.has_method("request_interaction"):
		# Mostrar selector de acciones
		_show_action_selector(nearby_player_peer_id)

func _on_player_connected(peer_id: int, player_name: String) -> void:
	_update_players_count()

func _on_player_disconnected(peer_id: int) -> void:
	_update_players_count()

# ===== SELECTOR DE ACCIONES =====

func _show_action_selector(target_peer_id: int) -> void:
	var local_data := GameManager.local_avatar_data
	var target_data := GameManager.get_player_data(target_peer_id)
	
	# Obtener acciones compatibles
	var compatible_actions := DataManager.get_compatible_actions(local_data, target_data)
	
	if compatible_actions.is_empty():
		EventBus.emit_system_message("No hay acciones compatibles con este jugador")
		return
	
	# Crear selector de acciones
	var action_selector := _create_action_selector(compatible_actions, target_peer_id)
	add_child(action_selector)

func _create_action_selector(actions: Array, target_peer_id: int) -> PopupPanel:
	var popup := PopupPanel.new()
	popup.size = Vector2(300, 400)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	popup.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "Selecciona una Acción"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var separator := HSeparator.new()
	vbox.add_child(separator)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)
	
	var actions_vbox := VBoxContainer.new()
	actions_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(actions_vbox)
	
	# Crear botón para cada acción
	for action in actions:
		var button := Button.new()
		button.text = action.get("nombre", "Acción")
		button.custom_minimum_size = Vector2(0, 40)
		
		button.pressed.connect(func():
			_on_action_selected(action, target_peer_id)
			popup.queue_free()
		)
		
		actions_vbox.add_child(button)
	
	var cancel_button := Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(popup.queue_free)
	vbox.add_child(cancel_button)
	
	popup.popup_centered()
	
	return popup

func _on_action_selected(action: Dictionary, target_peer_id: int) -> void:
	var local_peer_id := multiplayer.get_unique_id()
	
	# Enviar solicitud de acción al target
	_request_action_confirmation.rpc_id(target_peer_id, local_peer_id, action)

## RPC para solicitar confirmación de acción
@rpc("any_peer", "reliable")
func _request_action_confirmation(actor_peer_id: int, action_data: Dictionary) -> void:
	var actor_data := GameManager.get_player_data(actor_peer_id)
	var actor_name: String = str(actor_data.get("nombre", "Jugador"))
	var action_name: String = str(action_data.get("nombre", "Acción"))
	
	# Mostrar diálogo de confirmación
	var dialog := ConfirmationDialog.new()
	dialog.title = "Solicitud de Interacción"
	dialog.dialog_text = "%s quiere realizar: %s\n¿Aceptas?" % [actor_name, action_name]
	dialog.ok_button_text = "Aceptar"
	dialog.cancel_button_text = "Rechazar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		_accept_action.rpc_id(actor_peer_id, action_data)
		_show_animation_overlay(action_data, actor_data, GameManager.local_avatar_data)
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		_reject_action.rpc_id(actor_peer_id)
		dialog.queue_free()
	)
	
	dialog.close_requested.connect(dialog.queue_free)

## RPC para aceptar acción
@rpc("any_peer", "reliable")
func _accept_action(action_data: Dictionary) -> void:
	var target_peer_id := multiplayer.get_remote_sender_id()
	var target_data := GameManager.get_player_data(target_peer_id)
	
	_show_animation_overlay(action_data, GameManager.local_avatar_data, target_data)

## RPC para rechazar acción
@rpc("any_peer", "reliable")
func _reject_action() -> void:
	EventBus.emit_system_message("El jugador rechazó la interacción")

func _show_animation_overlay(action_data: Dictionary, actor_data: Dictionary, target_data: Dictionary) -> void:
	# Buscar el nodo AnimationOverlay
	var overlay = get_node_or_null("/root/WorldMap/CanvasLayer/AnimationOverlay")
	
	if not overlay:
		# Crear el overlay si no existe
		var overlay_scene := load("res://scenes/ui/animation_overlay.tscn")
		overlay = overlay_scene.instantiate()
		overlay.name = "AnimationOverlay"
		get_node("/root/WorldMap/CanvasLayer").add_child(overlay)
	
	overlay.show_animation(action_data, actor_data, target_data)
