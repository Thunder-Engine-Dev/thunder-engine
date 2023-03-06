# Create a Node2D with physics and some other parameters
extends Resource
class_name InstanceNode2D

@export_category("InstanceNode2D")
@export_group("Creation","creation_")
@export var creation_nodepack: PackedScene
@export_group("Transform","trans_")
@export var trans_offset: Vector2
@export_flags("inherit_rotation","inherit_scale","inherit_skew") var trans_inheritances: int
@export var trans_rotation: float
@export var trans_scale: Vector2 = Vector2.ONE
@export var trans_skew: float
@export_group("Visibility","visi_")
@export var visi_z_index: int
@export var visi_z_as_relative: bool = true
@export var visi_y_sort_enabled: bool
@export_group("Extension")
@export var custom_vars: Dictionary
@export var custom_script: GDScript


func _report_resource() -> void:
	printerr("[Report] The error happened on: " + str(get_rid()) + ", with path:" + resource_path)
