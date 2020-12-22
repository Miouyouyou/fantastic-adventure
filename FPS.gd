extends KinematicBody

var speed = 7
var acceleration = 20
var gravity = 19.6 # 9.8
var jump = 9

var mouse_sensitivity = 0.05

var positions = {}
var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()

onready var head = $Head
onready var animation_tree = $AnimationTree

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.

var menu_mode_active:bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))

	if event is InputEventKey and !event.pressed and event.scancode == KEY_ESCAPE:
		menu_mode_active = !menu_mode_active
		if menu_mode_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):

	direction = Vector3()
	var joystick:Vector2 = Vector2()

	if not is_on_floor():
		fall.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		fall.y = jump

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
	var move:Vector3 = move_and_slide(fall, Vector3.UP)
