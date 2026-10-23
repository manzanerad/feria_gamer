extends SceneTree
## Pruebas automáticas de las estructuras propias, sin abrir el juego:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_data_structures.gd
## Sirven como evidencia de confiabilidad para el informe (sección Resultados).

var _failures := 0
var _total := 0


func _init() -> void:
	_test_stack()
	_test_queue()
	_test_wave()
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


func _test_wave() -> void:
	print("Wave (lectura robusta del archivo)")
	var good := Wave.from_dictionary({"type": "troll", "start": 45, "interval": 2.5, "color": "#a64dff"})
	_check(good.threat_type == "troll" and is_equal_approx(good.start, 45.0), "lee los campos válidos")
	var bad := Wave.from_dictionary({"start": "texto", "interval": 0, "per_spawn": 999, "health": -5, "color": "no-es-color"})
	_check(is_equal_approx(bad.start, 0.0), "texto en un número usa el valor por defecto")
	_check(bad.interval >= 0.1, "intervalo 0 se sube a 0.1 (evita bucle infinito)")
	_check(bad.per_spawn == 20 and bad.health >= 1.0, "valores fuera de rango se recortan")
	_check(bad.color == Wave.new().color, "color inválido usa el color por defecto")
