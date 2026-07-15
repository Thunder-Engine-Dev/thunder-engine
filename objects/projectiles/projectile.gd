extends GeneralMovementBody2D
class_name Projectile

## Base class for projectiles with off-screen cleanup on spawn and while in flight.

## Who fired the projectile. Used to pick off-screen removal rules from the
## [code]player[/code] / [code]enemy[/code] entries in the removal dictionaries.
@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER

@export_group("Off-screen removing", "remove_offscreen")
## Seconds to wait before removing a projectile that spawned off-screen.[br]
@export var remove_offscreen_after_sec_creation: Dictionary[String, float] = {
	"player": 2.0,
	"enemy": 2.0
}
## Seconds a projectile may stay off-screen after leaving the viewport before
## it is removed.[br]
## Set a value to [code]0.0[/code]
## to disable tracking removal for that owner.
@export var remove_offscreen_after_sec_tracking: Dictionary[String, float] = {
	"player": 0.0,
	"enemy": 2.0
}
## Vertical screen margin in pixels for enemy projectiles on spawn.[br]
## If the projectile is above the top of the viewport beyond this offset when
## created, it is removed immediately.
@export var remove_offscreen_offset_px_creation_enemy: float = 32.0
## Vertical screen margin in pixels for player projectiles while off-screen
## tracking is active.[br]
## If the projectile is above the top edge of the viewport (screen [code]y <= 0[/code]),
## still between the left and right screen edges, and not higher than this offset,
## off-screen removal is paused: [member _offscreen_elapsed] is not increased and the
## projectile is not removed.
## Set to [code]0.0[/code] to disable this grace zone.
@export var remove_offscreen_offset_px_tracking_player: float = 640.0

## If [code]false[/code], [method offscreen_handler_process] is not connected and
## off-screen tracking removal is disabled. Override in subclass [method _ready]
## before calling [code]super()[/code].
var remove_offscreen_tracking_enabled: bool = true

var _offscreen_elapsed: float = 0.0
var _offscreen_tracking: bool = false


func _ready() -> void:
	_offscreen_handler_creation()
	add_to_group(&"end_level_sequence")
	_setup_offscreen_handler_process()
	super()


#func _exit_tree_offscreen_listener() -> void:
	#var tree := get_tree()
	#if is_instance_valid(tree) && tree.physics_frame.is_connected(offscreen_handler_process):
		#tree.physics_frame.disconnect(offscreen_handler_process)


## ABSTRACT METHOD
func _on_level_end() -> void:
	pass


func _offscreen_handler_creation() -> void:
	assert(vis_notifier_node, "Please set up Vision Path in the inspector for the projectile")
	await get_tree().physics_frame
	if !is_inside_tree():
		return
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		# Delete projectile if shot by enemy from the top
		Thunder.view.cam_border()
		if !Thunder.view.screen_top(global_position, remove_offscreen_offset_px_creation_enemy, true):
			queue_free()
		# Delete projectile if shot by enemy off-screen
		elif !vis_notifier_node.is_on_screen():
			await get_tree().create_timer(remove_offscreen_after_sec_creation["enemy"], false).timeout
			if is_inside_tree() && !vis_notifier_node.is_on_screen():
				queue_free()
	# Delete projectile shot by player off-screen if it's there for too long
	elif !vis_notifier_node.is_on_screen():
		await get_tree().create_timer(remove_offscreen_after_sec_creation["player"], false).timeout
		if is_inside_tree() && !vis_notifier_node.is_on_screen():
			queue_free()


func _setup_offscreen_handler_process() -> void:
	if !remove_offscreen_tracking_enabled:
		return
	assert(vis_notifier_node, "Please set up Vision Path in the inspector for the projectile")
	vis_notifier_node.screen_exited.connect(_on_offscreen_notifier_exited)
	vis_notifier_node.screen_entered.connect(_on_offscreen_notifier_entered)
	get_tree().physics_frame.connect(offscreen_handler_process)
	#tree_exiting.connect(_exit_tree_offscreen_listener)


func _on_offscreen_notifier_exited() -> void:
	_offscreen_tracking = true
	_offscreen_elapsed = 0.0


func _on_offscreen_notifier_entered() -> void:
	_offscreen_tracking = false
	_offscreen_elapsed = 0.0


func _is_offscreen_tracking_grace_zone() -> bool:
	if belongs_to != Data.PROJECTILE_BELONGS.PLAYER:
		return false
	if remove_offscreen_offset_px_tracking_player <= 0.0:
		return false
	if !vis_notifier_node || vis_notifier_node.is_on_screen():
		return false
	
	Thunder.view.cam_border()
	var offset := remove_offscreen_offset_px_tracking_player
	var screen_pos := Thunder.view.target_trans * global_position
	# screen_top alone is true below the viewport too (any y > -offset); grace is only
	# the band above the top edge: (-offset, 0] in screen space.
	return (
		screen_pos.y > -offset &&
		screen_pos.y <= 0.0 &&
		Thunder.view.screen_left(global_position, 0.0, true) &&
		Thunder.view.screen_right(global_position, 0.0, true)
	)


func offscreen_handler_process() -> void:
	if !remove_offscreen_tracking_enabled:
		return
	var dictionary_key = "player" if belongs_to == Data.PROJECTILE_BELONGS.PLAYER else "enemy"
	if !is_inside_tree() || !_offscreen_tracking || !vis_notifier_node:
		return
	if _is_offscreen_tracking_grace_zone():
		return
	if (get_tree().paused || process_mode == Node.PROCESS_MODE_DISABLED) && process_mode != Node.PROCESS_MODE_ALWAYS:
		return
	
	_offscreen_elapsed += get_physics_process_delta_time()
	var tracking_delay: float = remove_offscreen_after_sec_tracking.get(dictionary_key, 0.0)
	if _offscreen_elapsed >= tracking_delay && !vis_notifier_node.is_on_screen():
		queue_free()
