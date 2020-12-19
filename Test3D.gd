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

onready var speech = $Speech

var n_audio_packets : int = 0

func find_animator_in(model:Spatial):
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	return null

var exported:bool = false

sync func provide_local_player_transform(id, transform):
	players_transforms[id] = transform
	rset_unreliable("players_transforms", players_transforms)
	pass

func get_remote_player(id):
	var player_id = id
	if not remote_players.has(player_id):
		player_spawn_remote(player_id)
	return remote_players[player_id]

func _process(_delta):
	$CanvasLayer/HBoxContainer/LabelSpeedValue.text = str($Joueur.fall)

	var id:int = Network.local_player_id
	var local_player_transform:Transform = local_player.transform

	if not Network._we_are_the_server():
		rpc_unreliable_id(1, "provide_local_player_transform", id, local_player_transform)
	else:
		provide_local_player_transform(id, local_player_transform)

	for remote_player_id in players_transforms:
		if remote_player_id != Network.local_player_id:
			var remote_player = get_remote_player(remote_player_id)
			#remote_players[remote_player_id]
			remote_player.transform = players_transforms[remote_player_id]
			#if not Network._we_are_the_server():
			#	print("Local player id = " + str(remote_player_id) + " != " + str(Network.local_player_id))
			#	print("players_transforms[" + str(remote_player_id) + "] = " + str(players_transforms[remote_player_id]))
	speech_process_audio_input()
	$CanvasLayer/HBoxContainer/LabelPacketsNumber.text = str(n_audio_packets)
	$CanvasLayer/HBoxContainer/LabelVoiceIDValue.text = str(speech_voice_index)


onready var factory_player = preload("res://Joueur.tscn")
onready var factory_player_remote = preload("res://JoueurReseau.tscn")

func _ready():
	robot_anim.play("Love")
	popup = menu_button.get_popup()
	popup.hide_on_item_selection = false
	if popup.connect("id_pressed", self, "_on_item_pressed") != OK:
		printerr("Could not connect id_pressed on the animations popup GUI... ?")
	popup.set_position(Vector2(150,150))
	popup.show()

	player_spawn_local()
	speech_prepare()
	speech_start_recording()
	pass # Replace with function body.

func player_spawn_local():
	local_player = factory_player.instance()
	# ???
	players_transforms[Network.local_player_id] = local_player.transform
	add_child(local_player)
	#speech_add_player_audio(Network.local_player_id)

func player_spawn_remote(player_id):
	var remote_player = factory_player_remote.instance()
	remote_player.name = str(player_id)
	players_transforms[player_id] = remote_player.get_transform()
	remote_players[player_id] = remote_player
	add_child(remote_player)
	remote_player.set_billboard_name(Network.players[player_id]["username"])
	speech_add_player_audio(player_id)

func _on_item_pressed(_ID):
	#var items = popup.items
	#var selected_anim:String = popup.get_item_text(ID)
	#print("Meep")
	#print(ID)
	#print(popup.get_item_text(ID))
	#imported_anim.play(selected_anim)
	pass


const SPEECH_MAX_VOICE_BUFFERS = 16

var speech_players_streams : Dictionary = {}
var speech_voice_buffers : Array = []
# FIXME
# Might want to switch to double/triple buffers system,
# instead of creating arrays here and there
# That way we could reuse the same memory locations,
# instead of trashing the CPU caches.
func speech_copy_and_reset_voice_buffers() -> Array:
	var copied_voice_buffers : Array = speech_voice_buffers
	speech_voice_buffers = []
	return copied_voice_buffers

# ??? Buffer index ?
var speech_voice_index : int = 0
func speech_get_voice_index() -> int:
	return speech_voice_index
func speech_reset_voice_index() -> void:
	speech_voice_index = 0
func speech_increment_voice_index(val: int) -> void:
	speech_voice_index += val

func speech_start_recording() -> void:
	speech.start_recording()
	speech_reset_voice_index()

func speech_stop_recording() -> void:
	speech.stop_recording()

func speech_add_player_audio(player_id) -> void:
	var audio_stream_player = AudioStreamPlayer.new()
	speech_players_streams[player_id] = audio_stream_player
	audio_stream_player.set_name(str(player_id))

	speech.voice_controller.add_player_audio(player_id, audio_stream_player)
	# FIXME Categorize it inside the "Speech" node after that
	add_child(audio_stream_player)

func speech_remove_player_audio(player_id) -> void:
	speech.voice_controller.remove_player_audio(player_id)
	speech_players_streams[player_id].queue_free()
	if speech_players_streams.erase(player_id) != true:
		printerr("Player audio stream from " + str(player_id) + "did not exist")
	# TODO Check if that remove the child. Else we might have
	# to it manually.

func speech_receive_audio_packet(player_id, packet_index, packet):
	n_audio_packets += 1
	speech.on_received_external_audio_packet(player_id, packet_index, packet)

func speech_connect_signals() -> void:
	if Network.connect("received_voip_packet", self, "speech_receive_audio_packet") != OK:
		printerr("Could not connect VOIP packet handler on the Test3D scene")

func speech_setup_audio_input(_mic_node_name: String, mic_bus_name: String) -> void:
	var microphone_stream = $MicrophoneStreamAudio #get_node(mic_node_name)

	speech.set_audio_input_stream_player(microphone_stream)
	speech.set_streaming_bus(mic_bus_name)

func speech_prepare() -> void:
	speech_setup_audio_input("MicrophoneStreamAudio", "Mic")
	speech_connect_signals()

func speech_process_audio_input_get_buffers():
	var copied_voice_buffers : Array = speech.copy_and_clear_buffers()

	var current_skipped: int = speech.get_skipped_audio_packets()
	#print("current_skipped: %s" % str(current_skipped))
	speech.clear_skipped_audio_packets()

	speech_voice_index += current_skipped

	if copied_voice_buffers.size() > 0:
		for voice_buffer in copied_voice_buffers:
			if speech_voice_buffers.size() < SPEECH_MAX_VOICE_BUFFERS:
				speech_voice_buffers.push_back(voice_buffer)
			else:
				printerr("Voice buffer overrun!")
				#voice_buffer_overrun_count += 1

func speech_process_audio_input():
	if speech.is_recording():
		speech_process_audio_input_get_buffers()
		var current_index : int = speech_get_voice_index()
		var copied_buffers : Array = speech_copy_and_reset_voice_buffers()
		# FIXME :
		# This is the kind of situation where I prefer "Length" instead of
		# "Size". We're basically just counting how much packets we've sent
		# Therefore, index is clearly an ID in the end... I'll have to
		# change the index name back to ID.
		speech_increment_voice_index(copied_buffers.size())

		for buffer in copied_buffers:
			Network.send_audio_packet(current_index, buffer["byte_array"])
			current_index += 1
