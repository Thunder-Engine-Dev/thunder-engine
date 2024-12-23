extends Resource
class_name PlayerSkin

@export var name: StringName = &"small"
@export var animation_speeds: Dictionary = {
	"appear": 30,
	"attack": 10,
	"attack_air": 15,
	"back": 0,
	"climb": 0,
	"crouch": 0,
	"default": 0,
	"fall": 0,
	"grab": 5,
	"hold_crouch": 0,
	"hold_default": 0,
	"hold_fall": 0,
	"hold_jump": 0,
	"hold_walk": 6,
	"jump": 0,
	"kick": 4,
	"skid": 0,
	"slide": 0,
	"swim": 8,
	"walk": 6,
	"warp": 0,
	"win": 0,
}
@export var animation_regions: Dictionary = {
	"appear": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
	],
	"attack": [
		Rect2(0, 0, 32, 64),
	],
	"attack_air": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
	],
	"back": [
		Rect2(0, 0, 32, 64),
	],
	"climb": [
		Rect2(0, 0, 32, 64),
	],
	"crouch": [
		Rect2(0, 0, 32, 64),
	],
	"default": [
		Rect2(0, 0, 32, 64),
	],
	"fall": [
		Rect2(0, 0, 32, 64),
	],
	"grab": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
	],
	"hold_crouch": [
		Rect2(0, 0, 32, 64),
	],
	"hold_default": [
		Rect2(0, 0, 32, 64),
	],
	"hold_fall": [
		Rect2(0, 0, 32, 64),
	],
	"hold_jump": [
		Rect2(0, 0, 32, 64),
	],
	"hold_walk": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
	],
	"jump": [
		Rect2(0, 0, 32, 64),
	],
	"kick": [
		Rect2(0, 0, 32, 64),
	],
	"skid": [
		Rect2(0, 0, 32, 64),
	],
	"slide": [
		Rect2(0, 0, 32, 64),
	],
	"swim": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
		Rect2(96, 0, 32, 64),
		Rect2(128, 0, 32, 64),
	],
	"walk": [
		Rect2(0, 0, 32, 64),
		Rect2(32, 0, 32, 64),
		Rect2(64, 0, 32, 64),
	],
	"warp": [
		Rect2(0, 0, 32, 64),
	],
	"win": [
		Rect2(0, 0, 32, 64),
	],
}
@export var animation_loops: Dictionary = {
	"appear": true,
	"attack": false,
	"attack_air": false,
	"back": false,
	"climb": false,
	"crouch": false,
	"default": false,
	"fall": false,
	"grab": false,
	"hold_crouch": false,
	"hold_default": false,
	"hold_fall": false,
	"hold_jump": false,
	"hold_walk": true,
	"jump": false,
	"kick": false,
	"skid": false,
	"slide": false,
	"swim": true,
	"walk": true,
	"warp": true,
	"win": true,
}
@export var animation_durations: Dictionary = {
	
}
