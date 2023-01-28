# Singleton that stores general data
extends Node

const ATTACKERS: Dictionary = {
	head = &"head",
	starman = &"starman",
	shell = &"shell",
	fireball = &"fireball",
	beetroot = &"beetroot",
	iceball = &"iceball",
	hammer = &"hammer"
}

enum PLAYER_POWER {
	SMALL, # self-explanable
	SUPER, # for example big mario
	FULL   # for example fire mario
}