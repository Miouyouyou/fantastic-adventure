extends Spatial

func _ready():
	var player_height = 3.1
	var shape_transform = Transform(
		Basis(Vector3(1.0, 0.0, 0.0), deg2rad(90.0)),
		Vector3(0.0, player_height / 2.0, 0.0))
	$MeshInstance.transform = shape_transform
