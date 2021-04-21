extends Node

# FIXME Alright, the whole filesystem bullshit is not working.
# Most of the code consist in checking if file exists, can be opened,
# etc...
# All this code would not exist if a database were to be used.
# Database enforce the data structures, and schema migration is not
# THAT hard nowadays so... yeah. Database are CLEARLY needed here !
# Note that it's still entirely possible to store JSON in database
# for flexiblity purposes.

class ModelInfos:

	var thumbnail_filepath:String
	var filepath:String
	var filesize:int
	var metadata:Dictionary
	var userprefs_filepath:String
	var userprefs:Dictionary
	var aabb:AABB

	func _init(
		new_filepath:String = "",
		new_thumbnail_filepath:String = "",
		new_metadata = {},
		new_userprefs_filepath:String = ""):

		filepath = new_filepath
		metadata = new_metadata
		thumbnail_filepath = new_thumbnail_filepath
		userprefs_filepath = new_userprefs_filepath

		var metadata_pos:Array = metadata["aabb"]["position"]
		var metadata_size:Array = metadata["aabb"]["size"]
		var position:Vector3 = Vector3(metadata_pos[0], metadata_pos[1], metadata_pos[2])
		var size:Vector3 = Vector3(metadata_size[0], metadata_size[1], metadata_size[2])
		print_debug(position, size)
		aabb = AABB(position, size)

		# Preload defaults, just in case something goes wrong
		userprefs = _default_userprefs()
		print_debug("Loading userprefs : " + str(_load_userprefs(userprefs_filepath)))
		var filesize:int = 0
		var f:File = File.new()
		if f.open(new_filepath, File.READ) == OK:
			filesize = f.get_len()
			f.close()

	func _load_userprefs(filepath:String) -> int:
		var file_checker:File = File.new()
		var ret:int = OK
		if not file_checker.file_exists(filepath):
			ret = _save_prefs(_default_userprefs())
			if ret != OK:
				return ret

		ret = file_checker.open(filepath, File.READ)
		if ret != OK:
			return ret

		var userprefs_content:String = file_checker.get_as_text()
		file_checker.close()

		var loaded_prefs = parse_json(userprefs_content)
		if not loaded_prefs is Dictionary:
			print_debug("Not a dictionary : " + str(typeof(loaded_prefs)))
			return ERR_FILE_CORRUPT

		if not _userprefs_check(loaded_prefs):
			print_debug("Checks failed :C")
			return ERR_FILE_CORRUPT

		userprefs = loaded_prefs
		return OK

	func _userprefs_check(dic:Dictionary):
		var checked_keys = ["scale"]
		var dic_keys:Array = dic.keys()
		for key in checked_keys:
			if not key in dic_keys:
				return false
		return true

	func _default_userprefs() -> Dictionary:
		var default_prefs:Dictionary = {"scale": 1.0}

		# FIXME If not, this should be a critical error actually
		if metadata.has("aabb"):
			default_prefs["scale"] = compute_good_humanoid_scale()
		return default_prefs

	func dump():
		print_debug("Model thumbnail : " + thumbnail_filepath)
		print_debug("Model filepath  : " + filepath)
		print_debug("Model filesize  : " + str(filesize))
		print_debug("Model metadata  : " + str(metadata))

	# "The Good Humanoid Scale" TM
	# Jokes aside, this just compute the best scale to have
	# a standard scaled humanoid character
	# A good bunch of models are scaled with some bad FBX to GLB
	# converter, which lead to GIGANTIC sizes for no reasons most of
	# the time.
	func compute_good_humanoid_scale() -> float:
		# We'll fit it into a cube at the moment
		var size_max:float = 2 # meters
		var scale:float = 1
		var size:Vector3 = aabb.size
		# ... Ugh, just give me the value ...
		var max_axis_i:int = size.max_axis()
		var model_longest_dimension:float = size[max_axis_i]
		print_debug("Size : " + str(size))
		print_debug("Max Axis : " + str(model_longest_dimension))
		if model_longest_dimension > size_max:
			scale = size_max / model_longest_dimension
		return scale

	func _save_prefs(dic:Dictionary) -> int:
		return FileHelpers.write_text(userprefs_filepath, to_json(dic))
	func save_prefs() -> int:
		return _save_prefs(userprefs)

