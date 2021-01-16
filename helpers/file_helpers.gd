extends Node

func read_text(filepath:String) -> String:
	var file_opener : File = File.new()
	var content:String = ""
	if file_opener.open(filepath,File.READ) == OK:
		content = file_opener.get_as_text()
	return content
