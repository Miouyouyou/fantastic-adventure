extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var robot = $Robot
onready var robot_anim = $Robot/AnimationPlayer

onready var menu_button:MenuButton = $CanvasLayer/HBoxContainer/AnimationListPopup
var popup:PopupMenu

var imported_anim:AnimationPlayer
# Called when the node enters the scene tree for the first time.

var queued:Array = []
var last_pos:int = 0
var current_pos:int = 0

var gltf_importer = PackedSceneGLTF.new()

func download(url:String, id:String, to_filepath:String):
	var http_req:HTTPRequest = HTTPRequest.new()
	http_req.name = id
	if http_req.connect("request_completed", self, "download_finished") == OK:
		$Downloads.add_child(http_req)
		http_req.set_download_file(to_filepath)
		var ret = http_req.request(url)
		print("Downloading : " + url + " to " + to_filepath + " (" + str(ret) + ")")

func download_finished(_result, response_code, _headers, _body):
	print("Why did I got called ??")

var map_data = {}
func map_valid(json_data):
	# FIXME Put a real checks here
	return true

func map_entity_transform_to_vector(transform):
	return Vector3(float(transform["x"]), float(transform["y"]), float(transform["z"]))

func map_import_entity_glb_downloaded(json_def, filepath, response_code, url):
	print("Download complete for " + url)
	if response_code < 400:
		var importer = PackedSceneGLTF.new()
		var model:Spatial = importer.import(filepath)
		if model == null:
			return
		var components = json_def["components"]
		for component in components:
			if component["name"] == "transform":
				var transforms = component["transform"]
				var position:Vector3 = map_entity_transform_to_vector(transforms["position"])
				var rotation:Vector3 = map_entity_transform_to_vector(transforms["rotation"])
				var scale:Vector3 = map_entity_transform_to_vector(transforms["scale"])
				model.translate_object_local(position)
				model.set_rotate_degrees(rotation)
				model.scale_object_local(scale)
			# TODO Deal with colliders
		add_child(model)

func map_import_entity_glb(id:String, json_def):
	var components = json_def["components"]
	for component in components:
		if component["name"] == "gltf-model":
			download(component["props"]["src"], id, "/tmp/" + id)
			break

func import_map(url):
	var map_contents = {}
	var f = File.new()
	f.open("/home/gamer/tmp/Spoke-Export2.json", File.READ)
	var j:JSONParseResult = JSON.parse(f.get_as_text())
	f.close()
	print(j.get_error())
	print(j.get_error_string())
	print(j.get_error_line())
	if j.get_error() == OK:
		var doc = j.get_result()
		if map_valid(doc):
			var entities = doc["entities"]
			for entity_id in entities:
				var entity = entities[entity_id]
				var entity_name:String = entity["name"]
				if entity_name.ends_with(".glb"):
					map_import_entity_glb(entity_name, entity)
			
	#for entity in j["entities"]:
	#	print(entity)

func import_in_background(args):
	var model_filepath:String = args[0]
	var queue:Array = args[1]
	queue.resize(8)
	print("Processing {model}...".format({"model": model_filepath}))
	var importer = PackedSceneGLTF.new()

	print("Importer ready")
	var nya:Spatial = importer.import_gltf_scene(model_filepath)
	print("Imported ({node})".format({"node": nya}))

	if nya != null:
		queue[current_pos] = nya
		current_pos += 1
		current_pos &= 7 # max 8 objects queued
	print("Finished processing {model}...".format({"model": model_filepath}))

func find_animator_in(model:Spatial):
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	return null

var exported:bool = false

func _process(delta):
	while last_pos != current_pos:
		var current_model:Spatial = queued[last_pos]
		#var current_model_animator = find_animator_in(current_model)
		#for anim_name in current_model_animator.get_animation_list():
		#	popup.add_item(anim_name)
		#	popup.update()
		#	print(anim_name)
		#imported_anim = current_model_animator
		var c:Spatial = queued[last_pos]
		c.translate(Vector3(randf() * 15.0, 0.0, randf() * 15.0))
		$ToExport.add_child(queued[last_pos])
		last_pos += 1
		last_pos &= 7
	#if last_pos == 2 and !exported:
	#	var p = PackedSceneGLTF.new()
	#	exported = (p.export_gltf($ToExport, "/tmp/meow.glb") == OK)
	
	for http_request in $Downloads.get_children():
		if http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			print(http_request.get_download_file() + " : " + str(http_request.get_downloaded_bytes()))
			var model = gltf_importer.import_gltf_scene(http_request.get_download_file())
			if model != null:
				add_child(model)
			$Downloads.remove_child(http_request)

func _ready():
	robot_anim.play("Love")
	popup = menu_button.get_popup()
	popup.hide_on_item_selection = false
	popup.connect("id_pressed", self, "_on_item_pressed")
	popup.set_position(Vector2(150,150))
	popup.show()
	#var processing_thread:Thread = Thread.new()
	#processing_thread.start(self, "import_in_background", ["/tmp/test.glb", queued])
	#processing_thread = Thread.new()
	#processing_thread.start(self, "import_in_background", ["/home/gamer/tmp/model/Fox.glb", queued])
	import_map("")
	pass # Replace with function body.

func _on_item_pressed(ID):
	#var items = popup.items
	#var selected_anim:String = popup.get_item_text(ID)
	#print("Meep")
	#print(ID)
	#print(popup.get_item_text(ID))
	#imported_anim.play(selected_anim)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
