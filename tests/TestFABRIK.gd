extends Spatial

func camera_desktop_disable():
	$Camera.set_current(false)

func camera_desktop_enable():
	$Camera.set_current(true)

func camera_vr_enable():
	$ARVROrigin/ARVRCamera.set_current(true)

func camera_vr_disable():
	$ARVROrigin/ARVRCamera.set_current(false)

var VR
func setup_vr():
	var setup:bool = false
	# We will be using OpenVR to drive the VR interface, so we need to find and initialize it.
	VR = ARVRServer.find_interface("OpenXR")
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
		setup = true
	return setup

func _ready():
	setup_vr()

var speed : float = 7
var acceleration : float = 20
var gravity : float = 19.6 # 9.8
var jump : float = 9
var velocity : Vector3 = Vector3()
func _input(event):
	#if event is InputEventMouseMotion:
	#	$IK_LookAt_Head.translate(Vector3(event.relative.x*0.01, -event.relative.y*0.01, 0))
		#$IK_LookAt_Head.update_skeleton()
	pass

var frames = 0
var previous_status
func _process(delta):
	var current_status = VR.get_tracking_status()
	#if current_status != previous_status:
	print_debug(current_status)
	#	previous_status = current_status
	if frames < 5:
		ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)
		frames += 1
		pass
		#$ARVROrigin/ARVRCamera.rotate_y(deg2rad(180))



	pass
	#
