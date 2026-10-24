class_name HitFeedback
extends Node3D
## Muestra los textos de impacto sobre los enemigos. Los textos llevan palabras y no solo
## colores para que se entiendan sin distinguir colores (componente inclusivo).

const EFFECTIVE_TEXT := "¡Efectivo!"
const EFFECTIVE_COLOR := Color(0.45, 1.0, 0.55)
const RESISTED_TEXT := "Resiste"
const RESISTED_COLOR := Color(0.7, 0.7, 0.75)

@export var floating_text_scene: PackedScene

var _pool: ObjectPool


func _ready() -> void:
	_pool = ObjectPool.new(floating_text_scene, self)


func show_hit(world_position: Vector3, effective: bool) -> void:
	var floating_text := _pool.acquire() as FloatingText
	var text_position := world_position + Vector3.UP * 1.4
	if effective:
		floating_text.show_text(text_position, EFFECTIVE_TEXT, EFFECTIVE_COLOR)
	else:
		floating_text.show_text(text_position, RESISTED_TEXT, RESISTED_COLOR)
