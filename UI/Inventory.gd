extends Control

var thumbnail_object = preload("res://UI/ModelThumbnail.tscn")
var ui_items

export(NodePath) var path_picture
export(NodePath) var path_userscale
export(NodePath) var path_scaled_width
export(NodePath) var path_scaled_height
export(NodePath) var path_scaled_depth
export(NodePath) var path_original_width
export(NodePath) var path_original_height
export(NodePath) var path_original_depth
export(NodePath) var path_provider
export(NodePath) var path_license
export(NodePath) var path_description

onready var ui_desc_picture : TextureRect = get_node(path_picture)
onready var ui_desc_userscale : SpinBox = get_node(path_userscale)
onready var ui_desc_metrics_scaled_width : Label = get_node(path_scaled_width)
onready var ui_desc_metrics_scaled_height : Label = get_node(path_scaled_height)
onready var ui_desc_metrics_scaled_depth : Label = get_node(path_scaled_depth)
onready var ui_desc_metrics_original_width : Label = get_node(path_original_width)
onready var ui_desc_metrics_original_height : Label = get_node(path_original_height)
onready var ui_desc_metrics_original_depth : Label = get_node(path_original_depth)
onready var ui_desc_source_provider : Label = get_node(path_provider)
onready var ui_desc_license : Label = get_node(path_license)
onready var ui_desc_description : Label = get_node(path_description)

signal model_selected(model, thumbnail)

func refresh_list():
	NodeHelpers.remove_children(ui_items)
	var models:Array = ModelsInventory.list_cached_models()
	for model in models:
		model.dump()

		var image_read = ImageHelpers.read_image_texture_from_disk(model.thumbnail_filepath)
		if image_read.status == OK:
			var thumbnail = thumbnail_object.instance()
			ui_items.add_child(thumbnail)
			thumbnail.set_thumbnail(image_read.image)
			thumbnail.set_description(model.metadata["name"])
			# FIXME Replace this by a signal
			thumbnail.set_click_handler(self, "cb_item_clicked", [model, image_read.image])

func _ready():
	ui_items = $HSplitContainer/ScrollContainer/GridContainer
	refresh_list()

var current_model:ModelsInventory.ModelInfos
var current_model_set:bool = false

func cb_item_clicked(args:Array) -> void:
	current_model_set = false
	var model:ModelsInventory.ModelInfos = args[0]
	var thumbnail:ImageTexture = args[1]
	ui_desc_picture.texture = thumbnail
	# FIXME This should be define in User Preferences, stored alongside
	# the cached model
	
	var model_size:Vector3 = model.aabb.size
	var model_scale:float = model.userprefs["scale"]
	var model_size_scaled:Vector3 = model.aabb.size * model_scale
	ui_desc_userscale.value = model_scale * 100
	ui_desc_metrics_scaled_width.text = str(model_size_scaled.x)
	ui_desc_metrics_scaled_height.text = str(model_size_scaled.y)
	ui_desc_metrics_scaled_depth.text = str(model_size_scaled.z)
	ui_desc_metrics_original_width.text = str(model_size.x)
	ui_desc_metrics_original_height.text = str(model_size.y)
	ui_desc_metrics_original_depth.text = str(model_size.z)
	ui_desc_source_provider.text = model.metadata["provider"]
	ui_desc_license.text = model.metadata["license"]
	current_model = model
	current_model_set = true
	emit_signal("model_selected", current_model, thumbnail)

func get_current_scale() -> float:
	return ui_desc_userscale.value / 100

func show_scale() -> void:
	var model_size_scaled:Vector3 = current_model.aabb.size * get_current_scale() 
	ui_desc_metrics_scaled_width.text = str(model_size_scaled.x)
	ui_desc_metrics_scaled_height.text = str(model_size_scaled.y)
	ui_desc_metrics_scaled_depth.text = str(model_size_scaled.z)

func _on_LineEdit_value_changed(value):
	if current_model_set:
		show_scale()
		var current_scale:float = get_current_scale()
		current_model.userprefs["scale"] = current_scale
		print_debug("New scale : " + str(current_scale))
		print_debug("Saved : " + str(current_model.save_prefs()))
	pass # Replace with function body.
