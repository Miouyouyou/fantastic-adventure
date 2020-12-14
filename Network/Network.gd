extends Node

const DEFAULT_IP:String = "127.0.0.1"
const DEFAULT_PORT:int = 27845
const MAX_PLAYERS = 8

var local_player_id = 0

# Why not just pass these as arguments ?
var selected_ip

sync var players = {}
sync var player_data = {}

signal player_disconnected
signal server_disconnected

signal joined

func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_player_connected")

func godot_connect_node(peer:NetworkedMultiplayerENet):
	get_tree().set_network_peer(peer)

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	godot_connect_node(peer)
	add_to_player_list()
	print("Server has been created for hamsters !")
	print("I am player id : " + str(local_player_id))

func connect_server():
	var peer = NetworkedMultiplayerENet.new()
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	godot_connect_node(peer)

func add_to_player_list():
	local_player_id = get_tree().get_network_unique_id()
	player_data = SavedData.saved_data["player"]
	players[local_player_id] = player_data

func _connected_to_server():
	print("Connected to server")
	add_to_player_list()
	rpc("_send_player_info", local_player_id, player_data)
	emit_signal("joined")

func _we_are_the_server():
	return get_tree().is_network_server()

remote func _send_player_info(id, other_player_data):
	print("send player info called !")
	players[id] = other_player_data
	if _we_are_the_server():
		rset("players", players)
		rpc("update_waiting_room")
		print( "[Server] " + str(id) + " has connected.")

func  _on_player_connected(id):
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has connected.")

func _on_player_disconnected(id):
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has fled !")

sync func update_waiting_room():
	get_tree().call_group("RoomsList", "refresh_players", players)
