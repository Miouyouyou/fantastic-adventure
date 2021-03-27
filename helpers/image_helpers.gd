extends Node

class StatusAndImageTexture:
	var status:int = OK
	var image:ImageTexture
	func _init(new_status:int, new_image:ImageTexture = ImageTexture.new()):
		status = new_status
		image = new_image

const FILE_FORMAT_UNKNOWN = 0
const FILE_FORMAT_PNG     = 1
const FILE_FORMAT_JPEG    = 2
const FILE_FORMAT_BMP     = 3
const FILE_FORMAT_TGA     = 4
const FILE_FORMAT_COUNT   = 5

static func buffer_read_u16(buffer:PoolByteArray) -> int:
	return (
		(buffer[0] & 0xff) << 8 |
		(buffer[1] & 0xff) << 0
	)

static func buffer_read_u32(buffer:PoolByteArray) -> int:
	return (
		(buffer[0] & 0xff) << 24  |
		(buffer[1] & 0xff) << 16  |
		(buffer[2] & 0xff) <<  8 |
		(buffer[3] & 0xff) <<  0
	)

const MAGIC_HEADER_BMP  = 0x424d
const MAGIC_HEADER_JPEG = 0xffd8
const MAGIC_HEADER_PNG  = 0x89504e47

static func guess_format_using_data(filedata:PoolByteArray) -> int:
	var format:int = FILE_FORMAT_UNKNOWN
	var two_bytes:int = buffer_read_u16(filedata)
	var four_bytes:int = buffer_read_u32(filedata)
	match two_bytes:
		MAGIC_HEADER_BMP: # Bitmap 'BM' header
			format = FILE_FORMAT_BMP
		MAGIC_HEADER_JPEG: # JPEG SOI
			format = FILE_FORMAT_JPEG
		_:
			match four_bytes: 
				MAGIC_HEADER_PNG: # .PNG
					format = FILE_FORMAT_PNG
				_:
					format = FILE_FORMAT_UNKNOWN
	print_debug("%x %x -> %d" % [two_bytes, four_bytes, format])
	return format

static func guess_format_using_fileext(filename:String) -> int:
	var ext = filename.get_extension().to_lower()
	var format:int = FILE_FORMAT_UNKNOWN
	match ext:
		"png":
			format = FILE_FORMAT_PNG
		"jpg", "jpeg":
			format = FILE_FORMAT_JPEG
		"bmp":
			format = FILE_FORMAT_BMP
		"tga":
			format = FILE_FORMAT_TGA
		_:
			format = FILE_FORMAT_UNKNOWN
	return format

static func guess_format(filepath:String, filedata:PoolByteArray) -> int:
	var format:int = guess_format_using_data(filedata)
	if format == FILE_FORMAT_UNKNOWN:
		format = guess_format_using_fileext(filepath)
	return format

static func internal_format_to_mimetype(internal_format:int) -> String:
	var mimetype:String
	match internal_format:
		FILE_FORMAT_UNKNOWN:
			mimetype = "application/octet-stream"
		FILE_FORMAT_PNG:
			mimetype = "image/png"
		FILE_FORMAT_JPEG:
			mimetype = "image/jpg"
		FILE_FORMAT_BMP:
			mimetype = "image/bmp"
		FILE_FORMAT_TGA:
			mimetype = "image/tga"
		_:
			mimetype = "application/octet-stream"
	return mimetype

static func guess_mimetype(filename:String, filedata:PoolByteArray) -> String:
	return internal_format_to_mimetype(guess_format(filename, filedata))

static func internal_format_supported(format:int) -> bool:
	return (format >= 1) && (format < FILE_FORMAT_COUNT)

static func image_texture_from_buffer(image_buffer:PoolByteArray, format:int) -> StatusAndImageTexture:
	var image:Image = Image.new()
	var status_code:int = OK
	if not internal_format_supported(format):
		format = FILE_FORMAT_UNKNOWN
	match format:
		FILE_FORMAT_UNKNOWN, _:
			status_code = ERR_INVALID_DATA
		FILE_FORMAT_PNG:
			status_code = image.load_png_from_buffer(image_buffer)
		FILE_FORMAT_JPEG:
			status_code = image.load_jpg_from_buffer(image_buffer)
		FILE_FORMAT_BMP:
			status_code = image.load_bmp_from_buffer(image_buffer)
		FILE_FORMAT_TGA:
			status_code = image.load_tga_from_buffer(image_buffer)

	var image_texture = ImageTexture.new()
	var ret:StatusAndImageTexture = StatusAndImageTexture.new(status_code, image_texture)
	if status_code == OK:
		image_texture.create_from_image(image_texture)

	return ret

static func read_image_texture_from_disk(filepath:String, format:int = -1) -> StatusAndImageTexture:
	var image_buffer:PoolByteArray
	var supported_format:bool = internal_format_supported(format)
	var format_not_provided:bool = (format == -1)
	# If the format is not provided, we still try to guess it first,
	# in order to use the most appropriate function, since the Godot
	# documentation advise against using Image.load when possible.
	#
	# Supported fileformats (load_FORMAT_from_buffer) require you to
	# provide the image buffer content 
	if format_not_provided || supported_format:
		var file_handler:GLTFHelpers.StandardFileHandler = GLTFHelpers.StandardFileHandler.new()
		var file_read:GLTFHelpers.StatusAndData = file_handler.read_file(filepath)
		if file_read.status != OK:
			return StatusAndImageTexture.new(file_read.status)
		image_buffer = file_read.data

	if format_not_provided:
		format = guess_format(filepath, image_buffer)

	var image:Image = Image.new()
	var status_code:int = OK
	print_debug("Using format : " + str(format) + ", AKA : " + internal_format_to_mimetype(format))
	match format:
		FILE_FORMAT_UNKNOWN:
			status_code = image.load(filepath)
		FILE_FORMAT_PNG:
			status_code = image.load_png_from_buffer(image_buffer)
		FILE_FORMAT_JPEG:
			status_code = image.load_jpg_from_buffer(image_buffer)
		FILE_FORMAT_BMP:
			status_code = image.load_bmp_from_buffer(image_buffer)
		FILE_FORMAT_TGA:
			status_code = image.load_tga_from_buffer(image_buffer)
		_:
			status_code = image.load(filepath)

	var image_texture:ImageTexture = ImageTexture.new()
	image_texture.create_from_image(image)

	return StatusAndImageTexture.new(status_code, image_texture)
