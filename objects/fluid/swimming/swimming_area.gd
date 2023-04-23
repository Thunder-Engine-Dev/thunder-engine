extends Area2D

var swimming_script

@onready var player: Player = Thunder._current_player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if "swim" in player.movements:
		return
	
	swimming_script = preload("./movement_swim.gd").new()
	player.movements.swim = swimming_script._movement_swim

func _physics_process(delta: float) -> void:
	if overlaps_body(player):
		player.states.set_state("swim")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.states.set_state("swim")
		
		if !swimming_script: return
		swimming_script.store_config()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.states.set_state("default")
		
		if !swimming_script: return
		swimming_script.load_config()
