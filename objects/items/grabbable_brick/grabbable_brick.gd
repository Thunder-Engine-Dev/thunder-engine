extends GeneralMovementBody2D

const SMOKE = preload("res://engine/objects/effects/smoke/smoke.tscn")
const debris_effect = preload("res://engine/objects/effects/brick_debris/grabbable_brick_debris.tscn")

@export var breaking_speed: float = 100
@export var break_sound = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")
@export var grab_timeout_sec: float = 6.0

var activated: bool
var flasher: Tween
var old_z_index: int

@onready var _attack: ShapeCast2D = $Attack
@onready var _timer_destroy: Timer = $TimerDestroy
@onready var _timer_destroy_flash: Timer = $TimerDestroyFlash
@onready var _visible_on_screen: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _physics_process(delta: float) -> void:
	if !activated: return
	
	super(delta)
	
	if absf(speed_previous.x) > breaking_speed && is_on_wall():
		break_object()
	if speed_previous.y < 0 && is_on_ceiling():
		break_object()
	if absf(speed.x) < breaking_speed && is_on_floor():
		break_object()


func break_object() -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		return
	
	for i in get_slide_collision_count():
		var j: KinematicCollision2D = get_slide_collision(i)
		var collider = j.get_collider()
		if collider is StaticBumpingBlock:
			if collider.has_method(&"got_bumped"):
				collider.got_bumped.call_deferred(false)
			elif collider.has_method(&"bricks_break"):
				collider.bricks_break.call_deferred()
	
	Audio.play_sound(break_sound, self)
	if _visible_on_screen.is_on_screen():
		var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
		for i in speeds:
			NodeCreator.prepare_2d(debris_effect, self).create_2d(true).call_method(func(eff: Node2D):
				eff.global_transform = global_transform
				eff.velocity = i
			)
		
	Data.add_score(10)
	queue_free()


func reset_timers() -> void:
	_timer_destroy.paused = true
	_timer_destroy_flash.paused = true
	sprite_node.modulate.a = 1
	if flasher: flasher.kill()

func _on_grab_initiated() -> void:
	disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE
	reset_timers()


func _on_ungrabbed() -> void:
	z_index = old_z_index
	_attack.enabled = true
	activated = true
	reset_timers()


func _on_grabbed() -> void:
	old_z_index = z_index
	z_index = 1
	_timer_destroy_flash.paused = true
	if grab_timeout_sec > 1.5:
		_timer_destroy.paused = false
		_timer_destroy.start(grab_timeout_sec - 1.5)
	else:
		_timer_destroy_flash.start(grab_timeout_sec)
	activated = false
	sprite_node.play()
	_attack.enabled = false


func _on_timer_destroy_timeout() -> void:
	_timer_destroy_flash.paused = false
	_timer_destroy_flash.start(1.5)
	flasher = Effect.flash(sprite_node, 1.5, 0.06)


func _on_timer_destroy_flash_timeout() -> void:
	queue_free()
	var pl = Thunder._current_player
	if is_instance_valid(pl):
		pl.is_holding = false
		pl.holding_item = null
	var sm = SMOKE.instantiate()
	Scenes.current_scene.add_child(sm)
	sm.global_transform = global_transform
	sm.reset_physics_interpolation()
