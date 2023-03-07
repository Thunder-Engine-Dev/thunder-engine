extends Node

## Singleton that stores general data in the game

## Defines enemies' type of receiving attack
const ATTACKERS:Dictionary = {
	head = &"head",
	starman = &"starman",
	shell = &"shell",
	fireball = &"fireball",
	beetroot = &"beetroot",
	iceball = &"iceball",
	hammer = &"hammer",
	boomerang = &"boomerang"
}

## Defines player's basic power-up status
enum PLAYER_POWER {
	SMALL, ## Self-explanable, e.g. small Mario
	SUPER, ## e.g. big Mario
	FULL   ## e.g. fire Mario
}

## Defines which type a projectile belongs.[br]
## Projectiles can be items thrown, or items with damage
enum PROJECTILE_BELONGS {
	PLAYER, ## Player thrown and attacks enemies
	ENEMY ## Enemy thrown and attacks players
}

## Defines basic information of a player
var values: Dictionary = {
	lives = -1,
	score = 0,
	coins = 0,
	time = -1
}


func add_coin(amount: int = 1) -> void:
	Data.values.coins += 1
	if Data.values.coins > 99:
		Data.values.coins = 0
		Thunder.add_lives(1)
