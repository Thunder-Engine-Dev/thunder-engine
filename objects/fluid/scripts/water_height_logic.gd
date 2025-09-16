extends Node2D

const WATER_SFX = preload("res://engine/objects/fluid/sounds/wodapodnosz.wav")

@export_node_path() var water_path: NodePath = ^"../Water"

var water
var water_pos: float

func _ready():
	water = get_node_or_null(water_path)
	assert(water, name + ": Water scene not found.")
	water_pos = water.position.y

func _physics_process(delta):
	if !water: return
	water.position.y = move_toward(water.position.y, water_pos, delta * 50)

func set_water_height(by: float) -> void:
	Audio.play_1d_sound(WATER_SFX)
	water_pos += by
	
