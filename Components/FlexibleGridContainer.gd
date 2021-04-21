extends GridContainer

func _ready():
	var p = preload("res://UI/ModelThumbnail.tscn")
	var i = p.instance()
	add_child(i)

	var imagetex_read:ImageHelpers.StatusAndImageTexture = ImageHelpers.read_image_texture_from_disk("/tmp/test.png")
	if imagetex_read.status == OK:
		print("YAY !")
		i.set_thumbnail(imagetex_read.image)
		i.set_description("Meow Meow")
	else:
		print_debug(imagetex_read.status)
	return
