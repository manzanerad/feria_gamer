class_name Queue
extends RefCounted
## TAD Cola (FIFO: el primero en entrar es el primero en salir) con nodos enlazados.
## Guarda una referencia al frente (por donde se sale) y otra al final (por donde se entra).
## Con las dos referencias, enqueue y dequeue son O(1); con solo el frente,
## encolar obligaría a recorrer toda la lista para llegar al último nodo.

var _front: ListNode = null
var _rear: ListNode = null
var _size: int = 0


func enqueue(value: Variant) -> void:
	var node := ListNode.new(value)
	if _rear == null:
		_front = node
	else:
		_rear.next = node
	_rear = node
	_size += 1


func dequeue() -> Variant:
	if _front == null:
		return null
	var value: Variant = _front.value
	_front = _front.next
	# Si se vació, el final también debe quedar en null; si no, apuntaría a un nodo que ya salió.
	if _front == null:
		_rear = null
	_size -= 1
	return value


func front() -> Variant:
	return null if _front == null else _front.value


func is_empty() -> bool:
	return _front == null


func size() -> int:
	return _size


## Copia los valores del frente al final, solo para mostrarlos en pantalla.
func to_array() -> Array:
	var result: Array = []
	var current := _front
	while current != null:
		result.append(current.value)
		current = current.next
	return result
