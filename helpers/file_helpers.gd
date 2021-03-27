extends Node

# TODO Merge with GLTFHelpers File helpers, since it has proper error handling

func read_text(filepath:String) -> String:
	var file_opener : File = File.new()
	var content:String = ""
	if file_opener.open(filepath,File.READ) == OK:
		content = file_opener.get_as_text()
		file_opener.close()
	return content

func write_text(filepath:String, text_to_write:String) -> int:
	var file_writer : File = File.new()
	var ret : int = file_writer.open(filepath, File.WRITE_READ)
	if ret == OK:
		file_writer.store_string(text_to_write)
		file_writer.close()
	return ret
