extends CanvasLayer

@onready var action_image: TextureRect = %ActionImage
@onready var action_name: Label = %ActionName
@onready var participant_names: Label = %ParticipantNames
@onready var close_btn: Button = %CloseBtn

func display_action(action: Dictionary, p1_name: String, p2_name: String) -> void:
	action_name.text = action.nombre
	participant_names.text = "%s & %s" % [p1_name, p2_name]
	
	if action.has("imagen_url"):
		ImageLoader.load_image(action.imagen_url, func(texture):
			if texture:
				action_image.texture = texture
	)
	
	close_btn.pressed.connect(func(): queue_free(), CONNECT_ONE_SHOT)

func _ready() -> void:
	# Click outside or ESC to close could be added here
	pass
