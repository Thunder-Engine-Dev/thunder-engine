@tool
extends StaticBumpingBlock

@export_category("Switch Block")
@export_group("General")
@export var id: int = 0:
	set(to):
		id = to
		if Engine.is_editor_hint() || (!Engine.is_editor_hint() && _is_ready):
			if no_hue_shader: return
			$Sprites/AnimatedSprite2D.material.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))
@export var only_bump_by_player: bool = false
@export_group("Visuals")
@export var sprite_frames_override: SpriteFrames
@export var no_hue_shader: bool = false

@onready var _is_ready: bool = true
@onready var sprite: AnimatedSprite2D = $Sprites/AnimatedSprite2D
@onready var shader: ShaderMaterial = sprite.material


func _ready() -> void:
	if sprite_frames_override:
		sprite.sprite_frames = sprite_frames_override
		sprite.play()
	if no_hue_shader:
		sprite.material = null
		return
	shader.set_shader_parameter(&"hue", wrapf(float(id) * 0.02, -1, 1))


func _physics_process(_delta) -> void:
	if Engine.is_editor_hint(): return
	super(_delta)


func got_bumped(by_player: bool = false) -> void:
	if _triggered: return
	if !by_player && only_bump_by_player: return
	bump(false)
	for i in get_tree().get_nodes_in_group("switch_" + str(id)):
		if i.has_method(&"switch"): i.switch()
