extends Spatial

const DOWNLOAD_RESOLVING    = 1 # STATUS_RESOLVING
const DOWNLOAD_CONNECTING   = 2 # STATUS_CONNECTING
const DOWNLOAD_REQUEST_SENT = 3 # STATUS_REQUESTING
const DOWNLOAD_IN_PROGRESS  = 4 # STATUS_CONNECTED
const DOWNLOAD_COMPLETED    = 5 # STATUS_DISCONNECTED / STATUS_BODY
const DOWNLOAD_ID_INVALID = -1
const DOWNLOAD_FAILED_CANT_RESOLVE_ADDRESS = -2 # STATUS_CANT_RESOLVE
const DOWNLOAD_FAILED_CANT_CONNECT         = -3 # STATUS_CANT_CONNECT
const DOWNLOAD_FAILED_SSL_ISSUE            = -4 # STATUS_SSL_HANDSHAKE_ERROR
const DOWNLOAD_FAILED_GENERIC_ERROR        = -5 # STATUS_CONNECTION_ERROR
const DOWNLOAD_FAILED_GENERIC_DISCONNECTED = -6 # STATUS_DISCONNECTED

const HTTPCLIENT_STATUS_MAPPINGS = [
	DOWNLOAD_FAILED_GENERIC_DISCONNECTED, # STATUS_DISCONNECTED
	DOWNLOAD_RESOLVING,                   # STATUS_RESOLVING
	DOWNLOAD_FAILED_CANT_RESOLVE_ADDRESS, # STATUS_CANT_RESOLVE
	DOWNLOAD_CONNECTING,                  # STATUS_CONNECTING
	DOWNLOAD_FAILED_CANT_CONNECT,         # STATUS_CANT_CONNECT
	DOWNLOAD_IN_PROGRESS,                 # STATUS_CONNECTED
	DOWNLOAD_REQUEST_SENT,                # STATUS_REQUESTING
	DOWNLOAD_IN_PROGRESS,                 # STATUS_BODY
	DOWNLOAD_FAILED_GENERIC_ERROR,        # STATUS_CONNECTION_ERROR
	DOWNLOAD_FAILED_SSL_ISSUE             # STATUS_SSL_HANDSHAKE_ERROR
]

signal download_ended(result,response_code,headers,body, download_id, reason, extra_arg)
# request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray)

func download_ended_dispatcher(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, download_id: int, reason: String, extra_arg):
	emit_signal("download_ended", result, response_code, headers, body, download_id, reason, extra_arg)

func is_download_status_error(status_code:int):
	return status_code > 0

func download(reason: String, url: String, extra_arg) -> int:
	var http_request:HTTPRequest = HTTPRequest.new()
	var download_id:int = http_request.get_instance_id()
	http_request.connect(
		"request_completed", self, "download_ended_dispatcher",
		[download_id, reason, extra_arg])
	add_child(http_request)
	http_request.request(url)
	return download_id

func _download_progress_hr(http_request:HTTPRequest) -> Array:
	var stat:int = HTTPCLIENT_STATUS_MAPPINGS[http_request.get_http_client_status()]
	var bytes_downloaded:int = http_request.get_downloaded_bytes()
	var bytes_total:int = http_request.get_body_size()
	if bytes_downloaded > 0 and bytes_total > 0 and bytes_downloaded == bytes_total:
		# Godot doesn't really differentiate between downloading and download complete
		# So, if the all the data appear downloaded, we'll consider the download
		# as complete
		# I rarely saw a 0 byte download, so I'll consider this as "bogus" for
		# now.
		stat = DOWNLOAD_COMPLETED
	return [stat, bytes_downloaded, bytes_total]

func download_progress(instance_id:int) -> Array:
	var request:Object = instance_from_id(instance_id)
	if not request is HTTPRequest:
		return [DOWNLOAD_ID_INVALID,-1,-1]
	return _download_progress_hr(request)

