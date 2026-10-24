class_name ProjectileHabit
extends HabitBehavior
## Hábito que dispara proyectiles al enemigo más cercano ("Bloquear y reportar", "Verificar la fuente").
## Los dos usan el mismo código: cambian los números del JSON (daño, cantidad, cuántos atraviesa, color).

const SPREAD_ANGLE := 0.18   # radianes entre proyectiles cuando dispara varios en abanico

@export var projectile_scene: PackedScene

var container: Node3D
var _pool: ObjectPool
var _damage := 6.0
var _cooldown := 0.6
var _count := 1
var _pierce := 0
var _speed := 22.0
var _range := 14.0
var _color := Color(1.0, 0.85, 0.2)
var _timer := 0.0


func _ready() -> void:
	# Cada hábito de disparo tiene su propio pool: así cada uno recicla sus proyectiles con su color.
	_pool = ObjectPool.new(projectile_scene, container)


func configure(stats: Dictionary) -> void:
	_damage = stat(stats, "damage", _damage)
	_cooldown = maxf(0.1, stat(stats, "cooldown", _cooldown))
	_count = clampi(int(stat(stats, "count", _count)), 1, 8)
	_pierce = clampi(int(stat(stats, "pierce", _pierce)), 0, 20)
	_speed = maxf(1.0, stat(stats, "speed", _speed))
	_range = maxf(1.0, stat(stats, "range", _range))
	_color = Color.from_string(str(stats.get("color", "")), _color)


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	var target := nearest_enemy(_range)
	if target == null:
		return
	_timer = _cooldown
	var aim := target.global_position - global_position
	aim.y = 0.0
	aim = aim.normalized()
	for i in _count:
		# Ángulos centrados: con 3 proyectiles salen a -SPREAD, 0 y +SPREAD.
		var angle := (i - (_count - 1) / 2.0) * SPREAD_ANGLE
		var projectile := _pool.acquire() as Projectile
		projectile.fire(global_position + Vector3.UP * 0.6, aim.rotated(Vector3.UP, angle), _damage, _speed, _range / _speed, habit_id, _pierce, _color)
