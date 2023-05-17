extends Area2D

var bowser: Node2D


func _ready() -> void:
	$Text.queue_free()
	
	body_entered.connect(
		func(boss: Node2D) -> void:
			if !boss.is_in_group(&"#bowser"): return
			boss.jump_enabled = true
	)
	body_exited.connect(
		func(boss: Node2D) -> void:
			if !boss.is_in_group(&"#bowser"): return
			boss.jump_enabled = false
	)
