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

class StatusAndString:
	var status:int = OK
	var data:String = ""
	func _init(new_status:int, new_data:String = ""):
		status = new_status
		data = new_data

class StatusAndData:
	var status:int = OK
	var data:PoolByteArray = PoolByteArray()
	func _init(new_status:int, new_data:PoolByteArray = PoolByteArray()):
		status = new_status
		data = new_data
	func to_status_and_string() -> StatusAndString:
		return StatusAndString.new(status, data.get_string_from_utf8())

class ZipFileHandler:
	var current_zip_file:ZIPReader = ZIPReader.new()
	var current_file_content:PoolByteArray = PoolByteArray()
	var files_list:PoolStringArray = PoolStringArray()

	func set_zip_file(zip_filepath:String) -> int:
		var ret:int = current_zip_file.open(zip_filepath)
		if ret != OK:
			return ret
		# Only deal with case insensitive paths.
		# Most people tend to use filesystems that ignore them.
		files_list = current_zip_file.get_files()
		for i in range(0, files_list.size()):
			files_list[i] = files_list[i].to_lower()
		return OK

	func _has_file(filepath:String) -> bool:
		var filepath_lower = filepath.to_lower()
		for listed_file in files_list:
			if filepath_lower == listed_file:
				return true
		return false

	func read_file(filepath:String, mode:int) -> StatusAndData:
		# Strangely, the ZipReader won't accept "/file" as a
		# valid path of a file at the root of the zip file.
		# Because... reasons !
		# So... let's remove "/" if it's present at the start
		# of the path.
		if filepath.begins_with("/"):
			filepath.erase(0,1)
		if mode != File.READ:
			StatusAndData.new(ERR_FILE_CANT_WRITE)
		if not _has_file(filepath):
			StatusAndData.new(ERR_FILE_NOT_FOUND)
		var ret:StatusAndData = StatusAndData.new(OK, current_zip_file.read_file(filepath, false))
		print("Read " + filepath)
		print("Size " + str(ret.data.size()))
		return ret

	func read_file_as_string(filepath:String, mode:int) -> StatusAndString:
		return read_file(filepath, mode).to_status_and_string()

class StandardFileHandler:
	func read_file(filepath:String, mode:int) -> StatusAndData:
		var file_opener:File = File.new()
		var ret:int = file_opener.open(filepath, mode)
		if ret != OK:
			return StatusAndData.new(ret)
		var status_data:StatusAndData = StatusAndData.new(
			ret, file_opener.get_buffer(file_opener.get_len()))
		file_opener.close()
		return status_data

	func read_file_as_string(filepath:String, mode:int) -> StatusAndString:
		return read_file(filepath, mode).to_status_and_string()

func _ready():
	var z:ZipFileHandler = ZipFileHandler.new()
	if z.set_zip_file("res://tests/GLTF/NawakChezLesLapins.zip") == OK:
		convert_gltf_to_glb("NawakChezLesLapins/testGLTFExport.gltf", "user://nawak.glb", z)
	else:
		print("WTF !??")

func align_buffer_on_4_bytes(buffer:PoolByteArray):
	var buffer_size:int = buffer.size()
	for i in range(0, buffer_size & 3):
		buffer.append(0)

func convert_gltf_to_glb(gltf_filepath:String, glb_out_filepath:String, in_file_handler = StandardFileHandler.new()):
	var gltf_read:StatusAndString = in_file_handler.read_file_as_string(gltf_filepath, File.READ)
	if gltf_read.status != OK:
		print_debug("Error " + str(gltf_read.status) + " while trying to open " + gltf_filepath)
		return

	var parse_result:JSONParseResult = JSON.parse(gltf_read.data)
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
			var buffer_filepath:String = gltf_dirpath + str(buffer_desc["uri"])
			var buffer_read:StatusAndData = in_file_handler.read_file(buffer_filepath, File.READ)
			if buffer_read.status == OK:
				buffers_desc[buf_i] = {"offset": glb_buffer.size()}
				buf_i += 1
				glb_buffer.append_array(buffer_read.data)
				align_buffer_on_4_bytes(glb_buffer)
			else:
				print_debug("Could not read " + buffer_filepath)
				print_debug("Reason " + str(buffer_read.status))

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
			var image_filepath:String = gltf_dirpath + str(image_desc["uri"])
			var image_read:StatusAndData = in_file_handler.read_file(image_filepath, File.READ)
			if image_read.status == OK:
				var image_file_size:int = image_read.data.size()
				# Let's be optimistic and store the new image bufferView before
				# actually storing the image data into the GLB buffer
				var image_buffer_view = {
					"buffer": 0,
					"byteLength": image_file_size,
					"byteOffset": glb_buffer.size()
				}
				gltf["bufferViews"].append(image_buffer_view)
				glb_buffer.append_array(image_read.data)
				align_buffer_on_4_bytes(glb_buffer)
				image_desc.erase("uri")
				image_desc["bufferView"] = buffer_view_i
				buffer_view_i += 1
			else:
				print_debug("Could not read " + image_filepath)
				print_debug("Reason " + str(image_read.status))

	# Now that everything is converted and stored, generate the GLB buffer
	# description.
	gltf["buffers"].clear()
	gltf["buffers"] = [{ "byteLength": glb_buffer.size() }]
	# Using gltf["buffers"][0] will make GDScript throw a tantrum about
	# Dicitonaries inside Arrays, again...

	# To finish, we'll have to generate the GLB file
	var glb_file:File = File.new()
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



func convert_gltf_to_glb_working(gltf_filepath:String, glb_out_filepath:String, in_file_class = File, out_file_class = File):
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

