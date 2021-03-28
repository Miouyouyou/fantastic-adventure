extends Control

const CLIENT_ID = "qx8rY5mPvEwrtjHoUPaqYQflQNXB9L8w8fz1ZWjH"

signal sketchfab_login_success(credentials)
signal sketchfab_error(error_code, error_message)

var thumbnail_object = preload("res://UI/ModelThumbnail.tscn")

const sketchfab_api_host : String = "https://sketchfab.com"

onready var ui_input_search = $ContainerUI/ContainerToolbar/TextSearch

onready var ui_label_model_name = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsName
onready var ui_label_model_author = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsAuthor
onready var ui_label_model_polycount = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsPolycount
onready var ui_label_model_licence = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsLicence
onready var ui_label_model_size = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsSize
onready var ui_label_model_description = $ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/LabelDetailsDescription
onready var ui_model_preview = $"ContainerUI/ContainerSearchResults/ScrollDetails/ContainerDetails/ContainerDetails3DView/Control/Spatial"

var ui_filter_field_licences:OptionButton
onready var ui_filter_field_max_face_count:SpinBox = $"PanelContainer/ScrollContainer/VBoxContainer/SpinBoxMaxFaceCount"
onready var ui_filter_field_pbr:OptionButton = $"PanelContainer/ScrollContainer/VBoxContainer/OptionsPBR"
var ui_filter_field_categories:ItemList
onready var ui_filter_field_sort_by:OptionButton = $"PanelContainer/ScrollContainer/VBoxContainer/OptionsSortBy"
onready var ui_filter_field_max_gltf_filesize:SpinBox = $"PanelContainer/ScrollContainer/VBoxContainer/VBoxContainer/SpinBoxGLTFFilesize"
onready var ui_filters_container = $PanelContainer

onready var ui_results_list:GridContainer = $"ContainerUI/ContainerSearchResults/ScrollContainer/SearchResults"

func ui_max_filesizes_to_query_string() -> String:
	return "gltf:" + str(int(ui_filter_field_max_gltf_filesize.value))

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

func ui_enable_search():
	$ContainerUI/ContainerToolbar/ButtonFilters.disabled = false
	$ContainerUI/ContainerToolbar/TextSearch.editable = true
	$ContainerUI/ContainerToolbar/ButtonSearch.disabled = false

func options_get_selected_text(option_button:OptionButton):
	return option_button.get_item_text(option_button.selected)

func list_get_selected_options(ui_list:ItemList) -> Array:
	var result:Array = []
	for item_index in ui_list.get_selected_items():
		result.append(ui_list.get_item_text(item_index))
	return result


func ui_search():
	var query:Dictionary = {
		"q": ui_input_search.text,
		"license": options_get_selected_text(ui_filter_field_licences),
		"max_face_count": int(ui_filter_field_max_face_count.value),
		"categories": ["characters-creatures", "food-drink"],
		"sort_by": options_get_selected_text(ui_filter_field_sort_by),
		"max_filesizes": ui_max_filesizes_to_query_string(),
		"downloadable": true }
	if ui_filter_field_pbr.selected > 0:
		query["pbr_type"] = options_get_selected_text(ui_filter_field_pbr)

	print_debug(to_json(query))
	sketchfab_list_models(query)

func sketchfab_endpoint_url(endpoint:String) -> String:
	return sketchfab_api_host + endpoint

func sketchfab_list_models(search_criterias:Dictionary):
	var endpoint_url = sketchfab_endpoint_url("/v3/search?type=models")
	var query_params = HTTPClient.new().query_string_from_dict(search_criterias)
	var complete_url = endpoint_url + "&" + query_params
	print_debug(complete_url)
	DownloadManager.get_request(
		"Getting CC-BY models", complete_url, self, "cb_got_models")

func cb_test_login_success(credentials:Dictionary):
	set_meta("access_token", credentials["access_token"])
	ui_enable_search()

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
		emit_signal("sketchfab_error", "login", [response_code])

func http_ok(result:int, response_code:int) -> bool:
	return (result == OK and response_code == 200)

