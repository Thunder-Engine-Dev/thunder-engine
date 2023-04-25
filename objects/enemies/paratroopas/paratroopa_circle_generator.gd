@tool
extends Node2D

@export_category("Koopa Paratroopa Circle Generator")
@export var troopa: PackedScene
@export var amount: int = 6
@export_group("Circle")
@export var preview: bool:
	set(to):
		preview = to
		if preview:
			_phase = phase
			_amplitude = amplitude
		else:
			phase = _phase
			amplitude = _amplitude
@export var circle_line_spot: int = 32
@export var line_color: Color = Color.BROWN
@export_subgroup("Settings")
@export var amplitude: Vector2 = Vector2.ONE * 150:
	set(to):
		amplitude = to
@export_range(-180, 180, 0.01, "suffix:°") var phase: float:
	set(to):
		phase = to
@export_range(-359.999, 359.999, 0.001, "suffix:°/f") var frequency: float = 1

var _phase: float
var _amplitude: Vector2


func _ready() -> void:
	if Engine.is_editor_hint(): return
	for i in amount:
		var angle: float = float(i) * (360 / float(amount))
		if !troopa: return
		var troopa_ins: Node2D = troopa.instantiate() as Node2D
		if !troopa_ins: return
		if !troopa_ins.is_in_group(&"#circle"): return
		troopa_ins.random_phase = false
		troopa_ins.amplitude = amplitude
		troopa_ins.phase = angle
		troopa_ins.frequency = frequency
		add_child.call_deferred(troopa_ins)


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	if !Thunder.View.shows_tool(self): return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	var spots: PackedVector2Array = []
	for i in circle_line_spot + 1:
		var dot: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(circle_line_spot)) * amplitude
		spots.append(dot)
	draw_polyline(spots, line_color, 2)
	
	for j in amount:
		var dot: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(phase) + float(j) * TAU / float(amount)) * amplitude
		draw_circle(dot, 8, Color.GREEN_YELLOW)


func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint(): return
	if !Thunder.View.shows_tool(self): return
	
	if preview: 
		phase = wrapf(phase + 50 * delta, -180, 180)
	
	queue_redraw()


func _on_child_entered_tree(node: Node) -> void:
	if Engine.is_editor_hint(): return
	if node.is_in_group(&"#circle"): return
	
	node.reparent.call_deferred(get_parent())


func _on_child_exiting_tree(node: Node) -> void:
	if Engine.is_editor_hint(): return
	if get_child_count() <= 0:
		queue_free()
