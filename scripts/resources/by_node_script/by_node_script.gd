extends GDScript
class_name ByNodeScript

var by:Node


func _init(by:Node) -> void:
	if by:
		_instantiated_by(by)
		by.tree_entered.connect(_enter_tree_by.bind(by))
		by.get_tree().process_frame.connect(_process_by.bind(by.get_process_delta_time(),by))
		by.get_tree().physics_frame.connect(_physics_process_by.bind(by.get_physics_process_delta_time(),by))


func _instantiated_by(by:Node) -> void:
	pass

func _enter_tree_by(by:Node) -> void:
	pass

func _exit_tree_by(by:Node) -> void:
	pass

func _process_by(delta:float,by:Node) -> void:
	pass

func _physics_process_by(delta:float,by:Node) -> void:
	pass
