extends VBoxContainer

func downloaded_thumbnail(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	if result == OK and response_code == 200:
		var image : Image = Image.new()
		image.load_jpg_from_buffer(body)
		var image_texture : ImageTexture = ImageTexture.new()
		image_texture.create_from_image(image)
		$TextureRect.texture = image_texture

func set_thumbnail_with_url(image_url:String, description:String):
	DownloadManager.get_request("thumbnail", image_url, self, "downloaded_thumbnail")
	$Label.text = description
