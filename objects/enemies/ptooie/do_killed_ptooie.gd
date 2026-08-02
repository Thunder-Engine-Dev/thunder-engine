extends ByNodeScript

var dir: int
var enemy_attacked: Node
var attacker_speed: Vector2


func _ready() -> void:
	enemy_attacked = vars.enemy_attacked as Node
	
	if !enemy_attacked: return
	var spikeball: NodePath = vars.spikeball as NodePath
	var spk = enemy_attacked.get_node_or_null(spikeball)
	if spk:
		spk.independence()
	
	var is_fast_quality = SettingsManager.settings.quality == SettingsManager.QUALITY.MIN
	if &"fast_death_effect" in vars && vars.fast_death_effect:
		if is_fast_quality:
			return
	
	if enemy_attacked.has_meta(&"attacker_speed"):
		attacker_speed = enemy_attacked.get_meta(&"attacker_speed")
	var death: NodePath = vars.death as NodePath
	var speed: Vector2 = vars.death_speed as Vector2
	var min_quality_offset: Vector2 = vars.get("min_quality_offset", Vector2.ZERO)
	
	if death.is_empty(): return
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	if !attacker_speed:
		attacker_speed = Vector2.ZERO
	
	death_node.visible = true
	death_node.set(&"speed_scale", 0)
	for i in death_node.get_children():
		if i is AnimatedSprite2D:
			i.set(&"speed_scale", 0)
	if attacker_speed != Vector2.ZERO && node is GravityBody2D:
		if is_fast_quality:
			death_node.position -= min_quality_offset
		fancy_death_effect()
	else:
		if node is GravityBody2D: 
			node.speed = speed
			if is_fast_quality:
				death_node.position -= min_quality_offset
			var root = enemy_attacked._center
			if root:
				node.gravity_dir = root.gravity_dir
	node.add_child(death_node)


func fancy_death_effect() -> void:
	dir = sign(attacker_speed.x)
	node.speed.x *= dir
	if &"rotating_dir" in node:
		node.rotating_dir = dir
	
