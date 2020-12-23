extends ARVRController

func _physics_process(delta):
	for axis in range(0,15):
		var joystick_axis_value : float = get_joystick_axis(axis)
		if joystick_axis_value != 0.0:
			print(axis)

