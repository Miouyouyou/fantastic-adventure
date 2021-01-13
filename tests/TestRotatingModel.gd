extends Spatial

func _process(delta):
	$Model.rotate_y(1*delta)
