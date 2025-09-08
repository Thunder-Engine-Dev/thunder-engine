extends ByNodeScript

var dir: int
var enemy_attacked: Node
var attacker_speed: Vector2


func _ready() -> void:
	enemy_attacked = vars.enemy_attacked as Node
	var is_fast_quality: bool = SettingsManager.settings.quality == SettingsManager.QUALITY.MIN
	if &"fast_death_effect" in vars && vars.fast_death_effect:
		if is_fast_quality:
			return
	
	if !enemy_attacked: return
	if enemy_attacked.has_meta(&"attacker_speed"):
		attacker_speed = enemy_attacked.get_meta(&"attacker_speed")
	var death: NodePath = vars.death as NodePath
	var speed: Vector2 = vars.death_speed as Vector2
	var gravity_scale: float = vars.gravity_scale if "gravity_scale" in vars else 0.5
	var max_falling_speed: float = vars.max_falling_speed if "max_falling_speed" in vars else 1000
	var min_quality_offset: Vector2 = vars.get("min_quality_offset", Vector2.ZERO)
	
	if death.is_empty(): return
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	if !attacker_speed:
		attacker_speed = Vector2.ZERO
	
	death_node.visible = true
	death_node.set(&"speed_scale", 0)
	if attacker_speed != Vector2.ZERO && node is GravityBody2D:
		node.speed.y *= 2 * gravity_scale
		node.gravity_scale = gravity_scale
		node.max_falling_speed = max_falling_speed
		if is_fast_quality:
			death_node.offset -= min_quality_offset
		fancy_death_effect()
	else:
		if node is GravityBody2D:
			node.speed = speed
			node.speed.y *= 2 * gravity_scale
			node.gravity_scale = gravity_scale
			node.max_falling_speed = max_falling_speed
			if is_fast_quality:
				death_node.offset -= min_quality_offset
			var root := enemy_attacked.get_parent().get_parent() as GravityBody2D
			if root:
				node.gravity_dir = root.gravity_dir
	node.add_child(death_node)


func fancy_death_effect() -> void:
	dir = sign(attacker_speed.x)
	node.speed.x *= dir
	if &"rotating_dir" in node:
		node.rotating_dir = dir
	
