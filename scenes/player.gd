class_name Player
extends CharacterBody3D
## Personaje del jugador: se mueve en el plano XZ y ataca solo al enemigo más cercano.
## El ataque automático (como en Vampire Survivors) deja al jugador una sola tarea: moverse.

signal health_changed(current: float, maximum: float)
signal died

@export var speed: float = 7.0
@export var max_health: float = 100.0
## Daño por segundo que hace CADA enemigo que te está tocando.
@export var contact_damage: float = 20.0
@export_group("Attack")
@export var projectile_scene: PackedScene
@export var projectile_container: Node3D
@export var fire_cooldown: float = 0.5     # segundos entre disparos
@export var shot_damage: float = 5.0
@export var attack_range: float = 14.0
@export var projectile_speed: float = 22.0

## Límite del mapa: el suelo mide 200 x 200, así que no dejamos salir al jugador de ahí.
const MAP_LIMIT := 95.0

var health: float
var _alive := true
var _shot_timer := 0.0
var _projectile_pool: ObjectPool

@onready var _model: Node3D = $Model
@onready var _hurt_box: Area3D = $HurtBox


func _ready() -> void:
	health = max_health
	# Los proyectiles van en otro nodo del mundo: si fueran hijos del jugador se moverían con él.
	_projectile_pool = ObjectPool.new(projectile_scene, projectile_container)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_move()
	_check_contact(delta)
	_attack(delta)


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


func _attack(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	var direction := target.global_position - global_position
	direction.y = 0.0
	var projectile := _projectile_pool.acquire() as Projectile
	projectile.fire(global_position + Vector3.UP * 0.6, direction.normalized(), shot_damage, projectile_speed, attack_range / projectile_speed)
	_shot_timer = fire_cooldown


func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	# Comparamos distancias al cuadrado: evita la raíz cuadrada y el orden es el mismo.
	var best_distance := attack_range * attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node3D
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func take_damage(amount: float) -> void:
	if not _alive:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_alive = false
		died.emit()
