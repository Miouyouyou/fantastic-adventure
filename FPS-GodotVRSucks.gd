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

# Called when the node enters the scene tree for the first time.
func _ready():
	if not vr_mode:
		setup_desktop()
	else:
		if not setup_vr():
			setup_desktop()

var menu_mode_active:bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseMotion:
		#rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))
		#$LookAtNode.translate(Vector3(event.relative.x*0.01, -event.relative.y*0.01, 0))
#
	if Input.is_action_just_released("vr_turnleft"):
	#	print("Meep")
		rotate_y(deg2rad(45/2.0))
	if Input.is_action_just_released("vr_turnright"):
		rotate_y(deg2rad(-45/2.0))
#
	if event is InputEventKey and !event.pressed and event.scancode == KEY_ESCAPE:
		menu_mode_active = !menu_mode_active
		if menu_mode_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


var frames : int = 0
var arvr_camera_x_distance:float = 0
var arvr_camera_z_distance:float = 0
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
	if frames <= 60:
		print("Wait... Calibrating")
	elif frames == 60:
		var camera_rotation:float = arvr_camera.rotation.y
		rotate_y(camera_rotation)
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)
		#var offset_for_centering_camera_on_eyes:Vector3 = (
		#	$ARVROrigin/BetweenEyes.translation
		#	- $ARVROrigin/ARVRCamera.translation)
		#print($ARVROrigin/BetweenEyes.translation, " - ", $ARVROrigin/ARVRCamera.translation, " = ", offset_for_centering_camera_on_eyes)
		#$ARVROrigin.translate(offset_for_centering_camera_on_eyes)
		#print($ARVROrigin.translation)
		print("Recentering !")
	elif frames > 60 and frames < 63:
		print("Waiting for the camera to recenter correctly")
	elif frames == 64:
		print("Offseting the origin to center the camera between the eyes")
		print(arvr_camera.translation)

		var camera_position:Vector3 = arvr_camera.translation
		var offset_for_centering_camera_on_eyes:Vector3 = (head.translation- camera_position)
		arvr_origin.translate(offset_for_centering_camera_on_eyes)
		var player_position:Vector3 = translation
		
		arvr_camera_x_distance = abs(player_position.x - camera_position.x)
		arvr_camera_z_distance = abs(player_position.z - camera_position.z)
		print("Recentered")
	else:
		# The whole point is to keep the player centered on the camera, and
		# avoid freestyle camera move, where the camera move and detach itself
		# from the character.
		# That said, moving the Player will move everything, including the
		# camera, by the same amount, which would not solve the problem, since
		# we want to pull the camera back to the center.
		# So we need, as a stupid hack, to move the origin using an opposite
		# movement.
		# FIXME : Implement most of this logic using a Collider...
		# Checking for distances every frame is stupid, the physics engine
		# can already do it for you, in a more optimized fashion.
		var player_position:Vector3 = translation
		var camera_position:Vector3 = arvr_camera.translation
		var slide:Vector3 = Vector3()

		# ignore Y position. I don't care if the player is jumping, ATM
		var current_camera_x_distance:float = abs(player_position.x - camera_position.x)
		var current_camera_z_distance:float = abs(player_position.z - camera_position.z)

		if current_camera_x_distance > arvr_camera_x_distance:
			
			var overshoot:float = current_camera_x_distance - arvr_camera_x_distance
			if camera_position.x > player_position.x:
				slide.x = overshoot
			else:
				slide.x = -overshoot
		if current_camera_z_distance > arvr_camera_z_distance:
			print(camera_position)
			var overshoot:float = current_camera_z_distance - arvr_camera_z_distance
			#print(current_camera_z_distance, " > ", arvr_camera_z_distance, " (", overshoot, ")")
			if camera_position.z > player_position.z:
				slide.z = -overshoot
			else:
				slide.z = overshoot
		# Reposition the camera inside the character
		arvr_origin.translate(slide)
		# Move the character so the camera is at the same position
		#move_and_slide(slide, Vector3.UP)
	frames += 1

	#var joystick:Vector2 = Vector2()

	if not is_on_floor():
		fall.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		fall.y = jump

	var move_forward:float = Input.get_action_strength("move_forward")
	var move_backwards:float = Input.get_action_strength("move_backwards")
	#print("move_forward : " + str(move_forward))
	#print("move_backwards : " + str(move_backwards))
	var joy2:Vector2 = Vector2(
		(Input.get_action_strength("move_right") * 1.0) +
		(Input.get_action_strength("move_left") * -1.0),
		(Input.get_action_strength("move_forward") * 1.0)
		+ (Input.get_action_strength("move_backwards") * -1.0))

	var t : Basis = arvr_camera.global_transform.basis # transform.basis
	#print("\nLocal : " + str($ARVROrigin/ARVRCamera.transform.basis)
	#	+ "\nGlobal : " + str($ARVROrigin/ARVRCamera.global_transform.basis))
	#t = t.rotated(t.y, deg2rad(45))

	direction += (t.x) * joy2.x
	direction += (t.z) * -joy2.y


	#if Input.is_action_just_released("vr_turnleft"):
	#	$ARVROrigin.rotate_y(deg2rad(45/2.0))
	#if Input.is_action_just_released("vr_turnright"):
	#	$ARVROrigin.rotate_y(deg2rad(-45/2.0))
	#if Input.is_action_pressed("move_forward"):
	#	direction -= transform.basis.z
	#	joystick.y += 1.0
	#elif Input.is_action_pressed("move_backwards"):
	#	direction += transform.basis.z
	#	joystick.y -= 1.0

	#if Input.is_action_pressed("move_left"):
	#	direction -= transform.basis.x
	#	joystick.x -= 1.0
	#elif Input.is_action_pressed("move_right"):
	#	direction += transform.basis.x
	#	joystick.x += 1.0

	animation_tree.set("parameters/move/blend_position", joy2)
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	var _discarded = move_and_slide(fall, Vector3.UP)

	#for axis in range(0,15):
	#	var axis_value:float = Input.get_joy_axis(0,axis)
	#	if axis_value != 0.0:
	#		print("Axis " + str(axis) + " : " + str(axis_value))
	#for axis in range(0,15):
	#	var axis_value:float = Input.get_joy_axis(1,axis)
	#	if axis_value != 0.0:
	#		print("Axis " + str(axis) + " : " + str(axis_value))
