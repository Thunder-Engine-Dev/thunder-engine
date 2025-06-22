extends ByNodeScript

var player: Player
var resource: PlayerSuitProjectile


func _ready() -> void:
	player = node as Player
	resource = vars.get(&"suit_resource", null)


func _physics_process(_delta: float) -> void:
	if !player || !resource || player.is_crouching || \
	player.warp > Player.Warp.NONE || \
	player.completed: return
	var bulls: StringName = StringName("bul" + resource.resource_name)
	var bull_count: int = player.get_tree().get_nodes_in_group(bulls).size()
	if player.attacked && !player.is_holding && bull_count < resource.amount:
		var _custom_sfx = CharacterManager.get_sound_replace(resource.sound_attack, resource.sound_attack, "attack", true)
		Audio.play_sound(_custom_sfx, player, false)
		player.shot.emit()
		resource.create_projectile(player).add_to_group(bulls)
