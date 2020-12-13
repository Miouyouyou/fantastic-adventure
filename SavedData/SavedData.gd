extends Node


var saved_data = {}
const SAVE_PATH = "user://userprefs.json"

func _ready():
	load_data()

func fill_with_defaults(save:Dictionary):
	save["system"] = {}
	save["player"] = {"username": "Unnamed hamster"}

func save_data_using(new_save_data):
	# TODO Make a backup of the old save, just in case
	var f:File = File.new()
	var everything_ok:bool = (f.open(SAVE_PATH, File.WRITE) == OK)
	if everything_ok:
		f.store_line(to_json(new_save_data))
		everything_ok = (f.get_error() == OK)
		f.close()
	return everything_ok

func save_data():
	save_data_using(saved_data)

func create_save_if_not_exist():
	var everything_ok:bool = true
	var f = File.new()
	# TODO Deal with corruption
	if not f.file_exists(SAVE_PATH):
		var new_save_data:Dictionary = {}
		fill_with_defaults(new_save_data)
		everything_ok = save_data_using(new_save_data)
	return everything_ok

# TODO Why not load everything from _ready ?
func load_data():
	var data_loaded:bool = false
	# TODO Signal the user about the issue if we could
	# not even create a basic save file
	create_save_if_not_exist()
	var f = File.new()
	# TODO Check and notify an issue we could not even
	# open the save file
	f.open(SAVE_PATH, File.READ)
	saved_data = parse_json(f.get_as_text())
	f.close()
	data_loaded = (saved_data is Dictionary)
	# TODO else we're dealing with corrupted save data
	# Provide some clue to the user
	return data_loaded

func user_data():
	return saved_data["player"]

func player_data():
	return saved_data["system"]
