class_name MultiList
extends RefCounted
## TAD Multilista: una lista enlazada principal de cabeceras, donde cada cabecera
## tiene su propia sublista enlazada. Gráficamente:
##
##   _head -> [block] -------> [mute] -------> [verify] -> null
##               |                |                |
##            nivel 1          nivel 1          nivel 1
##               |                |                |
##            nivel 2          nivel 2          nivel 2 ...
##
## En el juego: cada cabecera es un hábito y su sublista son sus niveles de mejora.
## Las claves no se repiten: add_header rechaza una clave que ya existe.

var _head: MultiListHeader = null
var _tail: MultiListHeader = null
var _size: int = 0


## Agrega una cabecera al final de la lista principal. Devuelve false si la clave ya existía.
func add_header(key: String, value: Variant) -> bool:
	if find(key) != null:
		return false
	var header := MultiListHeader.new(key, value)
	if _tail == null:
		_head = header
	else:
		_tail.next = header
	_tail = header
	_size += 1
	return true


## Búsqueda secuencial por clave: O(n) en el número de cabeceras (aquí son 4).
func find(key: String) -> MultiListHeader:
	var current := _head
	while current != null:
		if current.key == key:
			return current
		current = current.next
	return null


## Agrega un valor al final de la sublista de `key`. Devuelve false si la cabecera no existe.
func append_to(key: String, value: Variant) -> bool:
	var header := find(key)
	if header == null:
		return false
	var node := ListNode.new(value)
	if header.sub_tail == null:
		header.sub_head = node
	else:
		header.sub_tail.next = node
	header.sub_tail = node
	header.sub_size += 1
	return true


## Valor en la posición `index` (desde 0) de la sublista de `key`, o null si no existe.
func sub_get(key: String, index: int) -> Variant:
	var header := find(key)
	if header == null or index < 0 or index >= header.sub_size:
		return null
	var current := header.sub_head
	for _i in index:
		current = current.next
	return current.value


func sub_size(key: String) -> int:
	var header := find(key)
	return 0 if header == null else header.sub_size


func header_value(key: String) -> Variant:
	var header := find(key)
	return null if header == null else header.value


func size() -> int:
	return _size


func is_empty() -> bool:
	return _head == null


## Valores de las cabeceras en orden, para recorrerlas desde fuera sin exponer los nodos.
func header_values() -> Array:
	var result: Array = []
	var current := _head
	while current != null:
		result.append(current.value)
		current = current.next
	return result


func sub_to_array(key: String) -> Array:
	var result: Array = []
	var header := find(key)
	if header == null:
		return result
	var current := header.sub_head
	while current != null:
		result.append(current.value)
		current = current.next
	return result
