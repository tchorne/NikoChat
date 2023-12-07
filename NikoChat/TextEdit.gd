extends TextEdit

signal message_sent(message: String)

func _input(event):
	if has_focus():
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_ENTER:
				send_message()
				get_viewport().set_input_as_handled()


func send_message():
	if text == "": return
	message_sent.emit(text)
	text = ""

func _on_connection_manager_server_connected():
	editable = true
	placeholder_text = ">"


func _on_connection_manager_server_disconnected():
	editable = false
	placeholder_text = "Lost Connection..."
