extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var viewport = $Viewport

# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_inside_tree() || Engine.editor_hint:
		return
		
	# Get main camera
	var root_viewport = get_tree().root
	var main_cam = root_viewport.get_camera()

	# Add a mirror camera
	var mirror_cam = Camera.new()
	viewport.add_child(mirror_cam)
	mirror_cam.keep_aspect = Camera.KEEP_WIDTH
	mirror_cam.current = true
	
	# Adjust viewport size to match the actual mirror size, multiplied by the resolution ratio
	#viewport.size = mesh.size * pixels_per_unit
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
