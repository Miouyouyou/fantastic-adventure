extends Control

const CLIENT_ID = "qx8rY5mPvEwrtjHoUPaqYQflQNXB9L8w8fz1ZWjH"

signal sketchfab_login_success(credentials)
signal sketchfab_login_error(error_code, error_message)

var thumbnail_object = preload("res://UI/ModelThumbnail.tscn")

const sketchfab_api_host : String = "https://sketchfab.com"

# FIXME Factorize
# reason: String, endpoint_url: String, callback_object, callback:String, extra_arg=null) -> int:
func auth_call_get(reason:String, endpoint:String, callback_obj, callback:String):
	var url : String = sketchfab_api_host + endpoint
	var headers : PoolStringArray = PoolStringArray()
	headers.append("Authorization: Bearer " + get_meta("access_token"))
	print(url)
	DownloadManager.get_request(
		reason, url, callback_obj, callback, null, headers)

func auth_call_post(reason, endpoint, form_data, callback_obj, callback):
	var url : String = sketchfab_api_host + endpoint
	var headers : PoolStringArray = PoolStringArray()
	headers.append("Authorization: Bearer " + get_meta("access_token"))
	# endpoint_url: String, form_data: Dictionary, callback_object, callback: String, headers: PoolStringArray = PoolStringArray(), extra_arg = null) -> int:
	DownloadManager.post_json(
		reason, endpoint, form_data, callback_obj, callback, headers)

func cb_test_login_success(credentials:Dictionary):
	print(credentials)
	set_meta("access_token", credentials["access_token"])
	sketchfab_list_models({
		"license": "by",
		"downloadable": true,
		"max_face_count": 20000,
		"categories": ["characters-creatures"],
		"sort_by": "-likeCount",
		"max_filesizes": "gltf:10000000" })

func cb_login_request(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	print(result)
	print(response_code)
	print(body.get_string_from_utf8())
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
		print(json_data)
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
		var scene_importer = PackedSceneGLTF.new()
		var node = scene_importer.import_gltf_scene("/tmp/scene.gltf")
		if node is Node:
			$"ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/ContainerDetails3DView/Control/Spatial".set_model(node)

func cb_model_download_url_obtained(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	print(result)
	print(response_code)
	if http_ok(result, response_code):
		var info = parse_json(body.get_string_from_utf8())
		if info is Dictionary:
			# FIXME Implement download_to_file
			DownloadManager.download_to_file("Download model", info["gltf"]["url"], "/tmp/test_model.zip", self, "cb_model_downloaded")



func set_select_description_sketchfab(sketchfab_model_info:Dictionary):
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsName.text = sketchfab_model_info["name"]
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsAuthor.text = sketchfab_model_info["user"]["displayName"]
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsPolycount.text = str(sketchfab_model_info["faceCount"])
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsLicence.text = "cc-by"
	var size : float = -1
	if sketchfab_model_info["archives"].has("gltf"):
		size = sketchfab_model_info["archives"]["gltf"].get("size", -1)
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsSize.text = str(size)
	$ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsDescription.text = sketchfab_model_info["description"]
	# FIXME This can lead to the previous slow request replacing the next fast one
	# auth_call(get_model_and_display_it)
	auth_call_get("Download the model", "/v3/models/" + sketchfab_model_info["uid"] + "/download", self, "cb_model_download_url_obtained")
	print(sketchfab_model_info.keys())

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
	var cache_content = parse_json(FileHelpers.read_text("/tmp/list.json"))
	if cache_content != null:
		display_model_list(cache_content)
		return
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
	if credentials_load_cached("/tmp/sketchfab_token.json"):
		print("Success !")
	else:
		var secrets_filepath = "/tmp/sketchfab.json"
		var parsed_data = parse_json(FileHelpers.read_text(secrets_filepath))
		if parsed_data is Dictionary:
			login_sketchfab(parsed_data)
		else:
			print("Could not open ", secrets_filepath)
