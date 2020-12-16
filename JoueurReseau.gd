extends Spatial

#var player_data = {"transform": Transform(Basis(), Vector3())}

#func _process(delta):
#	set_transform(player_data["transform"])

#func set_player_data_ptr(player_data_ptr):
#	player_data = player_data_ptr

func set_billboard_name_image(img:Image):
	var generated_texture = ImageTexture.new()
	generated_texture.create_from_image(img, Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_MIPMAPS)
	$BillboardName.texture = generated_texture

func set_billboard_name(name:String):
	var name_generator = preload("res://Components/BillboardTextGenerator.tscn").instance()
	name_generator.get_billboard_texture_from_text(name)
	add_child(name_generator)
	name_generator.set_size(name_generator.get_text_size())
	yield(name_generator.get_tree(),"idle_frame")
	yield(name_generator.get_tree(),"idle_frame")
	var image_data = name_generator.get_texture().get_data()
	image_data.flip_y()
	set_billboard_name_image(image_data)
	remove_child(name_generator)

func _ready():
	set_billboard_name("Pouiposaurus")


