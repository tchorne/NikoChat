extends Node

signal connected      # Connected to server
signal data           # Received data from server
signal disconnected   # Disconnected from server
signal error          # Error with connection to server

const HOST = "localhost"
const PORT = 8081

var _status: int = 0
var _stream: StreamPeerTCP = StreamPeerTCP.new()

func _ready() -> void:
	_status = _stream.get_status()

func _process(_delta: float) -> void:
	_stream.poll()
	var new_status: int = _stream.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			_stream.STATUS_NONE:
				print("Disconnected from host.")
				emit_signal("disconnected")
			_stream.STATUS_CONNECTING:
				print("Connecting to host.")
			_stream.STATUS_CONNECTED:
				print("Connected to host.")
				emit_signal("connected")
			_stream.STATUS_ERROR:
				print("Error with socket stream.")
				emit_signal("error")

	if _status == _stream.STATUS_CONNECTED:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			print("available bytes: ", available_bytes)
			@warning_ignore("shadowed_variable")
			var data: Array = _stream.get_partial_data(available_bytes)
			# Check for read error.
			if data[0] != OK:
				print("Error getting data from stream: ", data[0])
				emit_signal("error")
			else:
				emit_signal("data", data[1])


func connect_to_host(host: String, port: int) -> void:
	print("Connecting to %s:%d" % [host, port])
	# Reset status so we can tell if it changes to error again.
	_status = _stream.STATUS_NONE
	_stream.disconnect_from_host()
	if _stream.connect_to_host(host, port) != OK:
		print("Error connecting to host.")
		emit_signal("error")
		
@warning_ignore("shadowed_variable")
func send(data: PackedByteArray) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		print("Error: Stream is not currently connected.")
		return false
	var error: int = _stream.put_data(data)
	
	if error != OK:
		print("Error writing to stream: ", error)
		return false
	return true
	
@warning_ignore("shadowed_variable")
func send_message(data: String) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		print("Error: Stream is not currently connected.")
		StatusMessageBus.new_status("Error: Stream is not currently connected.")
		return false
	data.strip_edges()
	var data2 = data.to_utf8_buffer()
	assert(data != "")
	var _result = _stream.put_data(data2)
	
	StatusMessageBus.new_status("Message '" + data + "' sent")
	
	return true

func _on_connect_pressed():
	connect_to_host(HOST, PORT)


func _on_send_pressed():
	send(get_node("../UI/TextEdit").text)