func cb_got_models(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	DownloadManager.remove_ref(download_id)
	if result == OK and response_code == 200:
		# FIXME Check the results before passing them
		var json_data = body.get_string_from_utf8()
		display_model_list(parse_json(json_data))
	else:
		# FIXME : The API actually provide accurate information
		# Relay these info here
		emit_signal("sketchfab_error", "models_list", [response_code])

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
	var endpoint:String = "/oauth2/token/?grant_type=password&client_id=" + CLIENT_ID
	DownloadManager.post_form(
		"Login to Sketchfab",
		sketchfab_endpoint_url(endpoint), login_details,
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

func display_model_list(list:Dictionary):
	print_debug(list)
	# print(list["results"][0].keys())

	for result in list["results"]:
		for thumbnail_data in result["thumbnails"]["images"]:
			# print(thumbnail_data)
			if thumbnail_data["width"] == 256:
				var thumbnail = thumbnail_object.instance()
				ui_results_list.add_child(thumbnail)
				thumbnail.set_thumbnail_with_url(thumbnail_data["url"], result["name"])
				thumbnail.set_click_handler(self, "cb_sketchfab_thumbnail_click", [result])
	return

func _ready():
	connect("sketchfab_login_success", self, "cb_test_login_success")
	connect("sketchfab_error", self, "default_signal_handler_sketchfab_error")
	
	ui_filter_field_licences = $"PanelContainer/ScrollContainer/VBoxContainer/OptionsLicenses"
	ui_filter_field_categories = $"PanelContainer/ScrollContainer/VBoxContainer/ListCategories"

	sketchfab_get_licenses()
	sketchfab_get_categories()
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


func _on_TextSearch_text_entered(new_text):
	ui_search()

func _on_ButtonSearch_pressed():
	ui_search()

const FILTER_FIELD_UNKNOWN = 0
const FILTER_FIELD_LICENCE = 1
const FILTER_FIELD_CATEGORIES = 2

func cb_sketchfab_update_filters(
	result: int,
	response_code: int,
	headers: PoolStringArray,
	body: PoolByteArray,
	download_id: int,
	reason: String,
	filter_field:int) -> void:
	if result == OK && response_code == 200:
		var json_parse:JSONParseResult = JSON.parse(body.get_string_from_utf8())
		if json_parse.error != OK || !(json_parse.result is Dictionary):
			print_debug("Could not parse Sketchfab response !?")
			print_debug("Error : " + str(json_parse.error))
			print_debug("Result type : " + str(typeof(json_parse)))
			print_debug("Expected type : " + str(typeof({})))
			# FIXME Generate a signal and show the error to the user !!
			return
		var json:Dictionary = json_parse.result
		match filter_field:
			FILTER_FIELD_LICENCE:
				ui_refresh_licences_json(json_parse.result)
			FILTER_FIELD_CATEGORIES:
				ui_refresh_categories_json(json_parse.result)
			FILTER_FIELD_UNKNOWN, _:
				pass
	else:
		print_debug(reason + " failed...")
		print_debug("Result : " + str(result))
		print_debug("HTTP code : " + str(response_code))
		# FIXME Generate a signal and show the error to the user !!
		return

func ui_refresh_licences_json(sketchfab_response:Dictionary) -> void:
	var results:Array = sketchfab_response["results"]
	ui_filter_field_licences.clear()
	for result in results:
		ui_filter_field_licences.add_item(result["slug"])

func ui_refresh_categories_json(sketchfab_response:Dictionary) -> void:
	var results:Array = sketchfab_response["results"]
	ui_filter_field_categories.clear()
	for result in results:
		ui_filter_field_categories.add_item(result["slug"])
	print_debug(ui_filter_field_categories.items.size())

func sketchfab_get_licenses() -> void:
	DownloadManager.get_request(
		"Getting licences list",
		sketchfab_endpoint_url("/v3/licenses"),
		self, "cb_sketchfab_update_filters", FILTER_FIELD_LICENCE)

func sketchfab_get_categories() -> void:
	DownloadManager.get_request(
		"Getting categories list",
		sketchfab_endpoint_url("/v3/categories"),
		self, "cb_sketchfab_update_filters", FILTER_FIELD_CATEGORIES)

func _on_ButtonClose_pressed():
	ui_filters_container.visible = false
	pass # Replace with function body.

func _on_ButtonFilters_pressed():
	ui_filters_container.visible = true
	pass # Replace with function body.

func default_signal_handler_sketchfab_error(part:String, args:Array) -> void:
	match part:
		"login":
			print_debug("Something wrong happened during the login phase")
			print_debug("Error : " + str(args[0]))
		"models_list":
			print_debug("Something wrong happened when trying to list models")
			print_debug("Error : " + str(args[0]))
		_:
			print_debug("Unknown error during unknown phase : " + part)
	return


func _on_SearchResults_resized():
	print_debug("RESIZED !!")
	pass # Replace with function body.
