extends Node

const DEFAULT_IP:String = "127.0.0.1"
const DEFAULT_PORT:int = 27845
const MAX_PLAYERS = 8

var local_player_id = 0

# Why not just pass these as arguments ?
var selected_ip

sync var players = {}
sync var player_data = {}

#signal player_disconnected
#signal server_disconnected

signal joined
signal left


signal received_voip_packet(player_id, packet_index, packet)
# Taken from godot_voip_experimental
# TODO Move this to a helper library
static func encode_16_bit_value(p_value : int) -> PoolByteArray:
	return PoolByteArray([(p_value & 0x000000ff), (p_value & 0x0000ff00) >> 8])

static func decode_16_bit_value(p_buffer : PoolByteArray) -> int:
	var integer : int = 0
	integer = p_buffer[0] & 0x000000ff | (p_buffer[1] << 8) & 0x0000ff00
	return integer

static func encode_24_bit_value(p_value : int) -> PoolByteArray:
	return PoolByteArray([(p_value & 0x000000ff), (p_value & 0x0000ff00) >> 8, (p_value & 0x00ff0000) >> 16])

static func decode_24_bit_value(p_buffer : PoolByteArray) -> int:
	var integer : int = 0
	integer = p_buffer[0] & 0x000000ff | (p_buffer[1] << 8) & 0x0000ff00 | (p_buffer[2] << 16) & 0x00ff0000
	return integer

func encode_voice_packet(p_index : int, p_voice_buffer : PoolByteArray) -> PoolByteArray:
	var encoded_index : PoolByteArray = encode_24_bit_value(p_index)
	var encoded_size : PoolByteArray = encode_16_bit_value(p_voice_buffer.size())
	
	var new_pool = PoolByteArray()
	new_pool.append_array(encoded_index)
	new_pool.append_array(encoded_size)
	new_pool.append_array(p_voice_buffer)
	
	return new_pool

func decode_voice_packet(p_voice_buffer : PoolByteArray) -> Array:
	var new_pool : PoolByteArray = PoolByteArray()
	var encoded_id : int = -1

	if p_voice_buffer.size() > 5:
		var index : int = 0
		encoded_id = decode_24_bit_value(PoolByteArray([p_voice_buffer[index + 0], p_voice_buffer[index + 1], p_voice_buffer[index + 2]]))
		index += 3

		var encoded_size : int = decode_16_bit_value(PoolByteArray([p_voice_buffer[index + 0], p_voice_buffer[index + 1]]))
		index += 2

		new_pool = p_voice_buffer.subarray(index, index + (encoded_size - 1))

	return [encoded_id, new_pool]

func send_audio_packet(packet_index:int, packet: PoolByteArray) -> void:
	var compressed_audio_packet:PoolByteArray = encode_voice_packet(packet_index , packet)
	if get_tree().multiplayer.send_bytes(compressed_audio_packet, NetworkedMultiplayerPeer.TARGET_PEER_BROADCAST, NetworkedMultiplayerPeer.TRANSFER_MODE_UNRELIABLE) != OK:
		printerr("send_audio_packet: send_bytes failed!")

func _network_peer_custom_packet(sender_id:int, packet:PoolByteArray):
	# For the moment, the only custom packets we have to deal with
	# are VOIP packets, hence the absence of type checks.
	# Still :
	# TODO Perform actual sanitiy checks
	var result:Array = decode_voice_packet(packet)
	# result[0] is the index of the packet
	# result[1] is the actual packet
	emit_signal("received_voip_packet", sender_id, result[0], result[1])

func _ready():
	if get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected") != OK:
		printerr("Could not connect network_peer_disconnected on Network")
	if get_tree().connect("network_peer_connected", self, "_on_player_connected") != OK:
		printerr("Could not connect network_peer_connected on Network")
	if get_tree().multiplayer.connect("network_peer_packet", self, "_network_peer_custom_packet") != OK:
		printerr("Could not connect multiplayer network_peer_packet on Network")

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
	printerr("_on_player_connected : Called for " + str(id))
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has connected.")

func _on_player_disconnected(id):
	if not _we_are_the_server():
		print( "[Player] " + str(id) + " has fled !")
	emit_signal("left", id)

sync func update_waiting_room():
	get_tree().call_group("RoomsList", "refresh_players", players)
