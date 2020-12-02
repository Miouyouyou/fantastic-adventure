extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var robot = $Robot
onready var robot_anim = $Robot/AnimationPlayer

onready var menu_button:MenuButton = $CanvasLayer/HBoxContainer/AnimationListPopup
var popup:PopupMenu

var imported_anim:AnimationPlayer
# Called when the node enters the scene tree for the first time.

var queued:Array = []
var last_pos:int = 0
var current_pos:int = 0
var processing_thread:Thread = Thread.new()



func import_in_background(args):
	var model_filepath:String = args[0]
	var queue:Array = args[1]
	queue.resize(8)
	print("Processing {model}...".format({"model": model_filepath}))
	#var importer = PackedSceneGLTF.new()
	#print("Importer ready")
	#var nya:Spatial = importer.import_gltf_scene(model_filepath)
	#print("Imported ({node})".format({"node": nya}))

	#if nya != null:
	#	queue[current_pos] = nya
	#	current_pos += 1
	#	current_pos &= 7 # max 8 objects queued
	#print("Finished processing {model}...".format({"model": model_filepath}))

func find_animator_in(model:Spatial):
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	return null

func _process(delta):
	while last_pos != current_pos:
		var current_model:Spatial = queued[last_pos]
		var current_model_animator = find_animator_in(current_model)
		for anim_name in current_model_animator.get_animation_list():
			popup.add_item(anim_name)
			popup.update()
			print(anim_name)
		imported_anim = current_model_animator
		add_child(queued[last_pos])
		last_pos += 1
		last_pos &= 7

func _ready():
	robot_anim.play("Love")
	popup = menu_button.get_popup()
	popup.hide_on_item_selection = false
	popup.connect("id_pressed", self, "_on_item_pressed")
	popup.set_position(Vector2(150,150))
	popup.show()
	processing_thread.start(self, "import_in_background", ["/tmp/model/scene.glb", queued])
	pass # Replace with function body.

func _on_item_pressed(ID):
	var items = popup.items
	var selected_anim:String = popup.get_item_text(ID)
	print("Meep")
	print(ID)
	print(popup.get_item_text(ID))
	imported_anim.play(selected_anim)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
