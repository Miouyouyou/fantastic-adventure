extends Spatial

onready var robot = $Robot
onready var robot_anim = $Robot/AnimationPlayer

onready var menu_button:MenuButton = $CanvasLayer/HBoxContainer/AnimationListPopup
var popup:PopupMenu

var imported_anim:AnimationPlayer
# Called when the node enters the scene tree for the first time.

sync var players_transforms = {}
sync var remote_players = {}
var local_player

func find_animator_in(model:Spatial):
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	return null

var exported:bool = false

sync func provide_local_player_transform(id, transform):
	players_transforms[str(id)] = transform
	rset_unreliable("players_transforms", players_transforms)
	pass

func get_remote_player(id):
	var player_id = str(id)
	if not remote_players.has(player_id):
		player_spawn_remote(id)
	return remote_players[player_id]

func _process(delta):
	$CanvasLayer/HBoxContainer/LabelSpeedValue.text = str($Joueur.fall)

	var id:int = Network.local_player_id
	var local_player_transform:Transform = local_player.transform

	if not Network._we_are_the_server():
		rpc_unreliable_id(1, "provide_local_player_transform", id, local_player_transform)
	else:
		provide_local_player_transform(id, local_player_transform)

	for remote_player_id in players_transforms:
		if remote_player_id != str(Network.local_player_id):
			var remote_player = get_remote_player(remote_player_id)
			remote_players[remote_player_id].transform = players_transforms[remote_player_id]
			if not Network._we_are_the_server():
				print("Local player id = " + remote_player_id + " != " + str(Network.local_player_id))
				print("players_transforms[" + remote_player_id + "] = " + str(players_transforms[remote_player_id]))

onready var factory_player = preload("res://Joueur.tscn")
onready var factory_player_remote = preload("res://JoueurReseau.tscn")

func _ready():
	robot_anim.play("Love")
	popup = menu_button.get_popup()
	popup.hide_on_item_selection = false
	popup.connect("id_pressed", self, "_on_item_pressed")
	popup.set_position(Vector2(150,150))
	popup.show()

	player_spawn_local()

	pass # Replace with function body.

func player_spawn_local():
	local_player = factory_player.instance()
	# ???
	players_transforms[str(Network.local_player_id)] = local_player.transform
	add_child(local_player)

func player_spawn_remote(id):
	var player_id = str(id)
	var remote_player = factory_player_remote.instance()
	remote_player.name = player_id
	players_transforms[player_id] = remote_player.get_transform()
	remote_players[player_id] = remote_player
	add_child(remote_player)

func _on_item_pressed(ID):
	#var items = popup.items
	#var selected_anim:String = popup.get_item_text(ID)
	#print("Meep")
	#print(ID)
	#print(popup.get_item_text(ID))
	#imported_anim.play(selected_anim)
	pass