export(String, FILE) var cached_models_dir:String = "user://cache/models"

const metadata_filename:String = "metadata.json"
const sha256sum_filename:String = "SHA256SUM"
const model_filename:String = "model.glb"
const thumbnail_filename:String = "thumbnail"
const userprefs_filename:String = "userprefs.json"
const shasum_size:int = 64 # bytes

const max_filesize_thumbnail:int = 2*1024*1024 # 2 Megabytes

func filepath_metadata(model_dirpath:String) -> String:
	return model_dirpath + "/" + metadata_filename

func filepath_thumbnail(model_dirpath:String) -> String:
	return model_dirpath + "/" + thumbnail_filename

func filepath_shasum(model_dirpath:String) -> String:
	return model_dirpath + "/" + sha256sum_filename

func filepath_model(model_dirpath:String) -> String:
	return model_dirpath + "/" + model_filename

func dirpath_cached_model(cached_dirname:String) -> String:
	return cached_models_dir + "/" + cached_dirname

func filepath_userprefs(cached_dirname:String) -> String:
	return cached_dirname + "/" + userprefs_filename

func _ready():
	var dir:Directory = Directory.new()
	if not dir.dir_exists(cached_models_dir):
		if dir.make_dir_recursive(cached_models_dir) != OK:
			# FIXME Generate an error message telling
			# the user about this serious issue.
			print("Fatal issue : Cannot CREATE the cache directory at : ")
			print(cached_models_dir)
			# FIXME Factorize
			OS.new().exit_code(1)
	else:
		if dir.open(cached_models_dir) != OK:
			print("Fatal issue : Cannot OPEN the cache directory at : ")
			print(cached_models_dir)
			# FIXME Factorize
			OS.new().exit_code(1)

func _dir_has_all_the_files(dir:Directory) -> bool:
	var ret:bool = false
	for filename in [model_filename, sha256sum_filename, metadata_filename]:
		ret = dir.file_exists(filename)
		if ret == false:
			break
	return ret

func _model_metadata_are_correct(metadata:Dictionary) -> bool:
	var ret:bool = true
	for expected_field in ["uri", "name", "provider", "provider_metadata"]:
		var field_present:bool = metadata.has(expected_field)
		if not field_present:
			print(expected_field + " is missing")
	if ret == false:
		print("Missing fields in the metadata")
		return ret

	# TODO Add metadata check for specific providers ?

	return ret

func _model_all_the_files_are_correct(dirpath:String) -> bool:
	# FIXME Check for filesizes. Fail if filesizes are overly big
	var ret:bool = true
	var err:int = OK
	var f:File = File.new()
	var metadata_filepath:String = filepath_metadata(dirpath)
	err = f.open(metadata_filepath, File.READ)
	ret = (err == OK)
	if ret == false:
		print("Could not open the metadata located at : ")
		print(dirpath)
		print("Error " + str(err))
		return ret

	var json_read:JSONParseResult = JSON.parse(f.get_as_text())
	f.close()

	ret = (json_read.error == OK)
	if ret == false:
		print("Could not parse " + metadata_filepath)
		print("Error : " + str(json_read.error))
		print("Line : " + str(json_read.error_line))
		print("Message : " + json_read.error_string)
		return ret

	var temp_result = json_read.result
	ret = (temp_result is Dictionary)
	if ret == false:
		print("The metadata should define an Object. Filepath : ")
		print(metadata_filepath)
		print("Got a " + temp_result.get_class() + "instead")
		return ret

	var metadata:Dictionary = json_read.result
	ret = (_model_metadata_are_correct(metadata))
	if ret == false:
		print("Something is wrong with the metadata at : ")
		print(metadata_filepath)
		return ret

	var sha256sum_filepath:String = filepath_shasum(dirpath)
	var model_filepath:String = filepath_model(dirpath)
	err = f.open(sha256sum_filepath, File.READ)
	ret = (err == OK)
	if ret == false:
		print("Could not open the " + sha256sum_filename + " file at : ")
		print(sha256sum_filepath)
		print("Error code : " + str(err))
		return ret

	var glb_sha256sum_expected:String = f.get_buffer(shasum_size).get_string_from_utf8()
	f.close()
	var glb_sha256sum_actual:String = f.get_sha256(model_filepath)

	ret = (glb_sha256sum_actual == glb_sha256sum_expected)
	if ret == false:
		print("Checking the SHA256SUM of the model failed.")
		print("Expected : " + glb_sha256sum_expected)
		print("Actual   : " + glb_sha256sum_actual)
		print("SHASUM file :" + sha256sum_filepath)
		print("Model file  :" + model_filepath)
		return ret

	# TODO Check if the thumbnail is in the right format
	# TODO Check if the model is actually a GLB file

	return ret

