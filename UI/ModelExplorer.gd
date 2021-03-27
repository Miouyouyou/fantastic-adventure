extends Control

const CLIENT_ID = "qx8rY5mPvEwrtjHoUPaqYQflQNXB9L8w8fz1ZWjH"

signal sketchfab_login_success(credentials)
signal sketchfab_login_error(error_code, error_message)

var thumbnail_object = preload("res://UI/ModelThumbnail.tscn")

const sketchfab_api_host : String = "https://sketchfab.com"

onready var ui_label_model_name = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsName
onready var ui_label_model_author = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsAuthor
onready var ui_label_model_polycount = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsPolycount
onready var ui_label_model_licence = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsLicence
onready var ui_label_model_size = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsSize
onready var ui_label_model_description = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsDescription
onready var ui_model_preview = $"ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/ContainerDetails3DView/Control/Spatial"

func saved_model_filepath(model_uid:String) -> String:
	return "user://" + model_uid + ".glb"

func downloaded_model_filepath(model_uid:String) -> String:
	return "user://" + model_uid + ".zip"

func ui_show_downloaded_model(model_uid:String) -> bool:
	var model_filepath = saved_model_filepath(model_uid)
	var node = PackedSceneGLTF.new().import_gltf_scene(model_filepath)
	var ok = node is Node
	if ok:
		ui_model_preview.set_model(node)
	return ok

# FIXME Factorize
# reason: String, endpoint_url: String, callback_object, callback:String, extra_arg=null) -> int:
func auth_call_get(reason:String, endpoint:String, callback_obj, callback:String, extra_args=null):
	var url : String = sketchfab_api_host + endpoint
	var headers : PoolStringArray = PoolStringArray()
	headers.append("Authorization: Bearer " + get_meta("access_token"))
	DownloadManager.get_request(
		reason, url, callback_obj, callback, extra_args, headers)

func auth_call_post(reason, endpoint, form_data, callback_obj, callback):
	var url : String = sketchfab_api_host + endpoint
	var headers : PoolStringArray = PoolStringArray()
	headers.append("Authorization: Bearer " + get_meta("access_token"))
	# endpoint_url: String, form_data: Dictionary, callback_object, callback: String, headers: PoolStringArray = PoolStringArray(), extra_arg = null) -> int:
	DownloadManager.post_json(
		reason, endpoint, form_data, callback_obj, callback, headers)

func cb_test_login_success(credentials:Dictionary):
	set_meta("access_token", credentials["access_token"])
	sketchfab_list_models({
		"q": "curry",
		"license": "by",
		"downloadable": true,
		"max_face_count": 50000,
		"categories": ["food-drink"],
		"sort_by": "-likeCount",
		"max_filesizes": "gltf:50000000" })

