extends ByNodeScript

var player: Player
var suit: PlayerSuit

func _ready() -> void:
	player = node as Player
	suit = node.suit
	if !player.died.is_connected(_drop_on_death):
		player.died.connect(_drop_on_death)

func _physics_process(delta: float) -> void:
	if !player || player.warp > Player.Warp.NONE || player.is_climbing: return
	

func _drop_on_death() -> void:
	var holding = suit.grab_vars.holding
	if is_instance_valid(holding):
		#holding.got_thrown(true)
		player.emit_signal(&"threw")
