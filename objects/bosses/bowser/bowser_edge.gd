extends Area2D


func _ready() -> void:
	$Text.queue_free()
	
	body_entered.connect(
		func(boss: Node2D) -> void:
			if !boss.is_in_group(&"#bowser"): return
			boss.direction *= -1
	)
