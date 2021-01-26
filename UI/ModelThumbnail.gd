extends VBoxContainer

func downloaded_thumbnail(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	if result == OK and response_code == 200:
		var image : Image = Image.new()
		image.load_jpg_from_buffer(body)
		var image_texture : ImageTexture = ImageTexture.new()
		image_texture.create_from_image(image)
		$TextureRect.texture_normal = image_texture
		$TextureRect.texture_pressed = image_texture
		$TextureRect.texture_hover = image_texture
		$TextureRect.texture_focused = image_texture

func set_thumbnail_with_url(image_url:String, description:String):
	DownloadManager.get_request("thumbnail", image_url, self, "downloaded_thumbnail")
	$Label.text = description

var click_handler_target = self
var click_handler_name   = "default_click_handler"
var click_handler_args   = null

func set_click_handler(cb_target, cb_name, args = []):
	click_handler_target = cb_target
	click_handler_name = cb_name
	click_handler_args = args

func default_click_handler(args):
	print("Meep ! I'm a default click handler !")



func _on_TextureRect_button_down():
	click_handler_target.call(click_handler_name, click_handler_args)
	pass # Replace with function body.
