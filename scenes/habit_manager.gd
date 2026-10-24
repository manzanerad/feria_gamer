class_name HabitManager
extends Node3D
## Administra los hábitos del jugador: carga el catálogo (multilista) desde el archivo,
## crea el comportamiento de cada hábito cuando se adquiere y lo reconfigura al subir de nivel.
## Es hijo del jugador, así que todos los comportamientos se mueven con él.

signal habits_changed

@export_file("*.json") var habits_path: String = "res://data/habits.json"
@export var projectile_habit_scene: PackedScene
@export var aura_habit_scene: PackedScene
@export var pulse_habit_scene: PackedScene

var catalog := HabitCatalog.new()
## Dónde se crean los proyectiles (lo asigna el jugador).
var projectile_container: Node3D
# id del hábito -> su nodo de comportamiento. Dictionary solo como almacenamiento interno.
var _behaviors: Dictionary = {}


func _ready() -> void:
	catalog.load_from_dictionary(JsonLoader.read_dictionary(habits_path))


func random_offers(count: int) -> Array[Habit]:
	return catalog.random_offers(count)


## Adquiere o mejora un hábito. Ignora ids inválidos o hábitos ya al máximo (entrada errónea).
func apply_upgrade(habit_id: String) -> void:
	if not catalog.upgrade(habit_id):
		return
	var habit := catalog.get_habit(habit_id)
	var behavior := _behaviors.get(habit_id) as HabitBehavior
	if behavior == null:
		behavior = _create_behavior(habit)
		_behaviors[habit_id] = behavior
	behavior.configure(catalog.stats_for(habit_id, habit.level))
	habits_changed.emit()


func _create_behavior(habit: Habit) -> HabitBehavior:
	var scene: PackedScene
	match habit.kind:
		"aura":
			scene = aura_habit_scene
		"pulse":
			scene = pulse_habit_scene
		_:
			scene = projectile_habit_scene
	var behavior := scene.instantiate() as HabitBehavior
	behavior.habit_id = habit.id
	# El contenedor se asigna ANTES de add_child porque el _ready del hábito de disparo lo necesita.
	if behavior is ProjectileHabit:
		(behavior as ProjectileHabit).container = projectile_container
	add_child(behavior)
	return behavior


## Texto corto con los hábitos que se tienen, para el HUD.
func describe_owned() -> String:
	var parts := PackedStringArray()
	for habit in catalog.owned():
		parts.append("%s (nv %d)" % [habit.display_name, habit.level])
	return "Hábitos: " + (", ".join(parts) if not parts.is_empty() else "ninguno")
