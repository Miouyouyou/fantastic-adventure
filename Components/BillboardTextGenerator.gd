extends Viewport

func get_billboard_texture_from_text(provided_text:String):
	$Control/Text.text = provided_text
	#var text_min_size = $Control/Text.get_minimum_size()
	#$Control.set_size(text_min_size)
	#set_size(text_min_size)
	#print(text_min_size)
	var data = get_texture().get_data()
	data.flip_y()
	#data.save_png("/tmp/test.png")
	return data

func get_text_size():
	return $Control/Text.get_minimum_size()

func _ready():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
