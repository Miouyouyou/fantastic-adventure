extends Node

# Input File interface :
# open(filepath:String, open_mode:int) -> Error
# close() -> void
# get_buffer(buffer_size:int) -> PoolByteArray
# get_as_text() -> String
# get_len() -> int

# Output File interface :
# open(filepath:String, open_mode:int) -> Error
# close() -> void
# store_32(int_value:int) -> void
# store_buffer(buffer:PoolByteArray) -> void
# seek(to_byte:int) -> void
# get_len() -> int

class ZipFileHandler:
	var current_file

	func set_zip_fs(zip_filepath:String) -> int:
		
		return OK

	func new() -> ZipFileHandler:
		return self

	func open(filepath:String, mode:int) -> int:
		return OK
	func close() -> void:
		return

	func get_buffer(buffer_size:int) -> PoolByteArray:
		var arr = PoolByteArray()
		return arr
	func get_as_text() -> String:
		return ""

	func get_len() -> int:
		return 0

func _ready():
	convert_gltf_to_glb("res://tests/GLTF/testGLTFExport.gltf", "user://new_file.glb")

func align_buffer_on_4_bytes(buffer:PoolByteArray):
	var buffer_size:int = buffer.size()
	for i in range(0, buffer_size & 3):
		buffer.append(0)

func convert_gltf_to_glb(gltf_filepath:String, glb_out_filepath:String, in_file_class = File, out_file_class = File):
	var f = in_file_class.new()
	var err_ret = f.open(gltf_filepath, File.READ)
	if err_ret != OK:
		print_debug("Error " + err_ret + " while trying to open " + gltf_filepath)
		return

	var data:String = f.get_as_text()
	var parse_result:JSONParseResult = JSON.parse(data)
	if parse_result.error != OK:
		print_debug("Could not parse the GLTF file.")
		print_debug("Error :")
		print_debug(parse_result.error_string)
		print_debug("At line : " + str(parse_result.error_line))
		return

	if not parse_result.result is Dictionary:
		print_debug("... ? Expected a JSON Dictionary as the GLTF file.")
		print_debug("Got a " + str(typeof(parse_result.result)) + " instead.")
		return

	var gltf:Dictionary = parse_result.result
	var gltf_dirpath:String = gltf_filepath.get_base_dir() + "/"

	var glb_buffer:PoolByteArray = PoolByteArray()
	# Ah... Godot and its weird limitations...
	# If you create an array [] and then append a Dictionary,
	# GDSCript will throw a tantrum about you trying to
	# add a Dictionary inside an Array... Because... ???
	# If you add the Dictionary during the initialization,
	# GDScript is suddenly happy, and will let you append
	# Dictionaries to the array.
	# Ugh...
	var buffers_desc = [{"offset": 0}]
	var buf_i = 0

	# First we pack currently listed buffers into the GLB buffer, and update
	# any bufferView referencing them by linking them back to buffer 0 (the new
	# GLB buffer) and reoffseting them properly within the GLB buffer.
	for buffer_desc in gltf["buffers"]:
		if buffer_desc.has("uri"):
			var buffer_file = in_file_class.new()
			var buffer_filepath:String = gltf_dirpath + str(buffer_desc["uri"])
			if buffer_file.open(buffer_filepath, File.READ) == OK:
				buffers_desc[buf_i] = {"offset": glb_buffer.size()}
				buf_i += 1
				glb_buffer.append_array(
					buffer_file.get_buffer(buffer_file.get_len()))
				align_buffer_on_4_bytes(glb_buffer)
				buffer_file.close()

	for bufferview_desc in gltf["bufferViews"]:
		var previous_buf_i = bufferview_desc["buffer"]
		var previous_offset = bufferview_desc["byteOffset"]
		var new_offset = buffers_desc[previous_buf_i]["offset"] + previous_offset
		# All bufferViews now reference the GLB buffer
		bufferview_desc["buffer"] = 0
		# With the correct offset, of course
		bufferview_desc["offset"] = new_offset

	# Now we add the images into the main buffer, create new bufferViews to
	# reference them and link the images references to these bufferViews
	var buffer_view_i = gltf["bufferViews"].size()
	for image_desc in gltf["images"]:
		# We'll see about dealing with inlined images afterwards.
		# I expect such 'tricks' to be rare, since most exporters won't bother
		if image_desc.has("uri"):
			var image_file = in_file_class.new()
			var image_filepath:String = gltf_dirpath + str(image_desc["uri"])
			if image_file.open(image_filepath, File.READ) == OK:
				var image_file_size:int = image_file.get_len()
				# Let's be optimistic and store the new image bufferView before
				# actually storing the image data into the GLB buffer
				var image_buffer_view = {
					"buffer": 0,
					"byteLength": image_file_size,
					"byteOffset": glb_buffer.size()
				}
				gltf["bufferViews"].append(image_buffer_view)
				glb_buffer.append_array(image_file.get_buffer(image_file_size))
				align_buffer_on_4_bytes(glb_buffer)
				image_desc.erase("uri")
				image_desc["bufferView"] = buffer_view_i
				buffer_view_i += 1
				image_file.close()

	# Now that everything is converted and stored, generate the GLB buffer
	# description.
	gltf["buffers"].clear()
	gltf["buffers"] = [{ "byteLength": glb_buffer.size() }]
	# Using gltf["buffers"][0] will make GDScript throw a tantrum about
	# Dicitonaries inside Arrays, again...

	# To finish, we'll have to generate the GLB file
	var glb_file = out_file_class.new()
	glb_file.open(glb_out_filepath, File.WRITE_READ)

	# GLB 12-byte Header
	var glb_magic:int = 0x46546C67
	var glb_version:int = 2
	glb_file.store_32(glb_magic)
	glb_file.store_32(glb_version)
	# We'll write the actual size after writing everything,
	# in order to be sure to get the actual size, instead
	# of playing guessing games
	glb_file.store_32(0) # Fake size

	# GLB Chunk 0 (JSON)
	var glb_json_data:PoolByteArray = to_json(gltf).to_utf8()
	var glb_json_chunk_magic:int = 0x4E4F534A
	align_buffer_on_4_bytes(glb_json_data)
	glb_file.store_32(glb_json_data.size())
	glb_file.store_32(glb_json_chunk_magic)
	glb_file.store_buffer(glb_json_data)

	# GLB Chunk 1 (BIN)
	var glb_bin_chunk_magic:int = 0x004E4942
	glb_file.store_32(glb_buffer.size())
	glb_file.store_32(glb_bin_chunk_magic)
	glb_file.store_buffer(glb_buffer)

	# Write the actual size of the GLB file, in its header
	var glb_file_actual_size:int = glb_file.get_len()
	print(glb_file_actual_size)
	glb_file.seek(8) # magic (uint32) -> 4 bytes + version (uint32) -> 4 bytes
	glb_file.store_32(glb_file_actual_size)
	glb_file.close()

