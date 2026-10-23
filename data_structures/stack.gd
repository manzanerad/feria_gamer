class_name Stack
extends RefCounted
## TAD Pila (LIFO: el último en entrar es el primero en salir) con nodos enlazados.
## La cima es la cabeza de la lista: push y pop solo tocan la cabeza,
## por eso ambas operaciones son O(1) sin importar cuántos elementos haya.

var _top: ListNode = null
var _size: int = 0


func push(value: Variant) -> void:
	var node := ListNode.new(value)
	node.next = _top
	_top = node
	_size += 1


func pop() -> Variant:
	# Pila vacía: devolvemos null en vez de lanzar un error, así quien llama decide qué hacer.
	if _top == null:
		return null
	var value: Variant = _top.value
	_top = _top.next
	_size -= 1
	return value


func peek() -> Variant:
	return null if _top == null else _top.value


func is_empty() -> bool:
	return _top == null


func size() -> int:
	return _size


## Copia los valores de la cima al fondo. Solo sirve para mostrar la pila en pantalla;
## la lógica del juego nunca la recorre así.
func to_array() -> Array:
	var result: Array = []
	var current := _top
	while current != null:
		result.append(current.value)
		current = current.next
	return result
