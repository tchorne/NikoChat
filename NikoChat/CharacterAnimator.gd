extends Node

@export var label: RichTextLabel
@export var portrait: TextureRect
@export var sound: AudioStreamPlayer
@export var thinking: Label

const TIME_BETWEEN_CHARS = 1.0/40
const FAST_SPEED = 1.0/80
const SLOW_SPEED = 1.0/40
const SOUND_SPEED = 1.0/13
const SLEEP_SECONDS = 60*30

var animating = false
var time_until_next_char = TIME_BETWEEN_CHARS
var time_until_next_sound = SOUND_SPEED
var speed = FAST_SPEED


var emotion: String = ""

func _ready():
	thinking.get_node("Animation").play("thinking")
	_on_sleep_timer_timeout()

func update_text(text: String):
	if text.begins_with("<"):
		emotion = text.substr(1, text.find(">")).rstrip(">")
		print("Emotion Detected: " + emotion)
		text = text.trim_prefix("<" + emotion + ">")
		
	else:
		emotion = "neutral"
		
	
	animating = true
	label.visible_characters = 0
	label.text = text
	sound.play()
	time_until_next_char = TIME_BETWEEN_CHARS
	time_until_next_sound = SOUND_SPEED
	
	update_portrait()

func update_portrait():
	var old_texture = portrait.texture
	
	var images = CharacterSprites.get_sprites_for_emotion(emotion)
	
	if images.size() >= 2:
		while portrait.texture == old_texture:
			portrait.texture = images.pick_random()
	elif images.size() == 1:
		portrait.texture = images[0]
	
		

func _process(delta):
	if animating:
		time_until_next_char -= delta
		time_until_next_sound -= delta
		if time_until_next_sound <= 0:
			time_until_next_sound = SOUND_SPEED
			sound.play()
					
		if time_until_next_char <= 0:
			time_until_next_char = TIME_BETWEEN_CHARS
			label.visible_characters += 1
			if label.visible_characters % 70 == 0:
				update_portrait()
				
		if label.visible_characters > label.text.length():
			animating = false
			if emotion != "sleep":
				$SleepTimer.start(SLEEP_SECONDS)

func _on_text_edit_message_sent(_message):
	thinking.visible = true
	emotion = "think"
	update_portrait()

func _on_sleep_timer_timeout():
	emotion = "sleep"
	update_text("<sleep>...")

func _on_connection_manager_message_response(response):
	HistoryManager.add_message(response, false)
	thinking.visible = false
	update_text(response)
