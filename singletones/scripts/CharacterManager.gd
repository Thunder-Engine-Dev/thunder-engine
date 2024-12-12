extends Node

## This Dictionary contains all suits for all characters available in the game.
## To add your own suits and characters, use the "add_suits" method in an autoload script inside of your project.
## The dictionary is stored like this:
##   (list of power names) => dictionary of character names => suit resources
## i.e. "suits.Mario.small" returns a PlayerSuit of small Mario.
var suits: Dictionary = {}
## Contains all voice lines for all characters in the game.
## Add new ones with "add_voice_line" method.
var voice_lines: Dictionary = {}
## Miscelleneous textures for all characters, like the menu player head selector.
## Add new ones with "add_misc_texture" method.
var misc_textures: Dictionary = {}

## Base suits for Mario
const MARIO_SUITS: Dictionary = {
	"small": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres"),
	"super": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_super.tres"),
	"fireball": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_fireball.tres"),
	"beetroot": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_beetroot.tres"),
	"green_lui": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_green_lui.tres"),
	"iceball": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_iceball.tres"),
	"boomerang": preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_boomerang.tres"),
}
## Base suits for Luigi
const LUIGI_SUITS: Dictionary = {
	"small": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_small.tres"),
	"super": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_super.tres"),
	"fireball": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_fireball.tres"),
	"beetroot": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_beetroot.tres"),
	"green_lui": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_green_lui.tres"),
	"iceball": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_iceball.tres"),
	"boomerang": preload("res://engine/objects/players/prefabs/suits/luigi/suit_luigi_boomerang.tres"),
}

## Base voice lines for Mario
const MARIO_VOICE_LINES: Dictionary = {
	"checkpoint": [
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_1.ogg"),
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_2.ogg"),
		preload("res://engine/objects/players/prefabs/sounds/mario/checkpoint_3.ogg"),
	],
	"oh_no": [
		preload("res://engine/objects/players/prefabs/sounds/mario/oh_no.wav")
	],
	"fall": [
		preload("res://engine/objects/players/prefabs/sounds/mario/uwaah.wav")
	],
	"jump": null,
	"swim": null,
	"hurt": null,
	"death": null,
}
## Base voice lines for Luigi
const LUIGI_VOICE_LINES: Dictionary = {
	"checkpoint": [
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_1.wav"),
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_2.wav"),
		preload("res://engine/objects/players/prefabs/sounds/luigi/checkpoint_3.wav"),
	],
	"oh_no": [
		preload("res://engine/objects/players/prefabs/sounds/luigi/oh_no.wav")
		],
	"fall": [
		preload("res://engine/objects/players/prefabs/sounds/luigi/uwaah.wav")
	],
	"jump": null,
	"swim": null,
	"hurt": null,
	"death": null,
}

const DEFAULT_STORY_TEXT = ["they", "them", "the intrepid and determined plumber"]

func _ready() -> void:
	add_suits(MARIO_SUITS, "Mario")
	add_suits(LUIGI_SUITS, "Luigi")
	add_voice_lines(MARIO_VOICE_LINES, "Mario")
	add_voice_lines(LUIGI_VOICE_LINES, "Luigi")
	add_misc_texture(preload("res://engine/objects/players/prefabs/animations/mario/selector.tres"), "selector", "Mario")
	add_misc_texture(preload("res://engine/objects/players/prefabs/animations/luigi/selector.tres"), "selector", "Luigi")
	add_misc_texture(preload("res://engine/scenes/map/textures/mario_icon.png"), "map_icon", "Mario")
	add_misc_texture(preload("res://engine/scenes/map/textures/luigi_icon.png"), "map_icon", "Luigi")
	add_misc_texture(preload("res://engine/objects/players/prefabs/textures/mario/mario_dead.png"), "death", "Mario")
	add_misc_texture(preload("res://engine/objects/players/prefabs/textures/luigi/luigi_dead.png"), "death", "Luigi")


func get_character_name() -> String:
	return SettingsManager.settings.character


func get_character_display_name() -> String:
	var character: String = SkinsManager.custom_nicknames.get(SkinsManager.current_skin, "")
	if character.is_empty():
		character = SettingsManager.settings.character
	return character


func get_character_story_text(index: int) -> String:
	var text: Array = SkinsManager.custom_story_text.get(SkinsManager.current_skin, "")
	if text.is_empty():
		text = DEFAULT_STORY_TEXT.duplicate()
		text[0] = "he"
		text[1] = "him"
	return text[index]


func get_suit(suit_name: String, character_name: String = "") -> PlayerSuit:
	return _get_something(suit_name, character_name, suits, {})


func get_suit_names(character_name: String = "") -> Array:
	var chara: String = character_name
	if chara.is_empty(): chara = SettingsManager.settings.character
	
	var suit_name_arr: Array = []
	if chara && chara in suits:
		for key in suits[chara].keys():
			suit_name_arr.append(key)
	return suit_name_arr


func get_voice_line(voice_line: String, character_name: String = "", skinned: bool = true) -> Variant:
	var skinned_dict = {}
	if skinned:
		skinned_dict = SkinsManager.misc_sounds
	return _get_something(voice_line, character_name, voice_lines, skinned_dict)


func get_misc_texture(texture_name: String, character_name: String = "", skinned: bool = true) -> Variant:
	var skinned_dict = SkinsManager.misc_textures if skinned else {}
	return _get_something(texture_name, character_name, misc_textures, skinned_dict)


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


func add_misc_texture(texture: Variant, texture_name: String, character: String, override: bool = false) -> void:
	var new_texture_dict: Dictionary = misc_textures.duplicate(true)
	if !character in new_texture_dict:
		new_texture_dict[character] = {}
	if !override && texture_name in new_texture_dict[character]:
		return
	new_texture_dict[character][texture_name] = texture
	misc_textures = new_texture_dict


func _get_something(what: String, character_name: String, dict_ref: Dictionary, skinned_dict: Dictionary = {}) -> Variant:
	var chara: String = character_name
	if chara.is_empty(): chara = SettingsManager.settings.character
	
	if chara && chara in dict_ref && what in dict_ref[chara]:
		if skinned_dict && what in skinned_dict.get(SkinsManager.current_skin, ""):
			return skinned_dict[SkinsManager.current_skin][what]
		return dict_ref[chara][what]
	return null
