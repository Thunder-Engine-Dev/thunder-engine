extends Projectile

var interval: float


func _physics_process(delta: float) -> void:
	super(delta)
	
	interval += delta
	if interval > 0.04:
		interval = 0
		if !sprite_node is AnimatedSprite2D: return
		var spr: AnimatedSprite2D = sprite_node as AnimatedSprite2D
		Effect.trail(self, spr.sprite_frames.get_frame_texture(spr.animation, spr.frame))
