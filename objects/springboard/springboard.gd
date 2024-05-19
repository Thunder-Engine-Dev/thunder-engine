extends GeneralMovementBody2D

@export var spring_jump_height: float = 1000

@onready var enemy_attacked: Node = $Body/EnemyAttacked

@onready var animation_node: Node2D = $Node2D
@onready var marker: Node2D = $Node2D/Marker2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Node2D/Timer

var is_better: bool
var is_triggered: bool
var is_playing_backwards: bool
var is_higher: bool
var player: Player

func _ready() -> void:
	if SettingsManager.get_tweak("better_springboards"):
		is_better = true
		var spr = get_node(sprite) as AnimatedSprite2D
		spr.visible = false
		animation_node.visible = true
		animation_player.animation_finished.connect(_animation_finished)
		timer.timeout.connect(func():
			enemy_attacked.stomping_enabled = true
			print("stomping enabled")
		)
		return
	
	animation_node.queue_free()


func _physics_process(delta: float) -> void:
	if !is_triggered: return
	if player:
		player.no_movement = true
		player.global_position.y = marker.global_position.y - 16
		player.sprite.set_animation("default")


func trigger() -> void:
	if !is_better:
		var spr = get_node(sprite) as AnimatedSprite2D
		spr.play(&"default")
		spr.frame = 0
		return
	
	if !timer.is_stopped(): return
	if is_triggered: return
	timer.start()
	print("stomping disabled..")
	enemy_attacked.stomping_enabled = false
	animation_player.play(&"jump")
	player = Thunder._current_player
	#if player.global_position.y < marker.global_position.y + 8:
	is_triggered = true


func _animation_finished(anim: String) -> void:
	if !is_triggered: return
	if !is_playing_backwards:
		animation_player.play(&"jump", -1, -2.0, true)
		is_playing_backwards = true
	else:
		is_playing_backwards = false
		is_triggered = false
		if player:
			player.no_movement = false
			player.speed.y = -spring_jump_height if is_higher else -enemy_attacked.stomping_player_jumping_min
			player = null
		is_higher = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("m_jump"):
		if is_better:
			if is_triggered:
				is_higher = true
				print("higher!!")
			return
		enemy_attacked.stomping_player_jumping_max = spring_jump_height
		await get_tree().create_timer(0.1).timeout
		enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
