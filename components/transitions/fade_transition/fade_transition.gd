extends Transition

@export var animation_name: String = "to_white"

var paused: bool = false
var speed_closing: float = 2.0
var speed_opening: float = -2.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	name = "fade_transition"
	start.emit()
	animation_player.play(animation_name)
	animation_player.speed_scale = -speed_opening
	animation_player.animation_finished.connect(_end_transition,
		CONNECT_ONE_SHOT
	)

## Sets the center of transition on some node
func on(ref: Variant, direct = false, unpause = false) -> Transition:
	return self


## Sets the speeds
func with_speeds(s_closing: float, s_opening: float) -> Transition:
	speed_closing = s_closing
	speed_opening = s_opening
	return self


func with_animation(anim: String) -> Transition:
	animation_name = anim
	return self


func _end_transition(anim_name: StringName) -> void:
	middle.emit()
	animation_player.play_backwards.call_deferred(animation_name)
	animation_player.speed_scale = speed_closing
	animation_player.animation_finished.connect(
		_transition_ended,
		CONNECT_ONE_SHOT
	)


func _transition_ended(anim_name: StringName) -> void:
	end.emit()


func _physics_process(delta: float) -> void:
	if paused && animation_player.is_playing():
		animation_player.pause()
		return
	if !paused && !animation_player.is_playing():
		animation_player.play()
