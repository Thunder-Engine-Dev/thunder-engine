extends AnimatedSprite2D

@export_category("Wing")
@export_node_path("Node") var root_path: NodePath = ^"../.."
@export_node_path("Node2D") var parent_path: NodePath = ^".."
@export var flip_as_parent: bool = true
@export var follow_parent_animation_speed: bool = true

var _is_falling: bool

@onready var _anim: AnimationPlayer = $AnimationPlayer

@onready var parent_sprite: Node2D = get_node(parent_path) as Node2D
@onready var pos_x: float = position.x


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE && _is_falling:
		print("Haha!")
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
	(func() -> void:
		set_physics_process(false)
		reparent(get_node(root_path).get_parent())
		
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_loops()
		tw.tween_property(self, ^"position:x", position.x + 16, 0.2)
		tw.tween_property(self, ^"position:x", position.x - 16, 0.2)
		
		var tw2 := create_tween()
		tw2.tween_property(self, ^"position:y", position.y + 64, 1)
		
		_anim.play(&"fall")
		await _anim.animation_finished
		tw.kill()
		tw2.kill()
		
		_is_falling = false
		queue_free()
	).call_deferred()
