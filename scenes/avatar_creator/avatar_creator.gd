extends Control

@onready var name_input: LineEdit = %NameInput
@onready var raza_option: OptionButton = %RazaOption
@onready var sexo_option: OptionButton = %SexoOption
@onready var image_input: LineEdit = %ImageInput
@onready var desc_input: TextEdit = %DescInput
@onready var preview_texture: TextureRect = %PreviewTexture
@onready var load_image_btn: Button = %LoadImageBtn
@onready var save_btn: Button = %SaveBtn
@onready var cancel_btn: Button = %CancelBtn

func _ready() -> void:
	_setup_options()
	_connect_signals()
	
	# Load current avatar data if editing
	var current = AvatarManager.get_active_avatar()
	if current:
		_fill_data(current)

func _setup_options() -> void:
	raza_option.clear()
	for raza in ConfigLoader.get_all_razas():
		raza_option.add_item(raza.nombre)
		raza_option.set_item_metadata(raza_option.get_item_count() - 1, raza.id)
	
	sexo_option.clear()
	for sexo in ConfigLoader.get_all_sexos():
		sexo_option.add_item(sexo.nombre)
		sexo_option.set_item_metadata(sexo_option.get_item_count() - 1, sexo.id)

func _connect_signals() -> void:
	load_image_btn.pressed.connect(_on_load_image_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

func _fill_data(avatar: AvatarData) -> void:
	name_input.text = avatar.nombre
	desc_input.text = avatar.descripcion
	image_input.text = avatar.imagen_url
	
	# Select correct options
	for i in range(raza_option.get_item_count()):
		if raza_option.get_item_metadata(i) == avatar.raza_id:
			raza_option.select(i)
			break
			
	for i in range(sexo_option.get_item_count()):
		if sexo_option.get_item_metadata(i) == avatar.sexo_id:
			sexo_option.select(i)
			break
	
	_on_load_image_pressed()

func _on_load_image_pressed() -> void:
	var url = image_input.text.strip_edges()
	if url == "": return
	
	ImageLoader.load_image(url, func(texture):
		if texture:
			preview_texture.texture = texture
		else:
			# Fallback or clear
			preview_texture.texture = null
	)

func _on_save_pressed() -> void:
	var nombre = name_input.text.strip_edges()
	if nombre == "":
		# Show some error UI notification ideally
		return
	
	var raza_id = raza_option.get_item_metadata(raza_option.selected)
	var sexo_id = sexo_option.get_item_metadata(sexo_option.selected)
	
	var avatar = AvatarData.new(
		"", # ID will be generated if empty
		nombre,
		desc_input.text,
		image_input.text.strip_edges(),
		raza_id,
		sexo_id
	)
	
	AvatarManager.save_profile(avatar)
	AvatarManager.load_profile(nombre)
	
	_on_cancel_pressed()

func _on_cancel_pressed() -> void:
	# For now, just go back to main menu or previous scene
	# get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	pass
