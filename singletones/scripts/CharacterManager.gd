extends Node

## This Dictionary contains all suits for all characters available in the game.
## To add your own suits and characters, use the "add_suits" method in an autoload script inside of your project.
## The dictionary is stored like this:
##   (list of power names) => dictionary of character names => suit resources
## i.e. "suits.Mario.small" returns a PlayerSuit of small Mario.
var suits: Dictionary = {}

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

func _ready() -> void:
	add_suits(MARIO_SUITS, "Mario")
	add_suits(LUIGI_SUITS, "Luigi")
	print(suits)


func get_suit(suit_name: String) -> PlayerSuit:
	var player = Thunder._current_player
	if player && player.character in suits && suit_name in suits[player.character]:
		return suits[player.character][suit_name]
	return null


func add_suits(dict: Dictionary, character: String, override: bool = false) -> void:
	var new_suit_dict: Dictionary = suits.duplicate(true)
	if !character in new_suit_dict:
		new_suit_dict[character] = {}
	new_suit_dict[character].merge(dict, override)
	suits = new_suit_dict
