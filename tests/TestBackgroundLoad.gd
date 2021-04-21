extends Spatial

func _cb_model_loaded(model_ref, model:Spatial):
	model_ref.add_child(model)

func _cb_model_load_error(model_ref):
	print_debug("Could not load the model ! Calling the cops, right now !")

func _ready():
	$BackgroundLoader.connect("object_loaded", self, "_cb_model_loaded")
	$BackgroundLoader.connect("object_load_error", self, "_cb_model_load_error")
	var model:ModelsInventory.ModelInfos = ModelsInventory.list_cached_models()[0]
	$BackgroundLoader.load_in_background(model.filepath, self)
	pass

