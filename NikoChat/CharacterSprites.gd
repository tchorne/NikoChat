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

var images: Array[Texture] = []
var dict = {}

func _ready():
	#for e in expressions:
	#	var image = load(path_prefix + e + path_suffix)
	#	images.append(image)
	#	dict[e.lstrip("_")] = image
	refresh_sprites()

func refresh_sprites():
	var _data = SaveManager.get_save()
	
	
