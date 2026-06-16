extends "res://engine/objects/enemies/hammer_bros/hammer_bro_base.gd"

@export var goomba_limit: int = 4

func _on_attack_timeout() -> void:
	if get_tree().get_node_count_in_group(&"%s_spawn" % [name]) >= goomba_limit:
		_step_attacking = 0
		timer_attack.start(attacking_count_unit)
	
	match _step_attacking:
		# Detection for attack
		0:
			if !Thunder.view.is_getting_closer(self, 32):
				return
			var chance: float = Thunder.rng.get_randf()
			var random_delay: int = floori(log(chance) / log(1 - attacking_chance))
			_step_attacking = -1
			timer_attack.start(random_delay * attacking_count_unit)
			timer_attack.one_shot = true
		# Delaying the attack
		-1:
			_step_attacking = 1
			timer_attack.start(attacking_delay)
		# Attack
		1:
			_step_attacking = 0
			timer_attack.start(attacking_count_unit)
			NodeCreator.prepare_ins_2d(projectile, self).call_method(
				func(proj: Node2D) -> void:
					proj.set(&"belongs_to", Data.PROJECTILE_BELONGS.ENEMY)
					proj.add_to_group(&"%s_spawn" % [name])
			).execute_instance_script({bro = self}).create_2d().bind_global_transform(pos_attack.position)
			Audio.play_sound(sound, self, false)