func _model_generate_from(dirpath:String) -> ModelInfos:
	var metadata:Dictionary = parse_json(
		FileHelpers.read_text(filepath_metadata(dirpath))
	)
	return ModelInfos.new(
		filepath_model(dirpath),
		filepath_thumbnail(dirpath),
		metadata,
		filepath_userprefs(dirpath))

func _dir_name_looks_correct(dirname:String) -> bool:
	return (not dirname in [".", ".."])

func list_cached_models() -> Array:
	var dir:Directory = Directory.new()
	if dir.open(cached_models_dir) != OK:
		print("Fatal issue : Cannot OPEN the cache directory at : ")
		print(cached_models_dir)
		print("We could do it before, so something is clearly wrong with your system")
		# FIXME Factorize
		OS.new().exit_code(1)
	var arr:Array = Array()
	if dir.list_dir_begin() != OK:
		print("??? Cannot list the content located at : ")
		print(cached_models_dir)
		# FIXME Factorize
		OS.new().exit_code(1)
	var current_direntry:String = dir.get_next()
	var current_dirpath:String
	while current_direntry != "":
		if dir.current_is_dir() and _dir_name_looks_correct(current_direntry):
			current_dirpath = dir.get_current_dir() + "/" + current_direntry
			if _model_all_the_files_are_correct(current_dirpath):
				arr.append(_model_generate_from(current_dirpath))
		current_direntry = dir.get_next()
	return arr

func _cached_model_ensure_dir_exist(dirname:String) -> int:
	var ret_code = OK
	var dir_manager:Directory = Directory.new()
	var model_dirpath:String = cached_models_dir + "/" + dirname

	if dir_manager.dir_exists(model_dirpath):
		ret_code = dir_manager.open(model_dirpath)
		if ret_code != OK:
			print_debug("The following directory exist but cannot be opened :")
			print_debug(model_dirpath)
	else:
		ret_code = dir_manager.make_dir_recursive(model_dirpath)
		if ret_code != OK:
			print_debug("Could not create " + model_dirpath)
			print_debug("Error code : " + str(ret_code))

	return ret_code

