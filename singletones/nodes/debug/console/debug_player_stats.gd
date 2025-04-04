extends Label

var target_text: String


func _physics_process(delta: float) -> void:
	visible = Console.cv.player_stats_shown
	if !Console.cv.player_stats_shown: return
	var other_text: String = "PAUSE:" + str(get_tree().paused) + "
NICK: %s CHAR: %s" % [
		CharacterManager.get_character_display_name(),
		SettingsManager.settings.get("character", ""),
	]

	var pl: Player = Thunder._current_player
	if !pl:
		text = "Player Not Found " + other_text + target_text
		return

	target_text = """
XY: %v
SPD: %v
suit: %s | lr:%s ud:%s
STUCK:%s SLIDED:%s IS_SLIDING:%s
COMPL:%s NOMOVE:%s WARP_STATE:%s
FCWS: %s%s%s%s | Normal: %s
WALL: %s | BUG_SPD: %s
CROUCH: %s | FORCED: %s
ITEM:%s
""" % [
		pl.global_position,
		pl.speed,
		pl.suit.name if pl.get("suit") else null,
		pl.get("left_right"),
		pl.get("up_down"),
		_get_bool_mono(pl, "has_stuck"),
		_get_bool_mono(pl, "slided"),
		_get_bool_mono(pl, "is_sliding"),
		_get_bool_mono(pl, "completed"),
		_get_bool_mono(pl, "no_movement"),
		pl.get("warp"),
		int(pl.is_on_floor()),
		int(pl.is_on_ceiling()),
		int(pl.is_on_wall()),
		int(pl.is_on_slope()),
		rad_to_deg(pl.get_floor_normal().x),
		pl.get_which_wall_collided(),
		pl.get("ghost_speed_y"),
		_get_bool_mono(pl, "is_crouching"),
		_get_bool_mono(pl, "crouch_forced"),
		pl.get("holding_item"),
	]
	text = other_text + target_text

func _get_bool_mono(pl: Player, property: String) -> String:
	var _prop: Variant = pl.get(property)
	return str(_prop) if !_prop else (str(_prop) + " ")
