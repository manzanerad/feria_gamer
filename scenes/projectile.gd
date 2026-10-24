class_name Projectile
extends Area3D
## Proyectil de un hábito de disparo. Avanza en línea recta y daña a los enemigos que toca.
## Puede atravesar `pierce` enemigos antes de desaparecer ("Verificar la fuente" atraviesa varios).
## También vive en un ObjectPool: los hábitos disparan varias veces por segundo.

var pool: ObjectPool
var active := false
var _direction := Vector3.ZERO
var _speed := 0.0
var _damage := 0.0
var _time_left := 0.0
var _habit_id := ""
var _pierce_left := 0
# Material propio para pintar el proyectil con el color de su hábito.
var _material := StandardMaterial3D.new()

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision_shape: CollisionShape3D = $CollisionShape


func _ready() -> void:
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 2.0
	_mesh.material_override = _material
	area_entered.connect(_on_area_entered)


func fire(origin: Vector3, direction: Vector3, damage: float, travel_speed: float, lifetime: float, habit_id: String, pierce: int, color: Color) -> void:
	global_position = origin
	_direction = direction
	_damage = damage
	_speed = travel_speed
	_time_left = lifetime
	_habit_id = habit_id
	_pierce_left = pierce
	_material.albedo_color = color
	_material.emission = color
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
	# `active` evita seguir dañando después de haberse gastado en este mismo cuadro.
	if not active:
		return
	var enemy := area as Enemy
	if enemy == null or not enemy.active:
		return
	enemy.take_damage(_damage, _habit_id)
	if _pierce_left > 0:
		_pierce_left -= 1
	else:
		_deactivate()


func _deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	pool.release(self)
