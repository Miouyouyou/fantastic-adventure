extends VBoxContainer

onready var ui_thumbnail:TextureButton = $TextureRect
onready var ui_description:Label = $Label

var click_handler_target = self
var click_handler_name   = "default_click_handler"
var click_handler_args   = null
var thumbnail_set:bool   = false

signal save_thumbnail(image_buffer)

func set_thumbnail_with_url(image_url:String, description:String):
	DownloadManager.get_request("thumbnail", image_url, self, "downloaded_thumbnail")
	set_description(description)

func set_description(description:String) -> void:
	ui_description.text = description

func set_thumbnail(texture:Texture) -> void:
	ui_thumbnail.texture_normal  = texture
	ui_thumbnail.texture_pressed = texture
	ui_thumbnail.texture_hover   = texture
	ui_thumbnail.texture_focused = texture
	thumbnail_set = true
	save_thumbnail_when_possible()

func save_thumbnail_when_possible():
	if thumbnail_set:
		var image_texture:Texture = ui_thumbnail.texture_normal
		emit_signal("save_thumbnail", image_texture.get_data().save_png_to_buffer())

func downloaded_thumbnail(
	result: int,
	response_code: int,
	headers: PoolStringArray,
	body: PoolByteArray,
	download_id: int,
	reason: String,
	extra_arg):

	if result == OK and response_code == 200:
		var image : Image = Image.new()
		if image.load_jpg_from_buffer(body) == OK:
			var image_texture : ImageTexture = ImageTexture.new()
			image_texture.create_from_image(image)
			set_thumbnail(image_texture)

# FIXME Use signals instead...
func set_click_handler(cb_target, cb_name, args = []):
	click_handler_target = cb_target
	click_handler_name = cb_name
	click_handler_args = args

func default_click_handler(args):
	print("Meep ! I'm a default click handler !")

func _on_TextureRect_button_down():
	click_handler_target.call(click_handler_name, click_handler_args)
	pass # Replace with function body.
