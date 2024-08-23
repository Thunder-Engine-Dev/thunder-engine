extends StaticBumpingBlock

@export var change_to_suit: PlayerSuit = preload("res://engine/objects/players/prefabs/suits/mario/suit_mario_small.tres")

func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()


func _physics_process(delta):
	super(delta)
	if active && Thunder._current_player.suit.type == PlayerSuit.Type.SMALL:
		active = false
		_animated_sprite_2d.animation = &"empty"
	elif !active && Thunder._current_player.suit.type > PlayerSuit.Type.SMALL:
		active = true
		_animated_sprite_2d.animation = &"default"


func got_bumped(by: Node2D) -> void:
	if _triggered: return
	call_bump()


func call_bump() -> void:
	bump(false)
	if !active: return
	_animated_sprite_2d.animation = &"empty"
	Thunder._current_player.change_suit(change_to_suit, false)
	Data.values.lives = ProjectSettings.get_setting(&"application/thunder_settings/player/default_lives", 4)
