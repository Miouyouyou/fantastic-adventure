extends Spatial

func get_model_aabb() -> AABB:
	return NodeHelpers.sum_aabb($"Model")

func zoom_on_model() -> void:
	# FIXME : I don't know what I'm doing.
	# This is just broken.
	# The idea is just to have the equivalent of "Focus on model".
	# I'll just look at Godot code to understand how to do it correctly.

	var aabb:AABB = get_model_aabb()
	print(aabb.position)
	print(aabb.size)
	print(aabb.end)

	var model_scale: Vector3 = Vector3(1,1,1)
	if $Model.get_child_count() > 0:
		model_scale = $Model.get_child(0).scale
	var model_size: Vector3 = aabb.size * model_scale
	var half_height:float = model_size.y / 2.0


	$Camera.transform.origin.z = -(model_size.y * 0.75) - (model_size.z / 4.0)
	$Camera.transform.origin.y = aabb.position.y * model_scale.y + half_height

func remove_children(node:Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func set_model(node:Node):
	remove_children($Model)
	$Model.add_child(node)
	zoom_on_model()

func _process(delta):
	$Model.rotate_y(deg2rad(1)) # delta 
