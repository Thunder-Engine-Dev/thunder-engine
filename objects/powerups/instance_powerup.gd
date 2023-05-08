extends InstanceNode2D
class_name InstancePowerup

const NON_FALLBACKS: Array[PackedScene] = [
	preload("res://engine/objects/items/coin/coin.tscn")
]

@export_category("InstanceNode2D")
@export_group("Creation","creation_")
@export var creation_fallback_node: PackedScene


func prepare() -> Variant:
	# Duplicate self to avoid overwriting bugs
	var d_self = self.duplicate()
	
	if !creation_nodepack: return d_self
	
	if (
		!d_self.creation_nodepack in NON_FALLBACKS &&
		d_self.creation_fallback_node &&
		d_self.creation_nodepack.resource_path != d_self.creation_fallback_node.resource_path &&
		Thunder.is_player_power(Data.PLAYER_POWER.SMALL)
	):
		d_self.creation_nodepack = d_self.creation_fallback_node
	
	return d_self
