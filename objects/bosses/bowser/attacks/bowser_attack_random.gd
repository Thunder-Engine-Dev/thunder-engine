extends BowserAttack

## Bowser's attack chosen at random.
## For this to work, you must insert the desired attack scripts and put their names here.

@export var attacks: Array[String] = []

func start_attack() -> void:
	super()
	assert(!attacks.is_empty(), "No attacks provided to randomize")
	
	var attack_string = attacks[Thunder.rng.get_randi_range(0, len(attacks) - 1)]
	bowser.attack(attack_string)


func middle_attack() -> void:
	return


func end_attack() -> void:
	return
