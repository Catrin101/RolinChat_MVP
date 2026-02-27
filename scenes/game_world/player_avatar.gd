extends CharacterBody2D

## Representation of a player in the game world.

const SPEED = 200.0

@onready var sprite: Sprite2D = %Sprite
@onready var nametag: Label = %NameTag
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var avatar_data: AvatarData = null

func _ready() -> void:
	# Set authority based on the node name (set during spawn)
	var peer_id = name.to_int()
	set_multiplayer_authority(peer_id)
	
	if is_multiplayer_authority():
		# Sync local data once
		_update_from_manager.rpc()
	else:
		# Remote clients will receive data via RPC or sync property if added
		pass

@rpc("any_peer", "call_local", "reliable")
func _update_from_manager() -> void:
	var id = multiplayer.get_unique_id() if is_multiplayer_authority() else name.to_int()
	var info = NetworkManager.players.get(id, {})
	
	if info.has("name"):
		nametag.text = info.name
	
	if info.has("avatar"):
		var data = AvatarData.from_dict(info.avatar)
		_setup_avatar(data)

func _setup_avatar(data: AvatarData) -> void:
	avatar_data = data
	if data.imagen_url != "":
		ImageLoader.load_image(data.imagen_url, func(texture):
			if texture:
				sprite.texture = texture
	)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
