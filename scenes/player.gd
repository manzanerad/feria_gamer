class_name Player
extends CharacterBody3D
## Personaje del jugador: se mueve en el plano XZ, junta experiencia y sube de nivel.
## Ya no dispara por su cuenta: los ataques son sus hábitos (hijos del HabitManager),
## que actúan solos como en Vampire Survivors. Al jugador le toca moverse y elegir bien sus hábitos.

signal health_changed(current: float, maximum: float)
signal experience_changed(current: int, needed: int, level: int)
signal leveled_up
signal died

@export var speed: float = 7.0
@export var max_health: float = 100.0
## Daño por segundo que hace CADA enemigo que te está tocando.
@export var contact_damage: float = 15.0
@export var projectile_container: Node3D

## Límite del mapa: el suelo mide 200 x 200, así que no dejamos salir al jugador de ahí.
const MAP_LIMIT := 95.0

var health: float
var level: int = 1
var experience: int = 0
var _alive := true

@onready var habits: HabitManager = $HabitManager
@onready var _model: Node3D = $Model
@onready var _hurt_box: Area3D = $HurtBox


func _ready() -> void:
	health = max_health
	# Los proyectiles van en otro nodo del mundo: si fueran hijos del jugador se moverían con él.
	habits.projectile_container = projectile_container


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_move()
	_check_contact(delta)


func _move() -> void:
	# get_vector usa las acciones del Input Map, así un joystick táctil podría
	# alimentar las mismas acciones más adelante sin tocar este código.
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input.x, 0.0, input.y) * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, -MAP_LIMIT, MAP_LIMIT)
	global_position.z = clampf(global_position.z, -MAP_LIMIT, MAP_LIMIT)
	if input != Vector2.ZERO:
		# El modelo mira hacia -Z por defecto; este ángulo lo gira hacia donde camina.
		_model.rotation.y = atan2(-velocity.x, -velocity.z)


func _check_contact(delta: float) -> void:
	var touching := _hurt_box.get_overlapping_areas().size()
	if touching > 0:
		take_damage(touching * contact_damage * delta)


## Experiencia necesaria para pasar del nivel actual al siguiente: crece con cada nivel
## para que las primeras mejoras lleguen rápido y las últimas cuesten más.
func experience_to_next_level() -> int:
	return 4 + level * 3


func add_experience(amount: int) -> void:
	if not _alive or amount <= 0:
		return
	experience += amount
	# while y no if: un enemigo que da mucha experiencia puede hacer subir varios niveles a la vez.
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		leveled_up.emit()
	experience_changed.emit(experience, experience_to_next_level(), level)


func heal(amount: float) -> void:
	if not _alive:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func take_damage(amount: float) -> void:
	if not _alive:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_alive = false
		died.emit()
