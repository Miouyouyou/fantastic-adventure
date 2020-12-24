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

onready var head = $Head
onready var animation_tree = $AnimationTree

export(bool) var vr_mode : bool = false

func camera_desktop_disable():
	$Head/Camera.set_current(false)

func camera_desktop_enable():
	$Head/Camera.set_current(true)

func camera_vr_enable():
	$ARVROrigin/ARVRCamera.set_current(true)

func camera_vr_disable():
	$ARVROrigin/ARVRCamera.set_current(false)

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
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))

	if Input.is_action_just_released("vr_turnleft"):
		$ARVROrigin.rotate_y(deg2rad(45/2.0))
	if Input.is_action_just_released("vr_turnright"):
		$ARVROrigin.rotate_y(deg2rad(-45/2.0))

	if event is InputEventKey and !event.pressed and event.scancode == KEY_ESCAPE:
		menu_mode_active = !menu_mode_active
		if menu_mode_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):

	direction = Vector3()
	#var joystick:Vector2 = Vector2()

	if not is_on_floor():
		fall.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		fall.y = jump

	var move_forward:float = Input.get_action_strength("move_forward")
	var move_backwards:float = Input.get_action_strength("move_backwards")
	print("move_forward : " + str(move_forward))
	print("move_backwards : " + str(move_backwards))
	var joy2:Vector2 = Vector2(
		(Input.get_action_strength("move_right") * 1.0) +
		(Input.get_action_strength("move_left") * -1.0),
		(Input.get_action_strength("move_forward") * 1.0)
		+ (Input.get_action_strength("move_backwards") * -1.0))

	direction += (transform.basis.x) * joy2.x
	direction += (transform.basis.z) * (-joy2.y)
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

	for axis in range(0,15):
		var axis_value:float = Input.get_joy_axis(0,axis)
		if axis_value != 0.0:
			print("Axis " + str(axis) + " : " + str(axis_value))
	for axis in range(0,15):
		var axis_value:float = Input.get_joy_axis(1,axis)
		if axis_value != 0.0:
			print("Axis " + str(axis) + " : " + str(axis_value))
