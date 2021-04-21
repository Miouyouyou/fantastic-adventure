extends Spatial

onready var laser_mesh = $MeshInstance
onready var hit_ball = $MeshInstance2
onready var raycast = $RayCast

var model_loaded:bool = false
var loaded_model:Spatial = Spatial.new()
# FIXME Can't think about a better solution now
# Still, this just keep references of the entire
# scene, which could lead to major memory leaks
var spawns_container:Node = Node.new()

# FIXME : ???
var current_scale:Vector3 = Vector3(1.0,1.0,1.0)

func draw_ray(length:Vector3) -> void:
	var pos:Vector3 = transform.origin + length/2
	laser_mesh.transform.origin = pos
	laser_mesh.scale.z = length.z/2
	pass

func load_model(model:Spatial, scale_factor:float) -> void:
	loaded_model = model
	model_loaded = true
	current_scale = Vector3(scale_factor, scale_factor, scale_factor)

func unload_model() -> void:
	model_loaded = false
	loaded_model = Spatial.new()

func use() -> void:
	var hit = raycast.get_collider()
	if hit != null:
		var point:Vector3 = raycast.get_collision_point()
		print(point)
		hit_ball.global_transform.origin = point
		if model_loaded:
			var spawn:Spatial = loaded_model.duplicate()
			spawns_container.add_child(spawn)
			spawn.global_transform.origin = point
			spawn.scale = current_scale
	else:
		print("Meep")
	pass


