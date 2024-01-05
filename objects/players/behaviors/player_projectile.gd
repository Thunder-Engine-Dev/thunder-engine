extends ByNodeScript

var player: Player
var resource: PlayerSuitProjectile


func _ready() -> void:
	player = node as Player
	resource = vars.get(&"suit_resource", null)


func _physics_process(_delta: float) -> void:
	if !player || !resource || player.is_crouching || \
	player.warp > Player.Warp.NONE || player.is_climbing || \
	player.completed: return
	var bulls: StringName = StringName("bul" + resource.resource_name)
	var bull_count: int = player.get_tree().get_nodes_in_group(bulls).size()
	if player.attacked && bull_count < resource.amount:
		Audio.play_sound(resource.sound_attack, player, false)
		player.shot.emit()
		resource.create_projectile(player).add_to_group(bulls)
