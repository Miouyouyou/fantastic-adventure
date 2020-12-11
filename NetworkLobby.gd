extends Control



func _on_ButtonHost_pressed():
	Network.create_server()
	pass # Replace with function body.


func _on_ButtonJoin_pressed():
	Network.connect_server()
	pass # Replace with function body.
