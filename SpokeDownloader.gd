extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(String) var url:String = ""
export(String, FILE) var json_filepath:String = ""
export(String, DIR) var map_objects_cache_dir:String = "/tmp"
export(NodePath) var where = "."

# Will be setup in map_instantiate
var actual_root_node
var gltf_importer = PackedSceneGLTF.new()

# TODO Add download handlers... We'll need them very quickly !
# Because, sure, for simple GLTF file you can get from a public
# HTTP server without authentication, HTTPRequest will do.

# However most of Spoke maps use assets from Sketchfab, which
# require to use their API to be able to download the actual
# assets.
# As of today, for GLB objects, only Sketchfab is actually used in
# Spoke maps.
# However, new services may arise after the death of Google Poly and
# we need to be able to reference and use assets from these services,
# if the map maker is using them.
# For that reason, we need multiple download handlers that know
# how to get a GLB file from the references provided in Spoke maps.

# TODO Handle the attributions by appending, to a dictionnary :
# - The URL of each object downloaded
# - Its license
# - Its authors (currently, only one of them will be referenced
#   on most services. Still, use an Array for 'authors')

func map_file_download_path_setup_from_url():
	json_filepath.erase(0, json_filepath.length())
	# TODO Parsing URL like a dumbass
	json_filepath += ("/tmp" + url.get_basename())

func map_file_downloaded():
	# TODO Let's actually check if the file is valid...
	var f:File = File.new()
	return f.file_exists(json_filepath)

var map_req:HTTPRequest
func map_file_download():
	map_req= HTTPRequest.new()
	map_req.set_download_file(json_filepath)
	map_req.connect("request_completed", self, "map_file_download_ended")
	add_child(map_req)
	map_req.request(url)

func map_file_download_ended(result, response_code, _headers, _body):
	# TODO Perform actual checks.
	# Problems may arise EVEN if the response code is OK...
	if response_code < 400:
		map_instantiate(json_filepath)
	else:
		# TODO Signal errors
		push_error("Something went wrong while downloading your map !")
		push_error("result : {result}, response_code : {response_code}\n".format({"result": result, "response_code": response_code}))
	# FIXME Should we clean up here ?
	# That might make debugging harder and we'll free up... 5KB of resources...
	remove_child(map_req)

func map_content_check_and_signal_errors(json_data):
	# TODO Put actual checks here...
	return true

func map_import_entity_glb(id:String, json_def):
	var components = json_def["components"]
	for component in components:
		if component["name"] == "gltf-model":
			var filepath:String = map_objects_cache_dir + "/" + id
			var f = File.new()
			if f.file_exists(filepath):
				map_object_add_to_scene_with_collider_gltf(filepath)
				# Bracing for FBX, USDZ or others file formats
			else:
				map_object_download(component["props"]["src"], id, filepath)
			break

func map_instantiate_elements(json):
	# TODO For the moment, we basically only GLB elements,
	# hoping that we don't screw up
	var entities = json["entities"]
	for entity_id in entities:
		var entity = entities[entity_id]
		var entity_name:String = entity["name"]
		if entity_name.ends_with(".glb"):
			map_import_entity_glb(entity_name, entity)

func map_instantiate(filepath):
	actual_root_node = get_node_or_null(where)
	if actual_root_node == null:
		print_debug("The root node was null... Calling the police right now !")
		# TODO Signal error : Invalid node path provided
		return
	var f:File = File.new()
	f.open(json_filepath, File.READ)
	var j:JSONParseResult = JSON.parse(f.get_as_text())
	f.close()

	print_debug("Starting the instantiation")
	if j.get_error() != OK:
		# TODO Signal error : Invalid JSON (j.get_error_string() + j.get_error_line() + j)
		print_debug("Your JSON sucks !")
		print_debug(j.get_error_string())
		print_debug(j.get_error_line())
		return

	print_debug("Good JSON !")
	var doc = j.get_result()
	if map_content_check_and_signal_errors(doc) == false:
		print_debug("Bad map, no map...")
		return

	print_debug("Instantiating elements")
	map_instantiate_elements(doc)

	pass

func map_object_download(url:String, id:String, to_filepath:String):
	# Use an actual handlers instead of doing that by hand...
	var http_req:HTTPRequest = HTTPRequest.new()
	http_req.name = id
	if http_req.connect("request_completed", self, "map_object_downloaded") == OK:
		$MapObjectsDownload.add_child(http_req)
		http_req.set_download_file(to_filepath)
		var ret = http_req.request(url)
		print("Downloading : " + url + " to " + to_filepath + " (" + str(ret) + ")")

func map_object_downloaded(_result, _response_code, _headers, _body):
	# What's great about this callback, is that I have ZERO information
	# about the request itself.
	# "Something just downloaded ! Aren't you happy !?"
	# So, we're currently dealing with the downloaded elements inside
	# the _process loop (yes, it's fugly)
	# And this is also why we need actual download handlers !
	pass

func map_object_get_mesh(model):
	if model is MeshInstance:
		return model
	else:
		for child in model.get_children():
			if map_object_get_mesh(child) is MeshInstance:
				return child
			else:
				return null

func map_object_add_to_scene_with_collider(model:Spatial):
	var cs:MeshInstance = map_object_get_mesh(model)
	if cs == null:
		return
	cs.create_trimesh_collision()
	actual_root_node.add_child(model)

func map_object_add_to_scene_with_collider_gltf(filepath:String):
	var model = gltf_importer.import_gltf_scene(filepath)
	if model != null:
		map_object_add_to_scene_with_collider(model)

# Called when the node enters the scene tree for the first time.
func _ready():
	if json_filepath.empty() and url.empty():
		push_error("No URL and no JSON Filepath provided... Can't do anything")
		# TODO Send error signal about badly setup object
		return

	# TODO : Is that really what we want though ?
	if json_filepath.empty() and not url.empty():
		map_file_download_path_setup_from_url()

	print_debug("Things are looking good...")

	if not map_file_downloaded():
		print_debug("Downloading map...")
		map_file_download()
		return # We'll instantiate after downloading the map

	# TODO Send signal about map already downloaded, for UI ?
	print_debug("Instantiating the map...")
	map_instantiate(json_filepath)
	pass # Replace with function body.

func _process(delta):
	for http_request in $MapObjectsDownload.get_children():
		if http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			print(http_request.get_download_file() + " : " + str(http_request.get_downloaded_bytes()))
			map_object_add_to_scene_with_collider_gltf(http_request.get_download_file())
			$MapObjectsDownload.remove_child(http_request)
	pass
