extends Node

signal message_response(response: String)
signal server_connected
signal server_disconnected

const HOST: String = "127.0.0.1"
const PORT: int = 8081
const RECONNECT_TIMEOUT: float = 3.0

const Client = preload("res://TCPClient.gd")
var _client: Client = Client.new()

func _ready() -> void:
	_client.connected.connect(_handle_client_connected)
	_client.disconnected.connect(_handle_client_disconnected)
	_client.error.connect(_handle_client_error)
	_client.data.connect(_handle_client_data)
	add_child(_client)
	_client.connect_to_host(HOST, PORT)

func _connect_after_timeout(timeout: float) -> void:
	await get_tree().create_timer(timeout).timeout
	if _client._status == StreamPeerTCP.STATUS_CONNECTED:
		return
	_client.connect_to_host(HOST, PORT)
	pass

func _handle_client_connected() -> void:
	print("Client connected to server.")
	server_connected.emit()
	_client.send_message("HISTORY")

func _handle_client_data(data: PackedByteArray) -> void:
	#print("Client data: ", data.get_string_from_utf8())
	handle_server_response(data.get_string_from_utf8())
	

func _handle_client_disconnected() -> void:
	print("Client disconnected from server.")
	server_disconnected.emit()
	_connect_after_timeout(RECONNECT_TIMEOUT) # Try to reconnect after 3 seconds

func _handle_client_error() -> void:
	print("Client error.")
	_connect_after_timeout(RECONNECT_TIMEOUT) # Try to reconnect after 3 seconds


func _on_send_pressed():
	#var message = get_node("../UI/TextEdit").text
	#_client.send_message("MSG:" + message)
	pass


func _on_text_edit_message_sent(message):
	_client.send_message("MSG:" + message)
	StatusMessageBus.new_status("on_text_edit_message_sent " + str(randi()%100))

func handle_server_response(response: String):
	if response.begins_with("MSG:"):
		message_response.emit(response.trim_prefix("MSG:"))
	elif response.begins_with("HISTORY:"):
		HistoryManager.load_from_json_string(response.trim_prefix("HISTORY:"))


func _on_settings_reconnect(ip, port):
	_client.connect_to_host(ip, port)


func _on_button_pressed():
	_client.send_message("MSG:test")
