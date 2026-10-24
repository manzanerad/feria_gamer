class_name AuraHabit
extends HabitBehavior
## Hábito "Silenciar notificaciones": un área circular alrededor del jugador
## que daña a todo enemigo que esté dentro. Ideal contra enjambres (notificaciones).

## El daño se aplica en "pulsos" de 0.25 s y no en cada cuadro: el resultado por segundo es el mismo,
## pero se hacen 4 consultas de física por segundo en vez de 60.
const TICK := 0.25

var _radius := 2.5
var _damage_per_second := 10.0
var _tick_timer := 0.0

@onready var _area: Area3D = $Area
@onready var _shape: CollisionShape3D = $Area/CollisionShape
@onready var _disc: MeshInstance3D = $Disc


func _ready() -> void:
	# La forma viene de la escena y es un recurso compartido; la duplicamos para cambiar su radio sin afectar otras copias.
	_shape.shape = _shape.shape.duplicate()
	_apply_radius()


func configure(stats: Dictionary) -> void:
	_radius = clampf(stat(stats, "radius", _radius), 0.5, 15.0)
	_damage_per_second = maxf(0.0, stat(stats, "dps", _damage_per_second))
	if is_node_ready():
		_apply_radius()


func _apply_radius() -> void:
	(_shape.shape as SphereShape3D).radius = _radius
	_disc.scale = Vector3(_radius, 1.0, _radius)


func _physics_process(delta: float) -> void:
	_tick_timer -= delta
	if _tick_timer > 0.0:
		return
	_tick_timer = TICK
	for area in _area.get_overlapping_areas():
		var enemy := area as Enemy
		if enemy != null and enemy.active:
			enemy.take_damage(_damage_per_second * TICK, habit_id)
