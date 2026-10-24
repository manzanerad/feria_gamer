class_name Habit
extends RefCounted
## TAD Hábito: una conducta sana que en el juego funciona como arma.
## `level` = 0 significa que el jugador todavía no lo tiene.
## Los datos de cada nivel NO se guardan aquí: viven en la sublista de la multilista
## (ver HabitCatalog), así este objeto solo describe el hábito y en qué nivel va.

## Tipos de comportamiento que el juego sabe ejecutar (ver HabitManager).
const KINDS := ["projectile", "aura", "pulse"]

var id: String = ""
var display_name: String = ""
var kind: String = "projectile"
var description: String = ""
var tip: String = ""
var level: int = 0


static func from_dictionary(data: Dictionary) -> Habit:
	var habit := Habit.new()
	habit.id = str(data.get("id", ""))
	habit.display_name = str(data.get("name", habit.id))
	var requested_kind := str(data.get("kind", habit.kind))
	habit.kind = requested_kind if requested_kind in KINDS else "projectile"
	habit.description = str(data.get("description", ""))
	habit.tip = str(data.get("tip", ""))
	return habit


func is_owned() -> bool:
	return level > 0
