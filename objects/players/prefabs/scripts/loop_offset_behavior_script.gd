extends ByNodeScript

var _loop_offsets: Dictionary = {}

func _ready() -> void:
	if !node is AnimatedSprite2D:
		printerr(node, ": Expected AnimatedSprite2D")
		return
	
	var _off = CharacterManager.get_suit_tweak("loop_frame_offsets", "", vars.suit)
	if _off is Dictionary:
		_loop_offsets = _off
	node.animation_looped.connect(_sprite_loop)


func _sprite_loop() -> void:
	if !is_instance_valid(node): return
	for anim in _loop_offsets.keys():
		if _loop_offsets[anim] < 0: continue
		if node.animation == anim:
			node.frame = _loop_offsets[anim]
