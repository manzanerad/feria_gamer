class_name HabitCatalog
extends RefCounted
## TAD Catálogo de hábitos, construido sobre nuestra MultiList:
## - cada CABECERA es un hábito (objeto Habit, clave = su id),
## - su SUBLISTA son los niveles de mejora en orden (diccionarios con las estadísticas).
## La multilista encaja porque cada hábito tiene una cantidad propia de niveles
## que siempre se recorren en orden (1 -> 2 -> 3), y se agregan hábitos sin tocar los demás.

var _list := MultiList.new()


## Llena el catálogo desde el contenido de data/habits.json.
## Si no queda ningún hábito válido, agrega uno por defecto para que el juego siga siendo jugable.
func load_from_dictionary(data: Dictionary) -> void:
	var raw_habits: Variant = data.get("habits", [])
	if raw_habits is Array:
		for item: Variant in raw_habits:
			if item is Dictionary:
				_add_from_dictionary(item)
	if _list.is_empty():
		_add_default_habit()


func _add_from_dictionary(data: Dictionary) -> void:
	var habit := Habit.from_dictionary(data)
	if habit.id == "" or not _list.add_header(habit.id, habit):
		return  # sin id o repetido: se ignora en vez de romper el catálogo
	var raw_levels: Variant = data.get("levels", [])
	if raw_levels is Array:
		for level_data: Variant in raw_levels:
			if level_data is Dictionary:
				_list.append_to(habit.id, level_data)
	# Un hábito sin niveles no se puede usar: le damos un nivel vacío (usa valores por defecto).
	if _list.sub_size(habit.id) == 0:
		_list.append_to(habit.id, {})


func _add_default_habit() -> void:
	_add_from_dictionary({"id": "block", "name": "Bloquear y reportar", "kind": "projectile", "levels": [{}]})


func get_habit(habit_id: String) -> Habit:
	return _list.header_value(habit_id) as Habit


func max_level(habit_id: String) -> int:
	return _list.sub_size(habit_id)


## Estadísticas del nivel `level` (desde 1) del hábito. Diccionario vacío si no existe.
func stats_for(habit_id: String, level: int) -> Dictionary:
	var stats: Variant = _list.sub_get(habit_id, level - 1)
	return stats if stats is Dictionary else {}


## Sube un nivel (o lo adquiere si estaba en 0). Devuelve false si no existe o ya está al máximo.
func upgrade(habit_id: String) -> bool:
	var habit := get_habit(habit_id)
	if habit == null or habit.level >= max_level(habit_id):
		return false
	habit.level += 1
	return true


## Hábitos que todavía pueden mejorar (incluye los que no se tienen).
func available_upgrades() -> Array[Habit]:
	var result: Array[Habit] = []
	for value: Variant in _list.header_values():
		var habit := value as Habit
		if habit.level < max_level(habit.id):
			result.append(habit)
	return result


## Hasta `count` opciones distintas elegidas al azar: es el componente aleatorio de la subida de nivel.
func random_offers(count: int) -> Array[Habit]:
	var options := available_upgrades()
	options.shuffle()
	var result: Array[Habit] = []
	for i in mini(count, options.size()):
		result.append(options[i])
	return result


func owned() -> Array[Habit]:
	var result: Array[Habit] = []
	for value: Variant in _list.header_values():
		var habit := value as Habit
		if habit.is_owned():
			result.append(habit)
	return result


func size() -> int:
	return _list.size()


## Texto para el panel de estructuras del HUD (lo ve el jugador, va en español).
func describe() -> String:
	var lines := PackedStringArray(["MULTILISTA de hábitos (cabecera -> niveles):"])
	for value: Variant in _list.header_values():
		var habit := value as Habit
		lines.append("  %s: nivel %d de %d" % [habit.id, habit.level, max_level(habit.id)])
	return "\n".join(lines)
