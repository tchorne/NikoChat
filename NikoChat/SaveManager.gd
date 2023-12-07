extends Node

"""

tokens {
	"user_token": 
}

savedata {
	
	"char_id": 
	"image_paths": {
		"happy": 
	}
	
}


"""

const FILENAME = "user://savedata.json"
const TOKENS = "user://tokens.json"

const DEFAULT_SAVE = {
	"char_id": "",
	"image_paths": {
		"happy": "user://",
		
	},
}

func get_save() -> Dictionary:
	if !FileAccess.file_exists(FILENAME):
		var f = FileAccess.open(FILENAME, FileAccess.WRITE)
		f.store_line(JSON.stringify(DEFAULT_SAVE))
		
		return DEFAULT_SAVE
		
	else:
		var f = FileAccess.open(FILENAME, FileAccess.READ)
		var json_string = f.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result:
			print_debug("JSON error in savedata")
		return json.get_data()

func save(data: Dictionary):
	
	var current_save = get_save()
	
	for key in data.keys():
		if key == "image_paths":
			for emotion in data[key]:
				current_save[key][emotion] = data[key][emotion]
			
		elif key in current_save:
			current_save[key] = data[key]
			
	
	
	pass
	
func save_token(_tokens: Dictionary):
	pass
