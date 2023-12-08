extends Node

var history: Dictionary = {"messages" : []}

func load_from_json_string(data: String):
	var new_history = JSON.parse_string(data)
	assert(new_history != null, "Error parsing history")
	
	history = new_history

func get_history():
	return history

func add_message(text: String, human: bool = false):
	history['messages'].push_back(
		{
			'text': text,
			'human': human,
			'name': 'NikoChat',
		}
	)
	#print("new history: " + JSON.stringify(history))
