extends Control


func _on_drag_gui_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(event.relative))


func _on_hide_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_close_pressed():
	get_tree().quit()
	
func _on_border_pressed():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, 
		not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS))
