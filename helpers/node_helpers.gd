extends Node

static func merge_with_all_aabb(n:Node, aabb:AABB) -> AABB:
	if n.has_method("get_aabb"):
		print(n)
		aabb = aabb.merge(n.get_aabb())
	for child in n.get_children():
		aabb = merge_with_all_aabb(child, aabb)
	return aabb

static func sum_aabb(n:Node) -> AABB:
	var aabb:AABB = AABB()
	return merge_with_all_aabb(n,aabb).abs()

static func remove_children(nod:Node) -> void:
	for child_i in range(0,nod.get_child_count()):
		nod.remove_child(nod.get_child(child_i))
