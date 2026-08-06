extends Node

signal register_completed(success: bool, data: Dictionary)
signal login_completed(success: bool, data: Dictionary)

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 8080
const MAX_FRAME_SIZE := 1 << 20

## Server address. Overridable via user://server.cfg with keys
## "server/host" and "server/port".
var host: String = DEFAULT_HOST
var port: int = DEFAULT_PORT

var _tcp := StreamPeerTCP.new()
var _inbox := PackedByteArray()
var _frame_len := -1
var _next_id := 1
var _pending: Array = []
var _outbox: Array = []


func _ready() -> void:
	_tcp.set_big_endian(true)
	var config := ConfigFile.new()
	if config.load("user://server.cfg") == OK:
		host = config.get_value("server", "host", DEFAULT_HOST)
		port = int(config.get_value("server", "port", DEFAULT_PORT))
	_connect()


## Sends a register request. Emits register_completed on a response.
func register(username: String, password: String) -> void:
	_send_request("register", {"username": username, "password": password}, "register")


## Sends a login request. Emits login_completed on a response.
func login(username: String, password: String) -> void:
	_send_request("login", {"username": username, "password": password}, "login")


func _send_request(request_type: String, data: Dictionary, pending_type: String) -> void:
	var id := _next_id
	_next_id += 1
	_pending.append({"type": pending_type, "id": id})
	var payload := JSON.stringify({"type": request_type, "id": id, "data": data}).to_utf8_buffer()
	_outbox.append(payload)
	_connect()


func _connect() -> void:
	var status := _tcp.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED or status == StreamPeerTCP.STATUS_CONNECTING:
		return
	_tcp.connect_to_host(host, port)


func _process(_delta: float) -> void:
	_tcp.poll()
	var status := _tcp.get_status()
	if status == StreamPeerTCP.STATUS_ERROR:
		_fail_pending("connection_failed")
		_tcp.disconnect_from_host()
		return
	if status != StreamPeerTCP.STATUS_CONNECTED:
		return
	_flush_outbox()
	var available := _tcp.get_available_bytes()
	if available <= 0:
		return
	var res := _tcp.get_data(available)
	if res[0] == OK:
		_inbox.append_array(res[1])
		_drain_inbox()


func _flush_outbox() -> void:
	while not _outbox.is_empty():
		var payload: PackedByteArray = _outbox.pop_front()
		_tcp.put_32(payload.size())
		_tcp.put_data(payload)


func _drain_inbox() -> void:
	while true:
		if _frame_len < 0:
			if _inbox.size() < 4:
				return
			_frame_len = (_inbox[0] << 24) | (_inbox[1] << 16) | (_inbox[2] << 8) | _inbox[3]
			_inbox = _inbox.slice(4)
		if _inbox.size() < _frame_len:
			return
		var payload := _inbox.slice(0, _frame_len)
		_inbox = _inbox.slice(_frame_len)
		_frame_len = -1
		_handle_response(payload)


func _handle_response(payload: PackedByteArray) -> void:
	var json = JSON.parse_string(payload.get_string_from_utf8())
	if json == null or not json is Dictionary:
		_fail_pending("invalid_response")
		return
	var resp: Dictionary = json
	var index := _find_pending(int(resp.get("id", 0)))
	if index < 0:
		return
	var entry: Dictionary = _pending[index]
	_pending.remove_at(index)
	var resp_type: String = resp.get("type", "")
	var data: Dictionary = resp.get("data", {})
	if resp_type == "%s_ok" % entry["type"]:
		if entry["type"] == "register":
			register_completed.emit(true, data)
		else:
			login_completed.emit(true, data)
	else:
		_fail_one(entry, data.get("message", "unknown error"))


func _find_pending(id: int) -> int:
	for i in _pending.size():
		if _pending[i]["id"] == id:
			return i
	return -1


func _fail_one(entry: Dictionary, message: String) -> void:
	var err_data := {"error": message}
	if entry["type"] == "register":
		register_completed.emit(false, err_data)
	else:
		login_completed.emit(false, err_data)


func _fail_pending(message: String) -> void:
	while not _pending.is_empty():
		_fail_one(_pending.pop_front(), message)
