class_name BowserAttack
extends Node

signal start
signal middle
signal end

var bowser: CharacterBody2D

## NOT FOR OVERRIDING
func _accept_attack(node: CharacterBody2D) -> void:
	bowser = node
	start_attack()


## Extend this.
func start_attack() -> void:
	start.emit()


## Extend this. Use this to create projectiles
func middle_attack() -> void:
	middle.emit()


## Extend this.
func end_attack() -> void:
	bowser._attacking = false
	if bowser.tween_status && !bowser.tween_status.is_running(): 
		bowser.tween_status.play()
	end.emit()
