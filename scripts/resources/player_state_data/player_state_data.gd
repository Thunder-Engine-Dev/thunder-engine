extends Resource
class_name PlayerStateData

## Resource used to define [member Player.default_player_state]

@export_group("General")
## The name of the state
@export var state_name: StringName
## The power type of the state
@export var player_power: Data.PLAYER_POWER
## The [PlayerStateData] to be changed when the player gets hurt[br]
## [b]Note:[/b] If [enum Data.PLAYER_POWER].EMPTY is chosen, the player will die
@export var powerdown_state: PlayerStateData
@export_group("Animation")
## The [AnimatedSprite2D] used for the player
@export var player_prefab: SpriteFrames
## Used to define player's behavior. See [PlayerConfiguration]
@export_group("Physics")
@export var player_state_config: PlayerConfiguration
@export_group("Extra Behavior")
## The custom variables for [member player_script]
@export var player_state_vars: Dictionary
## Custom script to define the behavior of the player in this state
@export var player_script: Script
