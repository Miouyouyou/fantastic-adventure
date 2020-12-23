extends Control

var textbox_name:LineEdit

onready var textbox_ip = $VBoxContainer/CenterContainer/VBoxContainer/GridContainer/TextEditIP

func _ready():
	textbox_name = $VBoxContainer/CenterContainer/VBoxContainer/GridContainer/TextEditName
	textbox_name.set_text(SavedData.saved_data["player"]["username"])
	textbox_ip.text = Network.DEFAULT_IP
	_on_ButtonHost_pressed()

func _on_ButtonHost_pressed():
	Network.create_server()
	create_rooms_list()
	pass # Replace with function body.


func _on_ButtonJoin_pressed():
	# Clunky... Why not pass this to the Network class
	# and save it from there ?
	Network.selected_ip = textbox_ip.text
	if Network.connect("joined", self, "create_rooms_list") != OK:
		print_debug("Could not connect to the 'joined' signal on the Network object")
	Network.connect_server()
	#create_rooms_list()
	pass # Replace with function body.


func _on_TextEditName_text_changed(_new_text):
	# TODO Use functions to access the players data
	SavedData.saved_data["player"]["username"] = textbox_name.text
	# TODO This is insane... Only save when the user Join successfully
	# or start hosting
	SavedData.save_data()
	pass # Replace with function body.

func create_rooms_list():
	#$RoomsList.popup_centered()
	#$RoomsList.refresh_players(Network.players)
	if get_tree().change_scene("res://Test3D.tscn") != OK:
		printerr("Could not load the main scene :C")
	pass
