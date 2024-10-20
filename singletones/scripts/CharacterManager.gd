extends Node

## This Dictionary contains all suits for all characters available in the game.
## To add your own suits and characters, use the "add_suits" method in an autoload script inside of your project.
## The dictionary is stored like this:
##   (list of power names) => dictionary of character names => suit resources
## i.e. "suits.Mario.small" returns a PlayerSuit of small Mario.
var suits: Dictionary = {}
var voice_lines: Dictionary = {}

## Base suits for Mario
const MARIO_SUITS: Dictionary = {
	"small": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres"),
	"super": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_super.tres"),
	"fireball": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_fireball.tres"),
	"beetroot": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_beetroot.tres"),
	"green_lui": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_green_lui.tres"),
	"iceball": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_iceball.tres"),
}
## Base suits for Luigi
const LUIGI_SUITS: Dictionary = {
	"small": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_small.tres"),
	"super": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_super.tres"),
	"fireball": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_fireball.tres"),
	"beetroot": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_beetroot.tres"),
	"green_lui": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_green_lui.tres"),
	"iceball": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_iceball.tres"),
}


const MARIO_VOICE_LINES: Dictionary = {
	"checkpoint": [
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_1.ogg"),
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_2.ogg"),
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_3.ogg"),
	],
	"oh_no": preload("res://engine/objects/players/prefabs/sounds/mario/oh_no.wav"),
	"fall": preload("res://engine/objects/players/prefabs/sounds/mario/uwaah.wav"),
}

const LUIGI_VOICE_LINES: Dictionary = {
	"checkpoint": [
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_1.wav"),
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_2.wav"),
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_3.wav"),
	],
	"oh_no": preload("res://engine/objects/players/prefabs/sounds/luigi/oh_no.wav"),
	"fall": preload("res://engine/objects/players/prefabs/sounds/luigi/uwaah.wav"),
}

func _ready() -> void:
	add_suits(MARIO_SUITS, "Mario")
	add_suits(LUIGI_SUITS, "Luigi")
	add_voice_lines(MARIO_VOICE_LINES, "Mario")
	add_voice_lines(LUIGI_VOICE_LINES, "Luigi")
	print(suits)


func get_suit(suit_name: String, character_name: String = "") -> PlayerSuit:
	var player = Thunder._current_player
	var chara: String = character_name
	if chara.is_empty() && player && player.character in suits:
		chara = player.character
	
	if chara && chara in suits && suit_name in suits[chara]:
		return suits[chara][suit_name]
	return null


func get_suit_names(character_name: String = "") -> Array:
	var player = Thunder._current_player
	var chara: String = character_name
	if chara.is_empty() && player && player.character in suits:
		chara = player.character
	
	var suit_name_arr: Array = []
	if chara && chara in suits:
		for key in suits[chara].keys():
			suit_name_arr.append(key)
	return suit_name_arr


func get_voice_line(voice_line: String, character_name: String = "") -> Variant:
	var player = Thunder._current_player
	var chara: String = character_name
	if chara.is_empty() && player && player.character in voice_lines:
		chara = player.character
	
	if chara && chara in voice_lines && voice_line in voice_lines[chara]:
		return voice_lines[chara][voice_line]
	return null


func get_character_names() -> Array:
	var chara_name_arr: Array = []
	for key in suits.keys():
		chara_name_arr.append(key)
	return chara_name_arr


func add_suit(suit: PlayerSuit, power: String, character: String, override: bool = false) -> void:
	var new_suit_dict: Dictionary = suits.duplicate(true) 
	if !character in new_suit_dict:
		new_suit_dict[character] = {}
	if !override && power in new_suit_dict[character]:
		return
	new_suit_dict[character][power] = suit


func add_suits(dict: Dictionary, character: String, override: bool = false) -> void:
	var new_suit_dict: Dictionary = suits.duplicate(true)
	if !character in new_suit_dict:
		new_suit_dict[character] = {}
	new_suit_dict[character].merge(dict, override)
	suits = new_suit_dict


func add_voice_lines(dict: Dictionary, character: String, override: bool = false) -> void:
	var new_voice_dict: Dictionary = voice_lines.duplicate(true)
	if !character in new_voice_dict:
		new_voice_dict[character] = {}
	new_voice_dict[character].merge(dict, override)
	voice_lines = new_voice_dict
