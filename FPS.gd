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

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


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

	if not is_on_floor():
		fall.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		fall.y = jump

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backwards"):
		direction += transform.basis.z

	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	move_and_slide(fall, Vector3.UP)

