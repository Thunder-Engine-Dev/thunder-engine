extends InstanceNode2D
class_name InstancePowerup

@export_category("InstanceNode2D")
@export_group("Creation","creation_")
@export var creation_fallback_node: PackedScene


func prepare() -> Variant:
	# Duplicate self to avoid overwriting bugs
	var d_self = self.duplicate()
	
	if !creation_nodepack: return d_self
	
	if (
		creation_fallback_node &&
		creation_nodepack.resource_path != creation_fallback_node.resource_path &&
		Thunder._current_player_state.player_power == Data.PLAYER_POWER.SMALL
	):
		d_self.creation_nodepack = creation_fallback_node
	
	return d_self
