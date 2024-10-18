extends Label

var target_text: String


func _physics_process(delta: float) -> void:
	visible = Console.player_stats_shown
	if !Console.player_stats_shown: return
	var other_text: String = "PAUSE:" + str(get_tree().paused)

	var pl: Player = Thunder._current_player
	if !pl:
		text = "Player Not Found " + other_text + target_text
		return

	target_text = """
X: %s
Y: %s
SPDX: %s
SPDY: %s
NICK:%s CHAR:%s | lr:%s ud:%s
STUCK:%s SLIDED:%s ISSLIDING:%s
COMPL:%s NOMOVE:%s WARPSTATE:%s
FCWS: %s%s%s%s
ITEM:%s
""" % [
		pl.global_position.x,
		pl.global_position.y,
		pl.speed.x,
		pl.speed.y,
		pl.get("nickname"),
		pl.get("character"),
		pl.get("left_right"),
		pl.get("up_down"),
		pl.get("has_stuck"),
		pl.get("slided"),
		pl.get("is_sliding"),
		pl.get("completed"),
		pl.get("no_movement"),
		pl.get("warp"),
		int(pl.is_on_floor()),
		int(pl.is_on_ceiling()),
		int(pl.is_on_wall()),
		int(pl.is_on_slope()),
		pl.get("holding_item"),
	]
	text = other_text + target_text
