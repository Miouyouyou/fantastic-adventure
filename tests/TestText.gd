extends Control

var show:bool = true

func _ready():
	$Label.text = "Un poukacha sauvage apparaît. Il essaye de piquer votre portefeuille."
	print($Label.get_minimum_size())
	print(Vector3.FORWARD)
	print(Vector3.LEFT)

func _unhandled_key_input(event):
	var e:InputEventKey = event
	if event.scancode == KEY_D and !event.pressed:
		$Label.text = "Ah ben voilà, il s'est barré avec..."
		print($Label.get_minimum_size())
