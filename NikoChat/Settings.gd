extends Control

signal reconnect(ip: String, port: int)

func _ready():
	var data = SaveManager.get_save()
	
	if "default_ip" in data and "default_port" in data:
		$IPEdit.text = data["default_ip"] + ":" + str(data["default_port"])

func _on_texture_button_pressed():
	visible = not visible


func _on_savedir_pressed():
	OS.shell_show_in_file_manager(OS.get_user_data_dir())


func _on_reconnect_pressed():
	var split = $IPEdit.text.split(":")
	
	var ip
	var port
	
	if split.size() == 2 and split[1]:
		ip = split[0]
		port = int(split[1])
	elif split.size() == 1:
		ip = split[0]
		port = 8081
	else:
		return
	reconnect.emit(ip, port)
	


func _on_reconnect_2_pressed():
	var split = $IPEdit.text.split(":")
	
	var ip
	var port
	
	if split.size() == 2 and split[1]:
		ip = split[0]
		port = int(split[1])
	elif split.size() == 1:
		ip = split[0]
		port = 8081
		
	var data = {
		"default_ip": ip,
		"default_port": port,
		}
	SaveManager.save(data)
