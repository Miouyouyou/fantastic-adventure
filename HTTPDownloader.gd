extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var http_req:HTTPRequest

var previous_status = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	http_req = get_node("HTTPRequest")
	http_req.connect("request_completed", self, "download_completed")
	download("https://uploads-prod.reticulum.io/files/eeb68eb6-155f-4499-b4b1-7ab74ee5d040.glb", "/tmp/test.glb")
	pass # Replace with function body.

func download(url, filepath):
	http_req.set_download_file(filepath)
	http_req.request(url)

func _process(_delta):
	var status = http_req.get_http_client_status()
	if status == HTTPClient.STATUS_BODY:
		print(str(http_req.get_downloaded_bytes()) + " / " + str(http_req.get_body_size()))
	elif status != previous_status:
		print("Status : " + str(status))
	previous_status = status

func download_completed(result, response_code, _headers, _body):
	print(
		("Result : {result}\n" +
		"Response code : {response_code}\n").format({
			"result": result,
			"response_code": response_code}))
	if response_code < 400:
		var importer:PackedSceneGLTF = PackedSceneGLTF.new()
		var rez = importer.import_gltf_scene(http_req.download_file)
		print(rez)
		get_parent().add_child(rez)

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
