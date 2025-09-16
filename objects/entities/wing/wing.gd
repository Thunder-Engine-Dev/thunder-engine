extends AnimatedSprite2D

@export_category("Wing")
@export_node_path("Node") var root_path: NodePath = ^"../.."
@export_node_path("Node2D") var parent_path: NodePath = ^".."
@export var flip_as_parent: bool = true
@export var follow_parent_animation_speed: bool = true

var _is_falling: bool

@onready var parent_sprite: Node2D = get_node(parent_path) as Node2D
@onready var pos_x: float = position.x


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE && _is_falling:
		cancel_free()

func _ready() -> void:
	if parent_sprite is AnimatedSprite2D && follow_parent_animation_speed:
		sprite_frames.set_animation_speed(animation, parent_sprite.sprite_frames.get_animation_speed(parent_sprite.animation))
		_physics_process.call_deferred(0)

func _physics_process(_delta: float) -> void:
	if flip_as_parent && &"flip_h" in parent_sprite:
		position.x = -pos_x - 1 if parent_sprite.flip_h else pos_x
		reset_physics_interpolation()
		flip_h = parent_sprite.flip_h


func fall() -> void:
	if SettingsManager.get_quality() == SettingsManager.QUALITY.MIN:
		queue_free()
		return
	
	_is_falling = true
	stop()
	frame = 0
	(func() -> void:
		set_physics_process(false)
		reparent(get_node(root_path).get_parent())
		reset_physics_interpolation()
		
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
		for i: int in 2:
			tw.chain().tween_property(self, ^"offset:x", offset.x + 24, 0.5)
			tw.tween_property(self, ^"rotation", rotation - PI / 3, 0.5)
			tw.chain().tween_property(self, ^"offset:x", offset.x - 24, 0.5)
			tw.tween_property(self, ^"rotation", rotation + PI / 3, 0.5)
		
		var tw2 := create_tween().set_parallel()
		tw2.tween_property(self, ^"position", position + Vector2.DOWN.rotated(rotation) * 24, 2)
		tw2.tween_property(self, ^"modulate:a", 0.0, 2)
		
		await tw.finished
		tw.kill()
		tw2.kill()
		
		_is_falling = false
		queue_free()
	).call_deferred()
