extends TextEdit

signal message_sent(message: String)

@export var move_up_on_focus : bool = false

@onready var chat : Control = get_tree().root.find_child("Chat", true, false)
var chat_base_height : float

func _ready():
	chat_base_height = chat.size.y

func _input(event):
	if has_focus():
		if event is InputEventKey and event.is_pressed() and not Input.is_key_pressed(KEY_SHIFT):
			if event.keycode == KEY_ENTER:
				send_message()
				get_viewport().set_input_as_handled()


func send_message():
	if text == "": return
	message_sent.emit(text)
	HistoryManager.add_message(text, true)
	text = ""

func _on_connection_manager_server_connected():
	editable = true
	placeholder_text = ">"
	text = ""


func _on_connection_manager_server_disconnected():
	editable = false
	placeholder_text = "Lost Connection..."


func _on_settings_reconnect(ip, port):
	text = "Connecting to IP " + ip + " PORT " + str(port)


func _on_focus_entered():
	if move_up_on_focus:
		chat.size.y = chat_base_height - 600


func _on_focus_exited():
	if move_up_on_focus:
		chat.size.y = chat_base_height
