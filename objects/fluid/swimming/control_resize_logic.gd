extends VBoxContainer

## Area will be resized along with this control node
@export_node_path("Area2D") var child_area: NodePath

@onready var area: Area2D = get_node_or_null(child_area)


func _ready() -> void:
	assert(child_area, "[%s]: The child_area node is not set" % get_path())
	
	if !area: return
	
	resized.connect(_set_scale)
	_set_scale()

func _set_scale() -> void:
	area.scale = get_rect().size
	area.position = make_canvas_position_local(get_rect().get_center())
