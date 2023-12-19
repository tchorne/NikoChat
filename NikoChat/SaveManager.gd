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
	"default_ip": "localhost",
	"default_port": 8081,
}

func _ready():
	make_directories()

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
		if parse_result:
			print_debug("JSON error in savedata, error " + json.get_error_message())
			
		return json.get_data()

func make_directories():
	var dir = DirAccess.open("user://")
	dir.make_dir("images")
	dir.make_dir("images/fun")
	dir.make_dir("images/neutral")
	dir.make_dir("images/sadness")
	dir.make_dir("images/worry")
	dir.make_dir("images/surprise")
	dir.make_dir("images/love")
	dir.make_dir("images/relief")
	#dir.make_dir("images/happiness") fun
	# dir.make_dir("images/empty") sadness
	dir.make_dir("images/boredom")
	# dir.make_dir("images/enthusiasm") fun
	dir.make_dir("images/anger")
	# dir.make_dir("images/hate") anger
	dir.make_dir("images/think")
	dir.make_dir("images/sleep")
	
func save(data: Dictionary):
	
	var current_save = get_save()
	
	for key in data.keys():
		if key == "image_paths":
			for emotion in data[key]:
				current_save[key][emotion] = data[key][emotion]
			
		else:
			current_save[key] = data[key]
	
	var f = FileAccess.open(FILENAME, FileAccess.WRITE)
	print(JSON.stringify(current_save))
	f.store_line(JSON.stringify(current_save))
	
	
	pass
	
func save_token(_tokens: Dictionary):
	pass
