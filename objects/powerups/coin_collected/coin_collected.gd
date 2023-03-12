extends Node2D

const CoinEffect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

func _ready() -> void:
	var set_effect: Callable = func(eff: Node2D) -> void:
		await get_tree().process_frame
		eff.global_transform = global_transform
	
	NodeCreator.prepare_2d(CoinEffect, self).call_method(set_effect).create_2d().bind_global_transform()
	Data.add_coin()
	
	visible = false