func cache_model_thumbnail_buffer(
	provider:String,
	provider_id:String,
	image_buffer:PoolByteArray) -> int:

	var cached_dirpath:String = _cached_dirpath_for(provider, provider_id)
	if cached_dirpath == "":
		return ERR_CANT_OPEN

	var thumbnail_filesize:int = image_buffer.size()
	if thumbnail_filesize > max_filesize_thumbnail:
		var filesize_readable:String = FileHelpers.filesize_for_humans(thumbnail_filesize)
		var max_filesize_readable:String = FileHelpers.filesize_for_humans(max_filesize_thumbnail)
		print_debug("The thumbnail filesize exceeds the limits :")
		print_debug(
			"Current filesize   : " + filesize_readable +
			"(" + str(thumbnail_filesize) + ")")
		print_debug(
			"Maximum authorized : " + max_filesize_readable +
			"(" + str(max_filesize_thumbnail) + ")")
		return ERR_UNAUTHORIZED

	var thumbnail_filepath:String = filepath_thumbnail(cached_dirpath)
	var err:int = OK
	err = FileHelpers.write_buffer(thumbnail_filepath, image_buffer)
	if err != OK:
		print_debug("Could not write the thumbnail :")
		print_debug(thumbnail_filepath)
		print_debug("Error cdoe : " + str(err))
		return err

	var thumbnail_checksum_filepath = thumbnail_filepath + ".sha256"
	err = FileHelpers.write_sha256sum_of(
		thumbnail_filepath, thumbnail_checksum_filepath)
	if err != OK:
		print_debug("Could not write the SHA256SUM of the thumbnail :")
		print_debug(thumbnail_checksum_filepath)
		print_debug("Error code : " + str(err))
		return err
	return OK

func _cached_dirname_for(
	provider:String,
	provider_data) -> String:

	match provider:
		"sketchfab":
			var model_uid:String = provider_data
			return provider + "-" + model_uid
		_:
			print_debug("Unknown provider : " + provider)
			return ""

func _cached_dirpath_for(
	provider: String,
	provider_data) -> String:

	var dirname:String = _cached_dirname_for(provider, provider_data)
	if dirname != "" and _cached_model_ensure_dir_exist(dirname) == OK:
		 return dirpath_cached_model(dirname)
	else:
		return ""

func cache_model(
	provider:String,
	provider_id:String,
	provider_metadata:Dictionary,
	model_name:String,
	model_filepath:String,
	model_uri:String,
	model_licence:String,
	model_aabb:AABB) -> bool:

	var ret:bool = false
	var err:int = 0
	var cached_dirname:String = _cached_dirname_for(provider, provider_id)

	if cached_dirname == "":
		return false

	var sha256sum:String = FileHelpers.sha256(model_filepath)
	if sha256sum.length() != shasum_size:
		print_debug("Invalid SHA256SUM for " + model_filepath)
		print_debug("SHA256SUM : " + sha256sum)
		return false

	var model_filesize:int = FileHelpers.get_size(model_filepath)
	if model_filesize <= 0:
		print_debug("Invalid model filesize :")
		print_debug(str(model_filesize))
		return false

	err = _cached_model_ensure_dir_exist(cached_dirname)
	if err != OK:
		return false

	var model_dir:String = dirpath_cached_model(cached_dirname)

	var sha256sum_filepath:String = filepath_shasum(model_dir)
	err = FileHelpers.write_text(sha256sum_filepath, sha256sum)
	if err != OK:
		print_debug("Could not write the SHA256SUM file at :")
		print_debug(sha256sum_filepath)
		print_debug("Error code : " + str(err))
		return false

	var model_abs_aabb:AABB = model_aabb.abs()
	var model_abs_position:Vector3 = model_abs_aabb.position
	var model_abs_size:Vector3 = model_abs_aabb.size
	var metadata:Dictionary = {
		"provider": provider,
		"uri": model_uri,
		"provider_metadata": provider_metadata,
		"name": model_name,
		"aabb": {
			"position": [
				model_abs_position.x,
				model_abs_position.y,
				model_abs_position.z
			],
			"size": [
				model_abs_size.x,
				model_abs_size.y,
				model_abs_size.z
			]
		},
		"license": model_licence
	}
	var metadata_filepath:String = filepath_metadata(model_dir)
	err = FileHelpers.write_text(metadata_filepath, to_json(metadata))

	if err != OK:
		print_debug("Could not write the metadata at :")
		print_debug(metadata_filepath)
		print_debug("Error code : " + str(err))
		return false

	var d:Directory = Directory.new()
	var cached_model_filepath:String = filepath_model(model_dir)
	err = d.copy(model_filepath, cached_model_filepath)
	if err != OK:
		print_debug("Could not copy the model")
		print_debug("From : " + model_filepath)
		print_debug("To   : " + cached_model_filepath)
		return false

	return true