func cb_login_request(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	DownloadManager.remove_ref(download_id)
	if result == OK and response_code == 200:
		var json_data = body.get_string_from_utf8()
		# Create helpers
		var file_writer : File = File.new()
		if file_writer.open("/tmp/sketchfab_token.json", File.WRITE) == OK:
			file_writer.store_string(json_data)
		file_writer.close()
		emit_signal("sketchfab_login_success", parse_json(json_data))
	else:
		# FIXME : The API actually provide accurate information
		# Relay these info here
		emit_signal("sketchfab_login_error", response_code, "An error occured")

func http_ok(result:int, response_code:int) -> bool:
	return (result == OK and response_code == 200)

func cb_got_models(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	DownloadManager.remove_ref(download_id)
	if result == OK and response_code == 200:
		# FIXME Check the results before passing them
		var json_data = body.get_string_from_utf8()
		FileHelpers.write_text("/tmp/list.json", json_data)
		display_model_list(parse_json(json_data))
	else:
		# FIXME : The API actually provide accurate information
		# Relay these info here
		emit_signal("sketchfab_login_error", response_code, "An error occured")

func cb_sketchfab_thumbnail_click(args):
	var sketchfab_model_info : Dictionary = args[0]
	print(sketchfab_model_info)
	set_select_description_sketchfab(sketchfab_model_info)

func cb_model_downloaded(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, download_filename:String, extra_arg):
	if http_ok(result, response_code):
		var z:ZIPReader = ZIPReader.new()
		z.open(download_filename)
		var zipped_files:PoolStringArray = z.get_files()
		z.close()
		var out_filename:String = "user://" + extra_arg + ".glb"
		for zipped_file in zipped_files:
			if zipped_file.ends_with(".gltf"):
				var handler:GLTFHelpers.ZipFileHandler = GLTFHelpers.ZipFileHandler.new()
				handler.open_zip_file(download_filename)
				if GLTFHelpers.convert_gltf_to_glb(zipped_file, out_filename, handler) != OK:
					print_debug("Could not convert the archive...")
					return
				ui_show_downloaded_model(extra_arg)

func cb_model_download_url_obtained(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg:String):
	if http_ok(result, response_code):
		var info = parse_json(body.get_string_from_utf8())
		if info is Dictionary:
			print(info)
			var model_url:String = info["gltf"]["url"]
			var model_uid:String = extra_arg
			DownloadManager.download_to_file("Download model", model_url, "user://" + model_uid + ".zip", self, "cb_model_downloaded", model_uid)

func set_select_description_sketchfab(sketchfab_model_info:Dictionary):
	ui_label_model_name.text = sketchfab_model_info["name"]
	ui_label_model_author.text = sketchfab_model_info["user"]["displayName"]
	ui_label_model_polycount.text = str(sketchfab_model_info["faceCount"])
	ui_label_model_licence.text = "CC Attribution"
	var gltf_size : float = -1
	if sketchfab_model_info["archives"].has("gltf"):
		gltf_size = sketchfab_model_info["archives"]["gltf"].get("size", -1)
	ui_label_model_size.text = str(gltf_size)
	ui_label_model_description.text = sketchfab_model_info["description"]
	# FIXME This can lead to the previous slow request replacing the next fast one
	# auth_call(get_model_and_display_it)
	var uid:String = sketchfab_model_info["uid"]
	var gltf_zip_filepath:String = downloaded_model_filepath(uid)
	var file_checker:File = File.new()
	if file_checker.file_exists(gltf_zip_filepath):
		var err_ret:int = file_checker.open(gltf_zip_filepath, File.READ)
		if err_ret != OK:
			print_debug("The file exist but cannot be opened.")
			print_debug("Permissions issues ?")
			print_debug("Error code " + str(err_ret))
			return
		var file_size:int = file_checker.get_len()
		file_checker.close()
		# FIXME Check the SHASUM actually
		if file_size == gltf_size:
			if ui_show_downloaded_model(uid):
				return
			else:
				print_debug("Something went wrong when trying to show the model")
				print_debug("Redownloading, just in case...")
		else:
			print_debug("The file sizes differ... Redownloading")
			print_debug("Expected : " + str(gltf_size))
			print_debug("Current  : " + str(file_size))
			print_debug("Filepath : " + gltf_zip_filepath)

	# Note : Let this here. This handle the case where the file hasn't been
	# download correclty, and the case where the file has never been downloaded
	auth_call_get("Download the model", "/v3/models/" + uid + "/download", self, "cb_model_download_url_obtained", uid)

func login_sketchfab(login_details:Dictionary) -> void:
	var host:String = "https://sketchfab.com"
	var endpoint:String = "/oauth2/token/?grant_type=password&client_id=" + CLIENT_ID
	DownloadManager.post_form(
		"Login to Sketchfab",
		host + endpoint, login_details,
		self, "cb_login_request")

# ... Only available during the testing phase
# In most cases, caching credentials is a security red flag
func credentials_ok(credentials:Dictionary) -> bool:
	return (credentials.has("access_token") and credentials.has("refresh_token"))

func credentials_load_cached(cache_filepath:String) -> bool:
	var parsed_data = parse_json(FileHelpers.read_text(cache_filepath))
	var loaded : bool = false
	if parsed_data is Dictionary:
		var credentials:Dictionary = parsed_data
		if credentials_ok(credentials):
			loaded = true
			emit_signal("sketchfab_login_success", credentials)
	return loaded

func sketchfab_list_models(search_criterias:Dictionary):
	var end_point = "/v3/search?type=models"
	var query_params = HTTPClient.new().query_string_from_dict(search_criterias)
	var url = "https://sketchfab.com" + end_point + "&" + query_params
	DownloadManager.get_request(
		"Getting CC-BY models", url, self, "cb_got_models")

func display_model_list(list:Dictionary):
	# print(list["results"][0].keys())

	for result in list["results"]:
		for thumbnail_data in result["thumbnails"]["images"]:
			# print(thumbnail_data)
			if thumbnail_data["width"] == 256:
				var thumbnail = thumbnail_object.instance()
				thumbnail.set_thumbnail_with_url(thumbnail_data["url"], result["name"])
				thumbnail.set_click_handler(self, "cb_sketchfab_thumbnail_click", [result])
				$ContainerUI/ContainerSearchResults/ScrollSearchResults/ListResults.add_child(thumbnail)
	return

func _ready():
	connect("sketchfab_login_success", self, "cb_test_login_success")

	# Until I create the login UI
	if credentials_load_cached("user://sketchfab_token.json"):
		print("Success !")
	else:
		var secrets_filepath = "user://sketchfab.json"
		var parsed_data = parse_json(FileHelpers.read_text(secrets_filepath))
		if parsed_data is Dictionary:
			login_sketchfab(parsed_data)
		else:
			print("Could not open ", secrets_filepath)
