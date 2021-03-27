extends Control

var textbox_name:LineEdit
var checkbox_vr:CheckBox

onready var textbox_ip = $VBoxContainer/CenterContainer/VBoxContainer/GridContainer/TextEditIP

func _ready():
	textbox_name = $VBoxContainer/CenterContainer/VBoxContainer/GridContainer/TextEditName
	checkbox_vr = $VBoxContainer/CenterContainer/VBoxContainer/CheckBoxVR
	var player_data : Dictionary = SavedData.player_data()
	# FIXME Be sure to migrate all save data to new ones, filling up the
	# blanks if necessary
	textbox_name.set_text(player_data["username"])
	checkbox_vr.set_pressed(player_data["vr"])
	textbox_ip.text = Network.DEFAULT_IP

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
	pass # Replace with function body.

func create_rooms_list():
	#$RoomsList.popup_centered()
	#$RoomsList.refresh_players(Network.players)
	SavedData.save_data()
	if get_tree().change_scene("res://Test3D.tscn") != OK:
		printerr("Could not load the main scene :C")
	pass

func _on_CheckBoxVR_toggled(button_pressed):
	SavedData.saved_data["player"]["vr"] = button_pressed
	pass # Replace with function body.
