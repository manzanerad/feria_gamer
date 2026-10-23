class_name ListNode
extends RefCounted
## Nodo de una lista simplemente enlazada: guarda un valor y la referencia al siguiente.
## Es la pieza base de Stack y Queue.
## Extiende RefCounted para que Godot lo libere solo cuando nadie lo referencia
## (no hay que llamar free() a mano ni se queda memoria colgando).

var value: Variant
var next: ListNode = null


func _init(p_value: Variant = null) -> void:
	value = p_value
