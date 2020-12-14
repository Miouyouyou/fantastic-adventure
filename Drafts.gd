extends Node

var queued:Array = []
var last_pos:int = 0
var current_pos:int = 0

func import_in_background(args):
	var model_filepath:String = args[0]
	var queue:Array = args[1]
	queue.resize(8)
	print("Processing {model}...".format({"model": model_filepath}))
	var importer = PackedSceneGLTF.new()

	print("Importer ready")
	var nya:Spatial = importer.import_gltf_scene(model_filepath)
	print("Imported ({node})".format({"node": nya}))

	if nya != null:
		queue[current_pos] = nya
		current_pos += 1
		current_pos &= 7 # max 8 objects queued
	print("Finished processing {model}...".format({"model": model_filepath}))

func thread_generator():
	#var processing_thread:Thread = Thread.new()
	#processing_thread.start(self, "import_in_background", ["/tmp/test.glb", queued])
	#processing_thread = Thread.new()
	#processing_thread.start(self, "import_in_background", ["/home/gamer/tmp/model/Fox.glb", queued])
	
	pass
	
func _process(delta):
	while last_pos != current_pos:
		var current_model:Spatial = queued[last_pos]
		#var current_model_animator = find_animator_in(current_model)
		#for anim_name in current_model_animator.get_animation_list():
		#	popup.add_item(anim_name)
		#	popup.update()
		#	print(anim_name)
		#imported_anim = current_model_animator
		var c:Spatial = queued[last_pos]
		c.translate(Vector3(randf() * 15.0, 0.0, randf() * 15.0))
		$ToExport.add_child(queued[last_pos])
		last_pos += 1
		last_pos &= 7
