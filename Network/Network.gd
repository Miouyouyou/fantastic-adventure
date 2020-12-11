extends Node

const DEFAULT_IP:String = "127.0.0.1"
const DEFAULT_PORT:int = 27845
const MAX_PLAYERS = 8

var local_player_id = 0

var players = {} 

signal player_disconnected
signal server_disconnected

func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_player_connected")

func godot_connect_node(peer:NetworkedMultiplayerENet):
	get_tree().set_network_peer(peer)

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	godot_connect_node(peer)
	set_local_player_id()
	print("Server has been created for hamsters !")
	print("I am player id : " + str(local_player_id))

func connect_server():
	var peer = NetworkedMultiplayerENet.new()
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	godot_connect_node(peer)
	set_local_player_id()

func set_local_player_id():
	local_player_id = get_tree().get_network_unique_id()


func _connected_to_server():
	print("Connected to server")
	rpc("_send_player_info", local_player_id)
	pass

func _we_are_the_server():
	return get_tree().is_network_server()

func _send_player_info(id):
	if _we_are_the_server():
		print( "[Server] " + str(id) + " has connected.")

func  _on_player_connected(id):
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has connected.")

func _on_player_disconnected(id):
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has fled !")
