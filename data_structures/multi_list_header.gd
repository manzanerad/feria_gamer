class_name MultiListHeader
extends RefCounted
## Nodo cabecera de una multilista. Tiene dos enlaces:
## - `next`: la siguiente cabecera de la lista principal.
## - `sub_head` / `sub_tail`: el inicio y el final de SU propia sublista (hecha de ListNode).
## Guardar `sub_tail` permite agregar al final de la sublista en O(1), igual que en Queue.

var key: String
var value: Variant
var next: MultiListHeader = null
var sub_head: ListNode = null
var sub_tail: ListNode = null
var sub_size: int = 0


func _init(p_key: String = "", p_value: Variant = null) -> void:
	key = p_key
	value = p_value
