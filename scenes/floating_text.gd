class_name FloatingText
extends Label3D
## Texto que sube y se desvanece sobre un enemigo golpeado ("¡Efectivo!" / "Resiste").
## Es la retroalimentación inmediata del sistema de debilidades: el jugador VE si eligió bien.
## Reciclado con ObjectPool, igual que enemigos y proyectiles.

const LIFETIME := 0.7
const RISE_SPEED := 1.6

var pool: ObjectPool
var _time_left := 0.0


func show_text(world_position: Vector3, content: String, color: Color) -> void:
	global_position = world_position
	text = content
	modulate = color
	_time_left = LIFETIME
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_time_left -= delta
	position.y += RISE_SPEED * delta
	modulate.a = clampf(_time_left / LIFETIME, 0.0, 1.0)
	if _time_left <= 0.0:
		visible = false
		set_process(false)
		pool.release(self)
