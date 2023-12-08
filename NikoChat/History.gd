extends Control

const HistoryLabelScene = preload("res://nodes/history_text_label.tscn")

const LOREM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc feugiat, ligula ac maximus lacinia, augue risus ultrices tortor, a consequat ipsum nibh ut dui. Proin rutrum, augue quis sagittis tincidunt, ex velit mattis tortor, nec aliquam purus arcu eget libero. Nam in commodo eros, iaculis finibus ipsum. Praesent et magna id odio finibus posuere. Suspendisse potenti. Donec faucibus urna enim, quis ultrices risus auctor et. Curabitur facilisis ultricies mi nec posuere. Nunc tempor tempus eros eu dictum. In tempor pellentesque felis sit amet dignissim. Aliquam nisl ex, rhoncus eget eros id, vulputate blandit diam. Nullam ac fermentum augue. Aenean pretium purus magna, vel commodo quam fringilla vitae. Mauris auctor finibus consequat. Sed gravida condimentum dui, id ornare sapien ultricies et. Etiam pulvinar in lacus sed interdum. Donec finibus eu felis nec posuere.Phasellus efficitur lorem eget velit porttitor, eget ornare elit pharetra. Suspendisse et diam ut arcu luctus tincidunt. Proin pellentesque augue massa, eu lacinia elit varius quis. Nulla tincidunt, nulla sed suscipit faucibus, turpis felis hendrerit leo, in dictum augue quam et dolor. Etiam felis justo, vestibulum vel cursus imperdiet, fringilla sit amet libero. Quisque pulvinar, libero eu vestibulum vulputate, nunc arcu posuere est, id tincidunt eros neque id sem. Nulla ac maximus libero, in scelerisque est. Quisque eget aliquam augue. Suspendisse interdum lacus purus, et egestas massa sodales et. Maecenas semper urna a justo aliquet tempor ac sit amet tortor. Curabitur pharetra et nunc sed gravida. "

@onready var container = $ScrollContainer/VBoxContainer

func _on_history_button_pressed():
	visible = not visible
	if visible:
		update_text()
		
func update_text():
	var history = HistoryManager.get_history()
	for elem in container.get_children():
		if is_instance_valid(elem):
			elem.queue_free()
			
	if history['messages'].is_empty():
		add_text("No history available")
		
		return
	
	for message in history['messages']:
		add_text(message['text'], message['human'])
		

func add_text(text: String, right=false):
	var t = HistoryLabelScene.instantiate()
	var split = HSplitContainer.new()
	split.split_offset = container.size.x / 2.0
	
	container.add_child(split)
	
	if right:
		split.add_child(Control.new())
		split.add_child(t)
	else:
		split.add_child(t)
		split.add_child(Control.new())
		
	t.text = text
	return t
	
