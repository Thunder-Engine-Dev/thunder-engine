extends Area2D

const ICE_2 = preload("../sounds/ice2.wav")
const DEBRIS_EFFECT = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")

var THWOMP_ICICLE = load("res://engine/objects/enemies/thwomp/thwomp_icicle.tscn")

@export var stunning_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/stun.wav")
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")

@onready var left_explosion: Marker2D = $LeftExplosion
@onready var right_explosion: Marker2D = $RightExplosion
@onready var sprite_2d: Sprite2D = $Sprite2D

@onready var obstacle: Area2D = $Obstacle
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var body: Area2D = $Body

var dir: int = 1
var go_on: bool = false
var to_bump: Array[Node2D]
var ooawel: bool

func _ready() -> void:
	(func():
		visible = false
		for i in 2:
			await get_tree().physics_frame
		
		for i in get_overlapping_bodies():
			go_on = true
			if i.has_method(&"got_bumped"):
				to_bump.append(i)
		for i in get_overlapping_areas():
			go_on = true
			if i.has_method(&"got_bumped"):
				to_bump.append(i)
		for i in obstacle.get_overlapping_bodies():
			go_on = false
		if go_on:
			visible = true
			body.scale = Vector2(0.02, 0.02)
			enemy_attacked.stomping_enabled = true
		else:
			queue_free()
			return
	).call_deferred()
	

func _physics_process(delta: float) -> void:
	var rect: float = sprite_2d.region_rect.position.y
	if rect > 0.0:
		sprite_2d.region_rect.position.y -= 200 * delta
		if sprite_2d.region_rect.position.y < 0.0:
			sprite_2d.region_rect.position.y = 0.0
	elif !ooawel:
		ooawel = true
		sprite_2d.region_rect.position.y = 0.0
		
		await get_tree().create_timer(0.2, false, false, false).timeout
		Audio.play_sound(ICE_2, self)
		_explosion()
		queue_free()
		for i in to_bump:
			if is_instance_valid(i):
				i.got_bumped.call_deferred(false)
		return
	
	if go_on && body.scale.y < 1.0:
		body.scale += Vector2.ONE * 3 * delta
		if body.scale.y > 1.0:
			body.scale = Vector2.ONE


func _explosion() -> void:
	#NodeCreator.prepare_2d(explosion_effect, self) \
	#	.bind_global_transform(left_explosion.position).create_2d()
	NodeCreator.prepare_2d(explosion_effect, self) \
		.bind_global_transform(right_explosion.position).create_2d()
	var speeds: Array[Vector2] = [Vector2(2, -6), Vector2(4, -7), Vector2(-2, -6), Vector2(-4, -7)]
	for i in speeds:
		NodeCreator.prepare_2d(DEBRIS_EFFECT, self) \
			.bind_global_transform(right_explosion.position).create_2d(true).call_method(func(eff: Node2D):
				eff.texture = preload("res://engine/objects/enemies/icicle/textures/icicle_debris.png")
				eff.velocity = i
		)


func _on_timer_timeout() -> void:
	NodeCreator.prepare_2d(THWOMP_ICICLE, self) \
		.bind_global_transform(Vector2(32, 0) * dir).create_2d(true).call_method(func(eff):
		eff.dir = dir
		)
