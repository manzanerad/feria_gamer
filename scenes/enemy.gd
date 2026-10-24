class_name Enemy
extends Area3D
## Amenaza que persigue al jugador en el plano XZ.
## Se mueve sumando a su posición, sin motor de física: con cientos de enemigos,
## move_and_slide en cada uno sería demasiado costoso. Los golpes los detectan las Area3D.
## Vive en un ObjectPool: al morir no se destruye, se esconde y vuelve a la pila de libres.
## Su Threat decide la forma, el color y qué hábito le hace daño extra (sistema de debilidades).

signal killed(enemy: Enemy)
## Se emite al recibir daño (como máximo una vez cada POPUP_COOLDOWN) para mostrar el texto de impacto.
signal damaged(enemy: Enemy, effective: bool)

const FLASH_TIME := 0.08
## Sin este límite, el aura (4 golpes por segundo) llenaría la pantalla de textos.
const POPUP_COOLDOWN := 0.6
const SPIN_SPEED := 1.5
const KNOCKBACK_DECAY := 20.0

var pool: ObjectPool
var threat: Threat
var health: float = 1.0
var speed: float = 3.0
var target: Node3D
var active := false

# Material propio de cada enemigo para poder pintarlo según su amenaza y hacerlo destellar.
var _material := StandardMaterial3D.new()
var _knockback := Vector3.ZERO
var _flash_left := 0.0
var _popup_left := 0.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision_shape: CollisionShape3D = $CollisionShape


func _ready() -> void:
	_material.emission_enabled = true
	# Emisión moderada: con más brillo los colores se lavan hacia el blanco y se parecen entre sí.
	_material.emission_energy_multiplier = 0.6
	_mesh.material_override = _material


## Crea la malla de una forma. La llama WaveSpawner una sola vez por amenaza y la comparte entre enemigos.
static func build_mesh(shape: String) -> Mesh:
	var mesh: Mesh
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3(0.9, 0.9, 0.9)
			mesh = box
		"prism":
			var prism := PrismMesh.new()
			prism.size = Vector3(1.0, 1.1, 1.0)
			mesh = prism
		"torus":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.22
			torus.outer_radius = 0.6
			mesh = torus
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 16
			sphere.rings = 8
			mesh = sphere
	return mesh


func activate(wave: Wave, p_threat: Threat, mesh: Mesh, start_position: Vector3, p_target: Node3D) -> void:
	threat = p_threat
	health = wave.health
	# Pequeña variación de velocidad para que no lleguen todos en bloque.
	speed = wave.speed * randf_range(0.85, 1.15)
	target = p_target
	global_position = start_position
	_mesh.mesh = mesh
	_material.albedo_color = threat.color
	_material.emission = threat.color
	_knockback = Vector3.ZERO
	_flash_left = 0.0
	_popup_left = 0.0
	active = true
	visible = true
	set_physics_process(true)
	# set_deferred: cambiar colisiones durante un cálculo de física da error, así que se aplaza.
	_collision_shape.set_deferred("disabled", false)
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_mesh.rotate_y(SPIN_SPEED * delta)
	if target == null:
		return
	var direction := target.global_position - global_position
	direction.y = 0.0
	var movement := _knockback
	if direction.length_squared() > 0.01:
		movement += direction.normalized() * speed
	global_position += movement * delta
	# El empujón se va frenando hasta desaparecer.
	_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)


func _update_timers(delta: float) -> void:
	_popup_left -= delta
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_material.emission = threat.color


## `habit_id` es el hábito que golpea: si es la debilidad de esta amenaza, el daño se duplica.
func take_damage(amount: float, habit_id: String) -> void:
	if not active:
		return
	var effective := threat.is_weak_to(habit_id)
	health -= amount * threat.damage_multiplier(habit_id)
	if effective:
		# Destello blanco: confirma visualmente que se eligió el hábito correcto.
		_material.emission = Color.WHITE
		_flash_left = FLASH_TIME
	if _popup_left <= 0.0:
		_popup_left = POPUP_COOLDOWN
		damaged.emit(self, effective)
	if health <= 0.0:
		killed.emit(self)
		_deactivate()


func knock_back(impulse: Vector3) -> void:
	if active:
		_knockback += impulse


func _deactivate() -> void:
	active = false
	visible = false
	# Solo apagamos su _physics_process: cambiar process_mode a DISABLED también
	# desactivaría la colisión de golpe, y eso no se puede hacer dentro de una señal de física.
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	remove_from_group("enemies")
	pool.release(self)
