extends Node


var saved_data : Dictionary = {}
const SAVE_PATH = "user://userprefs.json"

const player_defaults = {"username": "Unnamed hamster", "vr": false}
const system_defaults = {}

func _ready():
	load_data()

func fill_with_defaults(save:Dictionary):
	save["system"] = {}
	save["player"] = {"username": "Unnamed hamster", "vr": false}

func save_data_fill_missing_keys(save:Dictionary):
	for main_k in ["system", "player"]:
		if not save.has(main_k):
			save[main_k] = {}

	var save_system : Dictionary = save["system"]
	for k in system_defaults:
		if not save_system.has(k):
			save_system[k] = system_defaults[k]

	var save_player : Dictionary = save["player"]
	for k in player_defaults:
		if not save_player.has(k):
			save_player[k] = player_defaults[k]

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
	if data_loaded:
		save_data_fill_missing_keys(saved_data)
	# TODO else we're dealing with corrupted save data
	# Provide some clue to the user
	return data_loaded

func player_data() -> Dictionary :
	return saved_data["player"]

func system_data() -> Dictionary :
	return saved_data["system"]
