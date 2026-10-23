class_name ObjectPool
extends RefCounted
## TAD Pool de objetos: recicla instancias de una escena en vez de crearlas y destruirlas.
## Crear y liberar nodos cada vez que aparece o muere un enemigo es caro y provoca tirones;
## con el pool, un enemigo muerto se esconde y se guarda para reutilizarlo después.
## Los objetos libres se guardan en nuestra Stack: acquire = pop, release = push (O(1)).

var _scene: PackedScene
var _container: Node
var _available := Stack.new()
var _created: int = 0


func _init(scene: PackedScene, container: Node) -> void:
	_scene = scene
	_container = container


## Entrega un objeto listo para configurar: uno reciclado si hay, o uno nuevo si la pila está vacía.
func acquire() -> Node:
	if not _available.is_empty():
		return _available.pop() as Node
	var instance := _scene.instantiate()
	# El objeto guarda una referencia a su pool para poder devolverse solo cuando muere.
	instance.set("pool", self)
	_container.add_child(instance)
	_created += 1
	return instance


func release(instance: Node) -> void:
	_available.push(instance)


func available_count() -> int:
	return _available.size()


func created_count() -> int:
	return _created
