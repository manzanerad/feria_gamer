class_name HabitBehavior
extends Node3D
## Base de los comportamientos de hábito (disparo, aura, pulso).
## Cada hábito que el jugador adquiere crea UN nodo de este tipo como hijo del HabitManager;
## como el manager es hijo del jugador, el comportamiento se mueve con él.
## Al subir de nivel no se crea otro nodo: se llama configure() con las estadísticas nuevas.

var habit_id: String = ""


## Cada subclase lee de `stats` lo que necesita (las claves vienen de data/habits.json).
func configure(_stats: Dictionary) -> void:
	pass


## Lee un número de las estadísticas con valor por defecto (ver JsonLoader.read_number).
func stat(stats: Dictionary, key: String, default_value: float) -> float:
	return JsonLoader.read_number(stats, key, default_value)


func nearest_enemy(max_range: float) -> Enemy:
	var best: Enemy = null
	# Comparamos distancias al cuadrado: evita la raíz cuadrada y el orden es el mismo.
	var best_distance := max_range * max_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best
