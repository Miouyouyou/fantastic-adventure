extends Spatial

func merge_with_all_aabb(n:Node, aabb:AABB) -> AABB:
	if n.has_method("get_aabb"):
		print(n)
		aabb = aabb.merge(n.get_aabb())
	for child in n.get_children():
		aabb = merge_with_all_aabb(child, aabb)
	return aabb

func sum_aabb(n:Node) -> AABB:
	var aabb:AABB = AABB()
	return merge_with_all_aabb(n,aabb).abs()

func zoom_on_model() -> void:
	# I don't know what I'm doing.
	# Technically, the whole point is to get the height of the model
	# and map it so that the Camera center is identical to the model center,
	# and then moving back so that :
	# model.center to model.half_height maps to 0.0 -> 1.0 in OpenGL.
	# Which means that model.height maps to -1.0 -> 1.0
	# The current view matrix 'probably' use z as 'w' meaning that the width
	# and the height are divided by the depth coordinate (x/z, y/z) to get a
	# perspective... But my knowledge stop around that part.
	# Still, the whole point is to map the whole height of the model to
	# -1.0 <-> 1.0 in the vertex shader.
	# That said, these naive approach are not really working :
	# $Camera.transform.origin.z = -aabb.position.y # Too far
	# $Camera.transform.origin.z = -aabb.position.y * 0.5 # Too near
	# $Camera.transform.origin.z = -aabb.position.y * 0.75
	# # Close but still a little too near
	var aabb:AABB = sum_aabb($"Model")
	print(aabb.position)
	print(aabb.size)
	print(aabb.end)

	var model_scale: Vector3 = Vector3(1,1,1)
	if $Model.get_child_count() > 0:
		model_scale = $Model.get_child(0).scale
	var model_size: Vector3 = aabb.size * model_scale
	var half_height:float = model_size.y / 2.0

	# 75% of the size seems to provide an almost correct position, but still
	# a little to near.
	# Getting 1/4 of the depth back seems to almost do the trick...
	# When tested with just fourmodels... We'll see after that.
	# I'm also expecting that the AABB calculations are correct, which might
	# not be always the case.
	$Camera.transform.origin.z = -(model_size.y * 0.75) - (model_size.z / 4.0)
	# -((aabb.size.y + (aabb.size.z / 2.0)) * ($Camera.fov / 100))
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
