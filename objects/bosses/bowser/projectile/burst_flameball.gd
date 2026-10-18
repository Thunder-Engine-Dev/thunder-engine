extends Projectile

var interval: float
var _trail_settings := Effect.TrailSettings.new()


func _physics_process(delta: float) -> void:
	var previous_position: Vector2 = sprite_node.global_position if is_instance_valid(sprite_node) else global_position
	super(delta)
	
	interval += delta
	if interval > 0.01:
		interval = 0
		if !sprite_node is AnimatedSprite2D: return
		var spr: AnimatedSprite2D = sprite_node as AnimatedSprite2D
		_trail_settings.z_index = z_index
		Effect.emit_trail(spr, previous_position, _trail_settings)
