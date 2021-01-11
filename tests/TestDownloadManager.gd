extends Control

func dl_cb(
	result: int,
	response_code: int,
	headers: PoolStringArray,
	body: PoolByteArray,
	download_id: int,
	reason: String,
	extra_arg
): # Horrendous indentation, but stupidly long lines are even worse...
	var text = (
		"result : {result}\n" +
		"response_code : {response_code}\n" +
		"download_id: {download_id}\n" +
		"reason : {reason}\n" +
		"arg : {arg}\n" +
		"== HEADERS ==\n{headers}\n" +
		"== BODY ==\n{body}\n").format({
			"result":result,
			"response_code":response_code,
			"headers":headers.join("\n"),
			"body":body.get_string_from_utf8(),
			"download_id": download_id,
			"reason": reason,
			"arg": extra_arg})
	print(text)
	print("dl_cb called !")

var dl_id:int
var dl_completed:bool = false
func _ready():
	if DownloadManager.connect("download_ended", self, "dl_cb") != OK:
		print_debug("Could not connect DownloadManager.download_ended to dl_cb")
	dl_id = DownloadManager.download("Test", "https://miouyouyou.fr", 12345678)

func _process(delta):
	if not dl_completed:
		var progress = DownloadManager.download_progress(dl_id)
		var dl_status = progress[0]
		dl_completed = (
			(dl_status == DownloadManager.DOWNLOAD_COMPLETED)
			or DownloadManager.is_download_status_error(dl_status))
		print(progress[0], " ", progress[1], " ", progress[2])
		
