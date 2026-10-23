class_name Enemy
extends Area3D
## Amenaza básica: persigue al jugador en el plano XZ.
## Se mueve sumando a su posición, sin motor de física: con cientos de enemigos,
## move_and_slide en cada uno sería demasiado costoso. Los golpes los detectan las Area3D.
## Vive en un ObjectPool: al morir no se destruye, se esconde y vuelve a la pila de libres.

signal killed(enemy: Enemy)

var pool: ObjectPool
var threat_type: String = ""
var health: float = 1.0
var speed: float = 3.0
var target: Node3D
var active := false

# Material propio de cada enemigo para poder pintarlo según el tipo de su oleada.
var _material := StandardMaterial3D.new()

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision_shape: CollisionShape3D = $CollisionShape


func _ready() -> void:
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 1.5
	_mesh.material_override = _material


func activate(wave: Wave, start_position: Vector3, p_target: Node3D) -> void:
	threat_type = wave.threat_type
	health = wave.health
	# Pequeña variación de velocidad para que no lleguen todos en bloque.
	speed = wave.speed * randf_range(0.85, 1.15)
	target = p_target
	global_position = start_position
	_material.albedo_color = wave.color
	_material.emission = wave.color
	active = true
	visible = true
	set_physics_process(true)
	# set_deferred: cambiar colisiones durante un cálculo de física da error, así que se aplaza.
	_collision_shape.set_deferred("disabled", false)
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		global_position += direction.normalized() * speed * delta


func take_damage(amount: float) -> void:
	if not active:
		return
	health -= amount
	if health <= 0.0:
		killed.emit(self)
		_deactivate()


func _deactivate() -> void:
	active = false
	visible = false
	# Solo apagamos su _physics_process: cambiar process_mode a DISABLED también
	# desactivaría la colisión de golpe, y eso no se puede hacer dentro de una señal de física.
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	remove_from_group("enemies")
	pool.release(self)
