extends SceneTree
## Pruebas automáticas de las estructuras propias, sin abrir el juego:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_data_structures.gd
## Sirven como evidencia de confiabilidad para el informe (sección Resultados).

var _failures := 0
var _total := 0


func _init() -> void:
	_test_stack()
	_test_queue()
	_test_multi_list()
	_test_wave()
	_test_threat()
	_test_habit_catalog()
	print("Pruebas: %d de %d correctas" % [_total - _failures, _total])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	_total += 1
	if condition:
		print("  OK    ", description)
	else:
		_failures += 1
		print("  FALLA ", description)


func _test_stack() -> void:
	print("Stack")
	var stack := Stack.new()
	_check(stack.is_empty() and stack.size() == 0, "empieza vacía")
	_check(stack.pop() == null, "pop en pila vacía devuelve null sin romperse")
	stack.push(1)
	stack.push(2)
	stack.push(3)
	_check(stack.size() == 3 and stack.peek() == 3, "la cima es el último apilado")
	_check(stack.to_array() == [3, 2, 1], "to_array va de la cima al fondo")
	_check(stack.pop() == 3 and stack.pop() == 2, "sale en orden LIFO")
	_check(stack.pop() == 1 and stack.is_empty(), "queda vacía al sacar todo")


func _test_queue() -> void:
	print("Queue")
	var queue := Queue.new()
	_check(queue.is_empty() and queue.dequeue() == null, "vacía y dequeue devuelve null")
	queue.enqueue("a")
	queue.enqueue("b")
	queue.enqueue("c")
	_check(queue.size() == 3 and queue.front() == "a", "el frente es el primero encolado")
	_check(queue.dequeue() == "a" and queue.dequeue() == "b", "sale en orden FIFO")
	_check(queue.dequeue() == "c" and queue.is_empty(), "queda vacía al sacar todo")
	# Caso que suele fallar: volver a encolar después de vaciarla (el final debía quedar en null).
	queue.enqueue("d")
	_check(queue.front() == "d" and queue.size() == 1, "funciona otra vez tras vaciarse")


func _test_multi_list() -> void:
	print("MultiList")
	var list := MultiList.new()
	_check(list.is_empty() and list.find("x") == null, "empieza vacía y find no encuentra nada")
	_check(list.add_header("mute", "Silenciar") and list.add_header("block", "Bloquear"), "agrega cabeceras")
	_check(not list.add_header("mute", "otra"), "rechaza una clave repetida")
	_check(list.size() == 2 and list.header_values() == ["Silenciar", "Bloquear"], "mantiene el orden de las cabeceras")
	list.append_to("mute", 10)
	list.append_to("mute", 20)
	list.append_to("mute", 30)
	_check(list.sub_size("mute") == 3 and list.sub_size("block") == 0, "cada cabecera tiene su propia sublista")
	_check(list.sub_get("mute", 0) == 10 and list.sub_get("mute", 2) == 30, "sub_get recorre la sublista en orden")
	_check(list.sub_to_array("mute") == [10, 20, 30], "sub_to_array devuelve la sublista completa")
	_check(list.sub_get("mute", 3) == null and list.sub_get("mute", -1) == null, "índices fuera de rango devuelven null")
	_check(not list.append_to("nope", 1) and list.sub_get("nope", 0) == null, "claves inexistentes no rompen nada")


func _test_wave() -> void:
	print("Wave (lectura robusta del archivo)")
	var good := Wave.from_dictionary({"type": "troll", "start": 45, "interval": 2.5})
	_check(good.threat_type == "troll" and is_equal_approx(good.start, 45.0), "lee los campos válidos")
	var bad := Wave.from_dictionary({"start": "texto", "interval": 0, "per_spawn": 999, "health": -5})
	_check(is_equal_approx(bad.start, 0.0), "texto en un número usa el valor por defecto")
	_check(bad.interval >= 0.1, "intervalo 0 se sube a 0.1 (evita bucle infinito)")
	_check(bad.per_spawn == 20 and bad.health >= 1.0, "valores fuera de rango se recortan")


func _test_threat() -> void:
	print("Threat (sistema de debilidades)")
	var troll := Threat.from_dictionary("troll", {"name": "Troll", "shape": "box", "weak_to": "block", "xp": 3})
	_check(troll.display_name == "Troll" and troll.shape == "box" and troll.xp == 3, "lee los campos válidos")
	_check(troll.is_weak_to("block") and not troll.is_weak_to("mute"), "solo es débil a su hábito")
	_check(is_equal_approx(troll.damage_multiplier("block"), Threat.EFFECTIVE_MULTIPLIER), "su hábito hace daño doble")
	_check(is_equal_approx(troll.damage_multiplier("mute"), Threat.RESISTED_MULTIPLIER), "otro hábito hace la mitad")
	var bad := Threat.from_dictionary("x", {"shape": "dodecaedro", "xp": "mucho", "color": "no-es-color"})
	_check(bad.shape == "sphere" and bad.xp == 1, "forma y xp inválidas usan valores por defecto")
	_check(not bad.is_weak_to(""), "un id vacío nunca cuenta como debilidad")


func _test_habit_catalog() -> void:
	print("HabitCatalog (multilista de hábitos y niveles)")
	var catalog := HabitCatalog.new()
	catalog.load_from_dictionary({"habits": [
		{"id": "mute", "name": "Silenciar", "kind": "aura", "levels": [{"radius": 2.0}, {"radius": 3.0}]},
		{"id": "block", "name": "Bloquear", "kind": "projectile", "levels": [{"damage": 6}]},
		{"id": "mute", "name": "Duplicado", "levels": []},
		"esto no es un diccionario",
	]})
	_check(catalog.size() == 2, "ignora hábitos repetidos y entradas inválidas")
	_check(catalog.max_level("mute") == 2 and catalog.max_level("block") == 1, "el máximo nivel es el tamaño de la sublista")
	_check(catalog.get_habit("mute").level == 0 and catalog.owned().is_empty(), "al inicio no se tiene ningún hábito")
	_check(catalog.available_upgrades().size() == 2, "todos los hábitos están disponibles al inicio")
	_check(catalog.upgrade("mute") and catalog.get_habit("mute").level == 1, "upgrade adquiere el hábito en nivel 1")
	_check(is_equal_approx(float(catalog.stats_for("mute", 1).get("radius", 0.0)), 2.0), "stats_for lee el nivel correcto de la sublista")
	_check(catalog.upgrade("mute") and not catalog.upgrade("mute"), "no pasa del nivel máximo")
	_check(catalog.available_upgrades().size() == 1, "un hábito al máximo deja de ofrecerse")
	_check(not catalog.upgrade("no-existe"), "un id inexistente no rompe nada")
	_check(catalog.random_offers(3).size() == 1, "random_offers no ofrece más de lo disponible")
	var empty := HabitCatalog.new()
	empty.load_from_dictionary({})
	_check(empty.size() == 1, "sin archivo válido agrega un hábito por defecto")
