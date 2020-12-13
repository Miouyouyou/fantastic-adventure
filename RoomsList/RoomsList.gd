extends Popup

onready var players_list = $VBoxContainer/CenterContainer/ItemList

func _ready():
	players_list.clear()

func refresh_players(players):
	players_list.clear()
	for player_id in players:
		var player_infos = players[player_id]
		var player_name = player_infos["username"]
		players_list.add_item(player_name, null, false)
