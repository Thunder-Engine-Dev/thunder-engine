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
	if !player.attacked: return
	if player.is_holding: return
	var bulls: StringName = StringName("bul" + resource.resource_path)
	var bull_count: int = player.get_tree().get_node_count_in_group(bulls)
	if resource.amount_extra >= 0 && !Console.cv.unlimited_player_projectiles:
		var extras := StringName("bul_extra" + resource.resource_path)
		var extra_count: int = player.get_tree().get_node_count_in_group(extras)
		if extra_count >= resource.amount_extra:
			return
	if bull_count < resource.amount || Console.cv.unlimited_player_projectiles:
		var _custom_sfx = CharacterManager.get_sound_replace(resource.sound_attack, resource.sound_attack, "attack", true)
		Audio.play_sound(_custom_sfx, player, false)
		player.shot.emit()
		resource.create_projectile(player).add_to_group(bulls)
