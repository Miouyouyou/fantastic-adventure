extends Node

# TODO Merge with GLTFHelpers File helpers, since it has proper error handling

func read_text(filepath:String) -> String:
	var file_opener : File = File.new()
	var content:String = ""
	if file_opener.open(filepath,File.READ) == OK:
		content = file_opener.get_as_text()
		file_opener.close()
	return content

func read_buffer(filepath:String) -> PoolByteArray:
	var file_opener : File = File.new()
	if file_opener.open(filepath,File.READ) == OK:
		var content:PoolByteArray = file_opener.get_buffer(file_opener.get_len())
		file_opener.close()
		return content
	else:
		return PoolByteArray()

func write_text(filepath:String, text_to_write:String) -> int:
	var file_writer : File = File.new()
	var ret : int = file_writer.open(filepath, File.WRITE_READ)
	if ret == OK:
		file_writer.store_string(text_to_write)
		file_writer.close()
	return ret

func write_buffer(filepath:String, buffer:PoolByteArray) -> int:
	var file_writer : File = File.new()
	var ret : int = file_writer.open(filepath, File.WRITE_READ)
	if ret == OK:
		file_writer.store_buffer(buffer)
		file_writer.close()
	return ret

func sha256(filepath:String) -> String:
	var file_checker : File = File.new()
	return file_checker.get_sha256(filepath)

func write_sha256sum_of(filepath:String, sha256_filepath:String) -> int:
	var sha256sum:String = sha256(filepath)
	if sha256sum == "":
		print_debug("Cannot get the SHA256 sum of : " + filepath)
		return ERR_CANT_OPEN

	return write_text(sha256_filepath, sha256sum)

func get_size(filepath:String) -> int:
	var file_opener : File = File.new()
	var returned_size : int = 0
	var ret : int = file_opener.open(filepath, File.READ)
	if ret == OK:
		returned_size = file_opener.get_len()
		file_opener.close()
		return returned_size
	else:
		return -ret

func filesize_for_humans(filesize:int) -> String:
	var prefixes:PoolStringArray = ["", "K", "M", "G", "T", "P", "E"]
	var max_prefix_i:int = prefixes.size() - 1

	var prefix_i:int = 0
	var calc:int = filesize >> 4
	while calc > 0:
		prefix_i += 1
		calc >>= 4

	if prefix_i > max_prefix_i:
		prefix_i = max_prefix_i

	var human_readable_filesize = str(filesize >> (4 * prefix_i)) + " " + prefixes[prefix_i]
	return human_readable_filesize
