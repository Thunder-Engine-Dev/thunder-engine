extends ByNodeScript

## If set on [member Player.holding_item], the default "press attack to throw" path is skipped
## (e.g. [code]grabbing_ungrab_on_attack_release[/code] in [res://engine/node_modifiers/grabbable_modifier/grabbable_modifier.gd]).
const GRAB_SKIP_ATTACK_INPUT_THROW: StringName = &"grabbing_skip_attack_input_throw"

var player: Player
var suit: PlayerSuit

func _ready() -> void:
	player = node as Player
	suit = node.suit
	if !player.died.is_connected(_drop_on_death):
		player.died.connect(_drop_on_death)


func _physics_process(delta: float) -> void:
	if !player || player.warp > Player.Warp.NONE || player.is_climbing:
		return
	
	var item = player.holding_item
	var is_holding = player.is_holding
	
	if !player.attacked:
		return
	
	if player.has_stuck: return
	
	if is_holding && is_instance_valid(item):
		if item.get_meta(GRAB_SKIP_ATTACK_INPUT_THROW, false):
			return
		if item.has_signal(&"grabbing_got_thrown"):
			item.emit_signal(&"grabbing_got_thrown", false)
		player.threw.emit()
		return
	
	var space_state := player.get_world_2d().direct_space_state
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.collision_shape.shape
	query.collision_mask = player.collision_mask
	
	# Side grabbing
	query.transform = player.collision_shape.global_transform.translated(Vector2(player.direction * 2, 0))
	var side_results := space_state.intersect_shape(query)
	
	for result: Dictionary in side_results:
		if !result.get("collider"):
			continue
		var collider: Node2D = result.collider
		if !is_instance_valid(collider) || collider.is_queued_for_deletion():
			continue
		
		var _modifier: NodeModifier = _check_group_and_emit(collider,
			&"#side_grabbable",
			&"grabbing_got_side_grabbed"
		)
		if _modifier:
			player.emit_signal(&"grabbed", true)
			return
	
	# Top grabbing
	query.transform = player.collision_shape.global_transform.translated(Vector2.DOWN)
	var top_results := space_state.intersect_shape(query)
	
	for result: Dictionary in top_results:
		if !result.get("collider"):
			continue
		var collider: Node2D = result.collider
		if !is_instance_valid(collider) || collider.is_queued_for_deletion():
			continue
		
		var _modifier: NodeModifier = _check_group_and_emit(collider,
			&"#top_grabbable",
			&"grabbing_got_top_grabbed"
		)
		if _modifier:
			var skip_grab_animation: bool = _modifier.grabbing_top_lock_method != 2
			player.emit_signal(&"grabbed", skip_grab_animation)
			return


func _check_group_and_emit(collider: Node2D, group: StringName, signal_name: StringName) -> NodeModifier:
	if !collider.is_in_group(group) || !collider.has_meta(&"grabbable_modifier"):
		return null
	var modifier = collider.get_meta(&"grabbable_modifier")
	
	if collider.has_signal(signal_name):
		collider.emit_signal(signal_name)
		return modifier
	
	var colparent = collider.get_parent()
	if colparent.has_signal(signal_name):
		colparent.emit_signal(signal_name)
		return modifier
	
	var colparparent = colparent.get_parent()
	if colparparent.has_signal(signal_name):
		colparparent.emit_signal(signal_name)
		return modifier
	
	return null


func _drop_on_death() -> void:
	var item = player.holding_item
	if is_instance_valid(item):
		item.emit_signal(&"grabbing_got_thrown", true)
		player.threw.emit()
