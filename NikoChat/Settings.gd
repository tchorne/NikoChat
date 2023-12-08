extends Control


func _on_texture_button_pressed():
	visible = not visible


func _on_savedir_pressed():
	OS.shell_show_in_file_manager(OS.get_user_data_dir())
