extends Spatial

class JobResult:
	var success:bool = false
	var model:Spatial = Spatial.new()
	var model_reference

var jobs_in_progress:int = 0
var jobs_results:Array = []

signal object_loaded(model_reference, model)
signal object_load_error(model_reference)

func _background_load(args:Array) -> void:
	var glb_filepath:String = args[0]
	var model_reference = args[1]
	var global_jobs_results = args[2]
	var loader = PackedSceneGLTF.new()
	var node = loader.import_gltf_scene(glb_filepath)

	var job:JobResult = JobResult.new()
	job.model_reference = model_reference
	job.success = (node != null)
	if node != null:
		job.model  = node

	print_debug("Blah : " + str(job.success))
	global_jobs_results.append(job)
	pass

func load_in_background(glb_filepath:String, model_reference = null) -> void:
	if model_reference == null:
		model_reference = glb_filepath
	jobs_in_progress += 1
	var thread = Thread.new()
	thread.start(self, "_background_load", [glb_filepath, model_reference, jobs_results])
	set_process(true)
	pass

func _ready():
	set_process(false)
	pass

func _process(delta):
	# Let's avoid too much racing issues by only focusing
	# on the jobs we accounted for sure at the beginning of the function
	var n_jobs:int = jobs_results.size()
	print_debug("Pouip")
	for job_i in range(0, n_jobs):
		var job_result:JobResult = jobs_results[job_i]
		if job_result.success:
			print_debug("Object load success !")
			emit_signal("object_loaded",job_result.model_reference,job_result.model)
		else:
			print_debug("Failure !")
			emit_signal("object_load_error", job_result.model_reference)

	# I don't know how to write "loop n times" in Godot
	for a in range(0, n_jobs):
		jobs_results.remove(0)

	jobs_in_progress -= n_jobs

	# FIXME Let's make sure that we never hit "< 0"
	if jobs_in_progress <= 0:
		set_process(false)
