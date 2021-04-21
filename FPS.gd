extends KinematicBody

var speed : float = 7
var acceleration : float = 20
var gravity : float = 19.6 # 9.8
var jump : float = 9

var mouse_sensitivity : float = 0.05

var positions = {}
var direction : Vector3 = Vector3()
var velocity : Vector3 = Vector3()
var fall : Vector3 = Vector3()

onready var head = $CollisionShape/Sakurada_Fumiriya/Head
onready var head_camera = $CollisionShape/Sakurada_Fumiriya/Head/Camera
onready var arvr_origin = $ARVROrigin
onready var arvr_camera = $ARVROrigin/ARVRCamera
onready var animation_tree = $AnimationTree

var vr_interface:ARVRInterface

onready var ui_menu = $CollisionShape/Sakurada_Fumiriya/Head/Camera/Menu

export(bool) var vr_mode : bool = false

func camera_desktop_disable():
	head_camera.set_current(false)

func camera_desktop_enable():
	head_camera.set_current(true)

func camera_vr_enable():
	arvr_camera.set_current(true)

func camera_vr_disable():
	arvr_camera.set_current(false)

func setup_vr() -> bool:
	var setup:bool = false
	# We will be using OpenVR to drive the VR interface, so we need to find and initialize it.
	var VR = ARVRServer.find_interface("OpenXR")
	if VR and VR.initialize():
		vr_interface = VR
		# Turn the main viewport into a AR/VR viewport,
		# and turn off HDR (which currently does not work)
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		# Let's disable VSync so we are not running at whatever the monitor's VSync is,
		# and let's set the target FPS to 90, which is standard for most VR headsets.
		OS.vsync_enabled = false
		Engine.target_fps = 90
		# Also, the physics FPS in the project settings is also 90 FPS. This makes the physics
		# run at the same frame rate as the display, which makes things look smoother in VR!
		camera_desktop_disable()
		camera_vr_enable()
		vr_mode = true # Myy : Just in case
		setup = true
	return setup

func setup_desktop():
	camera_vr_disable()
	camera_desktop_enable()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	vr_mode = false

var item_prop_spawner = preload("items/prop_spawner.tscn")
# FIXME No. Just no. Only for testing a few minutes.
var prop_spawner

# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug(vr_mode)
	if not vr_mode:
		setup_desktop()
	else:
		if not setup_vr():
			setup_desktop()

onready var background_loader = $Loader

func equip_prop_spawner(spawn_container:Node):
	print_debug("Equipping")
	prop_spawner = item_prop_spawner.instance()
	prop_spawner.spawns_container = spawn_container
	if vr_mode:
		arvr_origin.equip(prop_spawner)
	else:
		head.add_child(prop_spawner)

	var model:ModelsInventory.ModelInfos = ModelsInventory.list_cached_models()[0]
	background_loader.connect("object_loaded", self, "_cb_model_loaded")
	background_loader.connect("object_load_error", self, "_cb_model_load_error")
	background_loader.load_in_background(model.filepath, model)

func _cb_model_loaded(model_reference:ModelsInventory.ModelInfos, model:Spatial):
	var scale_factor:float = model_reference.userprefs["scale"] * 2
	prop_spawner.load_model(model, scale_factor)

func _cb_model_load_error(model_reference:ModelsInventory.ModelInfos) -> void:
	print_debug("Could not load : " + model_reference.filepath)

var menu_mode_active:bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if (not vr_mode) and (event is InputEventMouseMotion) and (not ui_menu.menu_shown()):
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))
		#$LookAtNode.translate(Vector3(event.relative.x*0.01, -event.relative.y*0.01, 0))
#
	if Input.is_action_just_released("vr_turnleft"):
	#	print("Meep")
		rotate_y(deg2rad(45/2.0))
	if Input.is_action_just_released("vr_turnright"):
		rotate_y(deg2rad(-45/2.0))
#
	if (not vr_mode) and (event is InputEventMouseButton) and (not ui_menu.menu_shown()):
		if event.is_pressed():
			if prop_spawner.model_loaded:
				prop_spawner.use()
			else:
				print("Meep ! No model loaded !")

	if event is InputEventKey and !event.pressed:
		match event.scancode:
			KEY_ESCAPE:
				if ui_menu.menu_shown():
					ui_menu.menu_show(false)
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					menu_mode_active = !menu_mode_active
					if menu_mode_active:
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					else:
						Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			KEY_N:
				ui_menu.menu_toggle()
				if ui_menu.menu_shown():
					ui_menu.switch_to_inventory()
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			KEY_P:
				ui_menu.menu_toggle()
				if ui_menu.menu_shown():
					ui_menu.switch_to_sketchfab()
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

var frames : int = 0
func _physics_process(delta):

	direction = Vector3()

	# TODO : Best way !
	# Sample the distance between the Collider and the ARVRCamera.
	# Offset the ARVROrigin by that distance in order to center the
	# ARVRCamera on the Collider (and rotate the ARVROrigin so that
	# the camera faces forward...).
	# THEN, on "sit mode", just ignore any move.
	# On "Standing mode", apply a move_and_slide based on that
	# distance.
	# This should take care of everything and the kitchen sink in
	# terms of VR Move.
	if frames == 60:
		var camera_rotation:float = arvr_camera.rotation.y
		rotate_y(camera_rotation)
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)
		print(arvr_camera.translation)
		print("Recentering !")
	elif frames == 65:
		print("Offseting the origin to center the camera between the eyes")
		print(arvr_camera.global_transform.origin)
		print(head.global_transform.origin)
		

		var camera_position:Vector3 = arvr_camera.global_transform.origin
		var offset_for_centering_camera_on_eyes:Vector3 = (head.global_transform.origin- camera_position)

		offset_for_centering_camera_on_eyes.x = 0
		print(offset_for_centering_camera_on_eyes)
		arvr_origin.translate(offset_for_centering_camera_on_eyes)
		print("Recentered")

	frames += 1

	if not is_on_floor():
		fall.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		fall.y = jump

	var move_forward:float = Input.get_action_strength("move_forward")
	var move_backwards:float = Input.get_action_strength("move_backwards")

	var joy2:Vector2 = Vector2(
		(Input.get_action_strength("move_right") * 1.0) +
		(Input.get_action_strength("move_left") * -1.0),
		(Input.get_action_strength("move_forward") * 1.0)
		+ (Input.get_action_strength("move_backwards") * -1.0))

	var t : Basis = arvr_camera.global_transform.basis # transform.basis

	direction += (t.x) * joy2.x
	direction += (t.z) * -joy2.y

	animation_tree.set("parameters/move/blend_position", joy2)
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	var _discarded = move_and_slide(fall, Vector3.UP)



func _on_Menu_visibility_changed():
	if ui_menu != null and not ui_menu.menu_shown():
		var model = ui_menu.get_selected_model()
		if model != null:
			background_loader.load_in_background(model.filepath, model)
	pass # Replace with function body.
