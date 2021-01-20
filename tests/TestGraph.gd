extends Control

var text_node = preload("res://tests/TestGraphNode.tscn")

func _ready():
	$GraphEdit.add_child(text_node.instance(), true)

func create_node(node_offset = Vector2(0,0)) -> GraphNode:
	var created_node : GraphNode = text_node.instance()
	created_node.offset += node_offset
	return created_node

func _on_GraphEdit_connection_from_empty(to : GraphNode, to_slot, release_position : Vector2):
	$GraphEdit.add_child(create_node(release_position))
	print(to)
	pass # Replace with function body.



func _on_GraphEdit_connection_to_empty(from : GraphNode, from_slot, release_position : Vector2):
	
	var node_to_add : GraphNode = create_node()
	var node_position : Vector2 = release_position
	node_position.y -= node_to_add.rect_size.y / 2
	node_to_add.offset = node_position
	$GraphEdit.add_child(node_to_add)
	print(from)
	pass # Replace with function body.


func _on_GraphEdit_popup_request(position):
	print("meep")
	print(position)
	pass # Replace with function body.
