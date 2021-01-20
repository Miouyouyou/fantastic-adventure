extends GraphNode

func _ready() :
	$TextEdit.rect_min_size = rect_size
	set_slot(
		0,
		true, 0, Color(1,1,1,1),
		true, 0, Color(0.2,0.5,0.75)
	)

func _on_GraphNode_close_request():
	queue_free()

func _on_GraphNode_resize_request(new_minsize):
	rect_size = new_minsize
	$TextEdit.rect_min_size = new_minsize
