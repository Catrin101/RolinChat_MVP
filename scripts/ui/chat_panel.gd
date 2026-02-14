# scripts/ui/chat_panel.gd
extends Control

## ChatPanel - Sistema de chat multijugador
## Muestra mensajes de jugadores y del sistema

# ===== NODOS =====
@onready var chat_log: RichTextLabel = %ChatLog
@onready var message_input: LineEdit = %MessageInput
@onready var send_button: Button = %SendButton
@onready var scroll_container: ScrollContainer = %ScrollContainer

# ===== CONSTANTES =====
const MAX_MESSAGES := 100
const COLOR_SYSTEM := Color(0.8, 0.8, 0.8)
const COLOR_PLAYER := Color(1.0, 1.0, 1.0)
const COLOR_SELF := Color(0.4, 0.8, 1.0)

# ===== ESTADO =====
var message_count := 0
var auto_scroll := true

# ===== INICIALIZACIÓN =====

func _ready() -> void:
	_connect_signals()
	_setup_chat_log()
	
	# Conectar señales de EventBus
	EventBus.message_received.connect(_on_message_received)
	EventBus.system_message.connect(_on_system_message)
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)
	
	# Mensaje de bienvenida
	add_system_message("Chat iniciado. Escribe para comunicarte.")

# ===== CONFIGURACIÓN =====

func _setup_chat_log() -> void:
	chat_log.bbcode_enabled = true
	chat_log.scroll_following = true

# ===== CONEXIÓN DE SEÑALES =====

func _connect_signals() -> void:
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	
	if scroll_container:
		scroll_container.get_v_scroll_bar().changed.connect(_check_auto_scroll)

# ===== ENVÍO DE MENSAJES =====

func _on_send_pressed() -> void:
	_send_message()

func _on_message_submitted(text: String) -> void:
	_send_message()

func _send_message() -> void:
	var text := message_input.text.strip_edges()
	
	if text.is_empty():
		return
	
	# Limpiar input
	message_input.text = ""
	message_input.grab_focus()
	
	# Enviar mensaje por red
	NetworkManager.send_chat_message.rpc_id(1, text)
	
	# Si somos el servidor, también procesamos localmente
	if NetworkManager.is_server:
		var sender_name := GameManager.local_avatar_data.get("nombre", "Host")
		add_player_message(sender_name, text, true)

# ===== RECEPCIÓN DE MENSAJES =====

func _on_message_received(sender_name: String, text: String) -> void:
	var is_self := sender_name == GameManager.local_avatar_data.get("nombre", "")
	add_player_message(sender_name, text, is_self)

func _on_system_message(text: String) -> void:
	add_system_message(text)

func _on_player_connected(peer_id: int, player_name: String) -> void:
	add_system_message(player_name + " se ha unido a la sala")

func _on_player_disconnected(peer_id: int) -> void:
	var player_data := GameManager.get_player_data(peer_id)
	var player_name := player_data.get("nombre", "Jugador")
	add_system_message(player_name + " se ha desconectado")

# ===== ADICIÓN DE MENSAJES =====

## Agrega un mensaje de jugador al chat
func add_player_message(sender_name: String, text: String, is_self: bool = false) -> void:
	var color := COLOR_SELF if is_self else COLOR_PLAYER
	var timestamp := _get_timestamp()
	
	var formatted_message := "[color=#%s][%s] [b]%s:[/b] %s[/color]\n" % [
		color.to_html(false),
		timestamp,
		sender_name,
		text
	]
	
	chat_log.append_text(formatted_message)
	_trim_messages()
	_scroll_to_bottom()

## Agrega un mensaje del sistema al chat
func add_system_message(text: String) -> void:
	var timestamp := _get_timestamp()
	
	var formatted_message := "[color=#%s][%s] [i]• %s[/i][/color]\n" % [
		COLOR_SYSTEM.to_html(false),
		timestamp,
		text
	]
	
	chat_log.append_text(formatted_message)
	_trim_messages()
	_scroll_to_bottom()

# ===== UTILIDADES =====

## Obtiene el timestamp actual en formato HH:MM
func _get_timestamp() -> String:
	var time := Time.get_datetime_dict_from_system()
	return "%02d:%02d" % [time.hour, time.minute]

## Limita el número de mensajes en el log
func _trim_messages() -> void:
	message_count += 1
	
	if message_count > MAX_MESSAGES:
		# Eliminar las primeras líneas del RichTextLabel
		var text := chat_log.get_parsed_text()
		var lines := text.split("\n")
		
		if lines.size() > MAX_MESSAGES:
			var new_text := ""
			for i in range(lines.size() - MAX_MESSAGES, lines.size()):
				new_text += lines[i] + "\n"
			
			chat_log.clear()
			chat_log.append_text(new_text)
			message_count = MAX_MESSAGES

## Hace scroll automático al final
func _scroll_to_bottom() -> void:
	if auto_scroll and scroll_container:
		await get_tree().process_frame
		var v_scroll := scroll_container.get_v_scroll_bar()
		v_scroll.value = v_scroll.max_value

## Detecta si el usuario está haciendo scroll manual
func _check_auto_scroll() -> void:
	if not scroll_container:
		return
	
	var v_scroll := scroll_container.get_v_scroll_bar()
	auto_scroll = v_scroll.value >= v_scroll.max_value - 10

# ===== COMANDOS DE CHAT (FUTURO) =====

## Procesa comandos especiales (ej: /roll, /me)
func _process_command(text: String) -> bool:
	if not text.begins_with("/"):
		return false
	
	var parts := text.split(" ", false, 1)
	var command := parts[0].substr(1).to_lower()
	var args := parts[1] if parts.size() > 1 else ""
	
	match command:
		"help":
			add_system_message("Comandos disponibles: /help, /clear")
			return true
		"clear":
			chat_log.clear()
			message_count = 0
			add_system_message("Chat limpiado")
			return true
		_:
			add_system_message("Comando desconocido: /" + command)
			return true
	
	return false
