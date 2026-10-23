class_name Projectile
extends Area3D
## Disparo automático del jugador. Avanza en línea recta y daña al primer enemigo que toca.
## También vive en un ObjectPool: el jugador dispara varias veces por segundo.

var pool: ObjectPool
var active := false
var _direction := Vector3.ZERO
var _speed := 0.0
var _damage := 0.0
var _time_left := 0.0

@onready var _collision_shape: CollisionShape3D = $CollisionShape


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func fire(origin: Vector3, direction: Vector3, damage: float, travel_speed: float, lifetime: float) -> void:
	global_position = origin
	_direction = direction
	_damage = damage
	_speed = travel_speed
	_time_left = lifetime
	active = true
	visible = true
	set_physics_process(true)
	_collision_shape.set_deferred("disabled", false)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		_deactivate()


func _on_area_entered(area: Area3D) -> void:
	# Si en un mismo cuadro toca dos enemigos, `active` evita que dañe a ambos.
	if not active:
		return
	var enemy := area as Enemy
	if enemy == null or not enemy.active:
		return
	enemy.take_damage(_damage)
	_deactivate()


func _deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	pool.release(self)
