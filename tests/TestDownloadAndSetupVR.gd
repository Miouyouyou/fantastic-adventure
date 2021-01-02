extends ARVROrigin

export(String, FILE) var construct_conf_filepath:String

func _ready():

	var VR = ARVRServer.find_interface("OpenXR")
	if VR and VR.initialize():
		
		# Turn the main viewport into a AR/VR viewport,
		# and turn off HDR (which currently does not work)
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		# Let's disable VSync so we are not running at whatever the monitor's VSync is,
		# and let's set the target FPS to 90, which is standard for most VR headsets.
		OS.vsync_enabled = false
		Engine.target_fps = 90

	var f = File.new()
	f.open(construct_conf_filepath, File.READ)
	setup_with_json_config(f.get_as_text())

func config_check(config:Dictionary) -> bool:
	# TODO Perform actual checks once the format is well defined.
	return true

func array_to_vector3(arr:Array) -> Vector3:
	return Vector3(arr[0], arr[1], arr[2])

# TODO : Create a generic helper for any class
func node_find_skeleton(that_node:Node):

	if that_node is Skeleton:
		print(that_node)
		print(that_node.get_path())
		return that_node
	else:
		for child in that_node.get_children():
			var skeleton_found = node_find_skeleton(child)
			if not skeleton_found == null:
				return skeleton_found

	return null

func setup_with_json_config(config_json:String) -> bool:
	var r = parse_json(config_json)
	if not r is Dictionary:
		return false
	var config : Dictionary = r
	if not config_check(config):
		# Blow everything up
		return false

	var vr_origin : ARVROrigin = self
	var vr_left_arm : ARVRController = $ManetteGauche
	var vr_right_arm : ARVRController = $ManetteDroite
	var vr_headset : ARVRCamera = $ARVRCamera
	var ik_look_at = preload("res://tests/IKLookAtNode.tscn")
	var model_generator : PackedSceneGLTF = PackedSceneGLTF.new()
	var models : Array = [model_generator.import_gltf_scene("user://Sakurada.glb")]

	var setup_config : Dictionary = config["setup"]
	var vr_origin_config : Dictionary = setup_config["vr_origin"]
	vr_origin.translation = array_to_vector3(vr_origin_config["translation"])
	vr_origin.rotation_degrees = array_to_vector3(vr_origin_config["rotation_degrees"])

	var head_config : Dictionary = setup_config["head"]
	vr_headset.near = head_config["near"]
	vr_headset.far = head_config["far"]

	var targeted_model : Spatial = models[setup_config["model"][0]]
	var head_location = array_to_vector3(head_config["translation"])
	head_location.y = -head_location.y
	head_location.z = -head_location.z
	targeted_model.translate(head_location)
	vr_headset.add_child(targeted_model)

	var ik_config : Dictionary = config["setup"]["ik"]
	for ik_look_at_config in ik_config["look_at"]:
		# Do we really want to deal with multiple skeletons ??
		var target_skeleton_index : int = ik_look_at_config["target_skeleton_from"][0]
		var targeted_model_skeleton : Node = node_find_skeleton(models[target_skeleton_index])
		print(targeted_model_skeleton.get_path())
		var ik_look_at_node = ik_look_at.instance()
		ik_look_at_node.name = ik_look_at_config["name"]
		ik_look_at_node.translation = array_to_vector3(ik_look_at_config["translation"])
		ik_look_at_node.rotation_degrees = array_to_vector3(ik_look_at_config["rotation_degrees"])
		ik_look_at_node.skeleton_to_use = targeted_model_skeleton
		ik_look_at_node.skeleton_path = targeted_model_skeleton.get_path()
		ik_look_at_node.bone_name = ik_look_at_config["bone_name"]
		ik_look_at_node.update_mode = ik_look_at_config["update_mode"]
		ik_look_at_node.look_at_axis = ik_look_at_config["look_at_axis"]
		ik_look_at_node.use_our_rotation_x = ik_look_at_config["use_our_rotation_x"]
		ik_look_at_node.use_our_rotation_y = ik_look_at_config["use_our_rotation_y"]
		ik_look_at_node.use_our_rotation_z = ik_look_at_config["use_our_rotation_z"]
		ik_look_at_node.use_negative_our_rot = ik_look_at_config["use_negative_our_rot"]
		ik_look_at_node.additional_rotation = array_to_vector3(ik_look_at_config["additional_rotation"])
		ik_look_at_node.position_using_additional_bone = ik_look_at_config["position_using_additional_bone"]
		ik_look_at_node.additional_bone_name = ik_look_at_config["additional_bone_name"]
		ik_look_at_node.additional_bone_length = ik_look_at_config["additional_bone_length"]
		match ik_look_at_node.name:
			"VRArmLeft":
				vr_left_arm.add_child(ik_look_at_node)
			"VRArmRight":
				vr_right_arm.add_child(ik_look_at_node)
			"VRHead":
				vr_headset.add_child(ik_look_at_node)
			_:
				print("Node added to the Origin, because I don't know where to put it !")
				vr_origin.add_child(ik_look_at_node)
		ik_look_at_node.update_skeleton()
		ik_look_at_node.skeleton_to_use = targeted_model_skeleton
		ik_look_at_node.update_skeleton()
	return true














#const CONFIG_OK = 0
#const CONFIG_NO_VERSION = 1
#const CONFIG_MAIN_KEYS_MISSING = 2
#const CONFIG_MAIN_KEYS_WRONG_TYPES = 3
#const CONFIG_HAS_NO_ASSETS = 4
#const CONFIG_ASSET_MISSING_MAIN_KEYS = 5
#const CONFIG_ASSET_FORMAT_UNSUPPORTED = 6
#
#func asset_format_is_supported(format:String) -> bool:
#	# Somehow, in the future, we might support FBX and others formats
#	return format == "GLB"
#
#func config_check_model_asset(asset:Dictionary, elements_size:Dictionary) -> int:
#	var has_main_keys : bool = (
#		asset.has("url") and
#		asset.has("format") and
#		asset.has("uploaders") and
#		asset.has("licence")
#	)
#	if not has_main_keys:
#		return CONFIG_ASSET_MISSING_MAIN_KEYS
#
#	if not asset_format_is_supported(asset["format"]):
#		return CONFIG_ASSET_FORMAT_UNSUPPORTED
#
#	return CONFIG_OK
#
#func config_check(config:Dictionary) -> int:
#	var has_version : bool = config.has("version")
#
#	if not has_version:
#		return CONFIG_NO_VERSION
#
#	var has_main_keys : bool = (
#		config.has("images") and
#		config.has("persons") and
#		config.has("licences") and
#		config.has("assets") and
#		config.has("setup")
#	)
#
#	if not has_main_keys:
#		return CONFIG_MAIN_KEYS_MISSING
#
#	var main_keys_types_are_valid : bool = (
#		config["version"] is float and
#		config["images"] is Array and
#		config["persons"] is Array and
#		config["licences"] is Array and
#		config["assets"] is Array and
#		config["setup"] is Dictionary
#	)
#
#	if not main_keys_types_are_valid:
#		return CONFIG_MAIN_KEYS_WRONG_TYPES
#
#	var n_images = config["images"].count()
#	var n_individuals = config["persons"].count()
#	var n_licences = config["licences"].count()
#	var n_assets = config["assets"].count()
#
#	if n_assets == 0:
#		return CONFIG_HAS_NO_ASSETS
#
#
#	return CONFIG_OK
