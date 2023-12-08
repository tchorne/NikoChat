extends Node

const path_prefix = "res://assets/niko/niko"
const path_suffix = ".png"

const expressions = [
	"",
	"2",
	"3",
	"4",
	"5",
	"6",
	"_83c",
	"_smile",
	"_speak",
	]

const EMOTIONS = [
	"fun",
	"neutral",
	"sadness",
	"worry",
	"surprise",
	"love",
	"relief",
	"boredom",
	"anger",
]

const EXPRESSION_REDIRECTS = {
	"happiness": "fun",
	"enthusiasm": "fun",
	"hate": "anger",
	"empty": "sadness",
	"fear": "worry",
	"joy": "fun",
	"pessimism": "worry",
	"trust": "fun",
	"disgust": "anger",
	"anticipation": "fun",
	"optimism": "fun"
}

var images: Array[Texture] = []
var emotion_to_image_array: Dictionary = {}
var dict = {}

func _ready():
	
	#for e in expressions:
	#	var image = load(path_prefix + e + path_suffix)
	#	images.append(image)
	#	dict[e.lstrip("_")] = image
	
	refresh_sprites()

func load_sprites_for_emotion(emotion: String):
	var dir = DirAccess.open("user://images/".path_join(emotion))
	dir.list_dir_begin()
	emotion_to_image_array[emotion] = []
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			var path = OS.get_user_data_dir().path_join("images").path_join(emotion).path_join(file)
			var image = Image.new()
			image.load(path)
			emotion_to_image_array[emotion].append(ImageTexture.create_from_image(image))
	dir.list_dir_end()

func get_sprites_for_emotion(emotion: String):
	if emotion in EXPRESSION_REDIRECTS:
		emotion = EXPRESSION_REDIRECTS[emotion]
		
	if not emotion_to_image_array[emotion].is_empty():
		return emotion_to_image_array[emotion]
	else:
		return emotion_to_image_array["neutral"]

func refresh_sprites():
	for e in EMOTIONS:
		load_sprites_for_emotion(e)
