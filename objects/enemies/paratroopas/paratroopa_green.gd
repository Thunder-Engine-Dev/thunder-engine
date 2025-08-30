@tool
extends Node2D

enum FacingMethod {
	LOOK_AT_PLAYER,
	X_SINE,
	Y_COSINE
}

@export var amplitude: Vector2 = Vector2(50, 50)
@export_range(0, 360, 0.01, "suffix: °") var phase: float = -1.0
@export_tool_button("Randomize Phase", "RandomNumberGenerator") var set_random_phase = randomize_phase
@export var frequency: float = 1
@export_group("Preview")
@export var circle_line_spot: int = 24
@export var line_color: Color = Color.AQUAMARINE
@export var spot_color: Color = Color.HOT_PINK
@export_group("Deprecated (Do not use)")
@export var random_phase: bool:
	set(rph):
		random_phase = rph
		if !random_phase:
			phase = 0.0
			return
		if phase == -1.0:
			phase = randf_range(0, 360)
@export_group("Sprite")
@export var sprite_path: NodePath
@export var facing_method: FacingMethod = FacingMethod.LOOK_AT_PLAYER

var dir: int
var facing: float

@onready var center: Vector2 = position

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_physics_process(0)


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	#if !owner: return
	if !Thunder.View.shows_tool(self): return
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE / global_scale)
	var spots: PackedVector2Array = []
	for i in circle_line_spot + 1:
		var dot: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(circle_line_spot)) * amplitude
		spots.append(dot)
	draw_polyline(spots, line_color, 2)
	draw_circle(Thunder.Math.oval(Vector2.ZERO, amplitude, deg_to_rad(phase)), 3, spot_color)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	position = Thunder.Math.oval(center, amplitude, deg_to_rad(phase))
	phase = wrapf(phase + frequency * 50 * delta, 0, 360)
	
	if !sprite_path || !has_node(sprite_path):
		return
	var sprite = get_node(sprite_path)
	
	match facing_method:
		FacingMethod.LOOK_AT_PLAYER:
			var player: Player = Thunder._current_player
			if player:
				facing = Thunder.Math.look_at(global_position, player.global_position, global_transform)
		FacingMethod.X_SINE:
			facing = -sin(deg_to_rad(phase))
		FacingMethod.Y_COSINE:
			facing = cos(deg_to_rad(phase))
	dir = sign(facing)
	
	if &"flip_h" in sprite:
		sprite.flip_h = (facing < 0 && facing != 0)

func randomize_phase():
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Randomized Paratroopa Phase")
	undo_redo.add_do_property(self, &"phase", randf_range(0, 360))
	undo_redo.add_undo_property(self, &"phase", phase)
	undo_redo.commit_action()
