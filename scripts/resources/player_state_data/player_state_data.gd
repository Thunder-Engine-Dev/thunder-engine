extends Resource
class_name PlayerStateData

## Resource used to define [member Player.default_player_state]

## The name of the state
@export var state_name: StringName
## The [AnimatedSprite2D] used for the player
@export var player_prefab: SpriteFrames
## The custom variables for [member player_script]
@export var player_state_vars: Dictionary
## Custom script to define the behavior of the player in this state
@export var player_script: Script
## The power type of the state
@export var player_power: Data.PLAYER_POWER
## The [PlayerStateData] to be changed when the player gets hurt[br]
## [b]Note:[/b] If [enum Data.PLAYER_POWER].EMPTY is chosen, the player will die
@export var powerdown_state: PlayerStateData
## Used to define player's behavior. See [PlayerConfiguration]
@export var player_state_config: PlayerConfiguration
