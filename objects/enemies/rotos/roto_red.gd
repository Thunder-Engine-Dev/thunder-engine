@tool
extends Area2D

@export_category("Roto-Disk")
@export_group("Preview")
@export var preview: bool:
	set(to):
		preview = to
		if preview:
			_origin = position
			_amplitude = amplitude
			_phase = phase
			_track_rot = track_rot
			if amplitude_changing_speed > 0:
				amplitude = amplitude_min
		else:
			position = _origin
			amplitude = _amplitude
			phase = _phase
			track_rot = _track_rot
			_amplitude_in = false
@export var circle_line_spot: int = 32
@export var line_color: Color = Color.ANTIQUE_WHITE
@export_group("Physics")
@export_subgroup("Amplitude")
@export var amplitude_enable: bool = false
@export var amplitude: Vector2 = 150 * Vector2.ONE:
	set(to):
		amplitude = to
		if Engine.is_editor_hint() && !preview:
			oval_pos()
@export_range(0, 9999, 0.01, "suffix:px/s") var amplitude_changing_speed: float = 350
@export var amplitude_min: Vector2
@export var amplitude_max: Vector2 = 200 * Vector2.ONE
@export_subgroup("Phase")
@export_range(-180, 180, 0.01, "suffix:°") var phase: float:
	set(to):
		phase = to
		if Engine.is_editor_hint() && !preview:
			oval_pos()
@export_range(-21599.94, 21599.94, 0.001, "suffix:°/s") var frequency: float = 50
@export_subgroup("Track rotation")
@export var track_rot: float:
	set(to):
		track_rot = to
		if Engine.is_editor_hint() && !preview:
			oval_pos()
@export_range(-21599.94, 21599.94, 0.001, "suffix:°/s") var track_rot_speed: float

var _origin: Vector2
var _phase: float
var _track_rot: float
var _amplitude: Vector2
var _amplitude_in: bool


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	elif !Thunder.View.shows_tool(self): return
	
	draw_set_transform(-position, deg_to_rad(track_rot), Vector2.ONE / global_scale)
	var spots: PackedVector2Array = []
	for i in circle_line_spot + 1:
		var dot: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(circle_line_spot)) * amplitude
		spots.append(dot)
	draw_polyline(spots, line_color, 2)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	z_index = 5


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		if !preview:
			return
	oval_pos()
	
	if amplitude_changing_speed > 0 && amplitude_enable:
		if _amplitude_in:
			amplitude = amplitude.move_toward(amplitude_min, amplitude_changing_speed * delta)
			_amplitude_in = !(amplitude == amplitude_min)
		else:
			amplitude = amplitude.move_toward(amplitude_max, amplitude_changing_speed * delta)
			_amplitude_in = (amplitude == amplitude_max)
	
	phase = wrapf(phase + frequency * delta, -180, 180)
	track_rot = wrapf(track_rot + track_rot_speed * delta, -180, 180)


func oval_pos() -> void:
	position = Thunder.Math.oval(Vector2.ZERO, amplitude, deg_to_rad(phase), deg_to_rad(track_rot)).round()
