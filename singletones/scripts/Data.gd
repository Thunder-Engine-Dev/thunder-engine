# Singleton that stores general data
extends Node

var values: Dictionary = {
	lives = -1,
	score = 0,
	coins = 0,
	time = -1
}

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

enum PLAYER_POWER {
	SMALL, # self-explanable
	SUPER, # for example big mario
	FULL   # for example fire mario
}

enum PROJECTILE_BELONGS {
	PLAYER,
	ENEMY
}
