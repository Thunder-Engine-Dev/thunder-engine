extends Node

func _init(a, vars) -> void:
	owner = a

func _on_attack_custom_signal(attack_type: String):
	if attack_type != "bumping_block": return
	
	owner.velocity.y = -200
	owner.sprite.flip_v = true
