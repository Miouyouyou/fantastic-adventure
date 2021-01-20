extends Control

const CLIENT_ID = "qx8rY5mPvEwrtjHoUPaqYQflQNXB9L8w8fz1ZWjH"

signal sketchfab_login_success(credentials)
signal sketchfab_login_error(error_code, error_message)

var thumbnail_object = preload("res://UI/ModelThumbnail.tscn")

func cb_test_login_success(credentials:Dictionary):
	print(credentials)

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
	var first_result : Dictionary = list["results"][0]
	print(first_result.keys())
	print(first_result["uri"])
	print(first_result["uid"])
	print(first_result["name"])
	print(first_result["thumbnails"])

	for result in list["results"]:
		for thumbnail_data in result["thumbnails"]["images"]:
			print(thumbnail_data)
			if thumbnail_data["width"] == 256:
				var thumbnail = thumbnail_object.instance()
				thumbnail.set_thumbnail_with_url(thumbnail_data["url"], result["name"])
				$ContainerUI/ContainerSearchResults/ScrollSearchResults/ListResults.add_child(thumbnail)
	return

func _ready():
	connect("sketchfab_login_success", self, "cb_test_login_success")
	# Until I create the login UI
	#var secrets_filepath = "/tmp/sketchfab.json"

	#if credentials_load_cached("/tmp/sketchfab_token.json"):
	#	print("Success !")
	#else:
	#	var parsed_data = parse_json(FileHelpers.read_text(secrets_filepath))
	#	if parsed_data is Dictionary:
	#		login_sketchfab(parsed_data)
	#	else:
	#		print("Could not open ", secrets_filepath)
	sketchfab_list_models({
		"license": "by",
		"downloadable": true,
		"max_face_count": 20000,
		"categories": ["characters-creatures"]
		})
