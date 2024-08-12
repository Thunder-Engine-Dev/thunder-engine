extends Resource
class_name PlayerSkin

@export var name: StringName = &"small"
@export var animation_speeds: Dictionary = {
	"appear": 30,
	"attack": 10,
	"climb": 0,
	"crouch": 0,
	"default": 0,
	"jump": 0,
	"slide": 0,
	"swim": 8,
	"walk": 6,
	"warp": 0,
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
	"climb": [
		Rect2(0, 0, 32, 64),
	],
	"crouch": [
		Rect2(0, 0, 32, 64),
	],
	"default": [
		Rect2(0, 0, 32, 64),
	],
	"jump": [
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
}
@export var animation_loops: Dictionary = {
	"appear": true,
	"attack": false,
	"climb": false,
	"crouch": false,
	"default": false,
	"jump": false,
	"slide": false,
	"swim": true,
	"walk": true,
	"warp": true,
}
