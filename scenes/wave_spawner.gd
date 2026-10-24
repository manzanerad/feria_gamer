class_name WaveSpawner
extends Node
## Lee las amenazas y las oleadas de archivos JSON, guarda las oleadas en nuestra Queue
## ordenadas por segundo de inicio y las va activando cuando llega su momento.
## La cola encaja porque las oleadas se consumen en el mismo orden en que se programaron:
## solo hace falta mirar el frente para saber si ya le toca a la siguiente.

signal enemy_killed(experience: int)
signal match_won

@export var enemy_scene: PackedScene
@export var container: Node3D
@export var hit_feedback: HitFeedback
@export_file("*.json") var waves_path: String = "res://data/waves.json"
@export_file("*.json") var threats_path: String = "res://data/threats.json"
## Distancia al jugador donde aparecen: un poco más allá de lo que alcanza a ver la cámara.
@export var spawn_radius: float = 24.0
## Tope de enemigos vivos para que el rendimiento no se caiga.
@export var max_enemies: int = 250

var target: Node3D
var match_time: float = 0.0
var match_duration: float = 300.0
## id de amenaza -> Threat. Dictionary solo como almacenamiento interno (búsqueda por nombre).
var threats: Dictionary = {}

var _pending := Queue.new()
# Oleadas que ya empezaron. Array solo como almacenamiento interno: la estructura
# que se evalúa aquí es la Queue de pendientes.
var _active: Array[Wave] = []
# id de amenaza -> Mesh. Una malla por tipo, compartida por todos los enemigos de ese tipo.
var _meshes: Dictionary = {}
var _pool: ObjectPool
var _alive_count: int = 0
var _finished := false


func _ready() -> void:
	_pool = ObjectPool.new(enemy_scene, container)
	load_threats(threats_path)
	load_waves(waves_path)


func load_threats(path: String) -> void:
	var raw_threats: Variant = JsonLoader.read_dictionary(path).get("threats", {})
	if raw_threats is Dictionary:
		for id: Variant in raw_threats:
			var data: Variant = raw_threats[id]
			if data is Dictionary:
				threats[str(id)] = Threat.from_dictionary(str(id), data)


func load_waves(path: String) -> void:
	var data := JsonLoader.read_dictionary(path)
	match_duration = maxf(30.0, JsonLoader.read_number(data, "match_duration", match_duration))
	var waves: Array[Wave] = []
	var raw_waves: Variant = data.get("waves", [])
	if raw_waves is Array:
		for item: Variant in raw_waves:
			if item is Dictionary:
				waves.append(Wave.from_dictionary(item))
	if waves.is_empty():
		# Sin oleadas válidas el juego igual debe poder jugarse.
		waves.append(Wave.new())
	# Ordenamos antes de encolar: la cola da por hecho que el frente es la próxima en empezar.
	waves.sort_custom(func(a: Wave, b: Wave) -> bool: return a.start < b.start)
	for wave in waves:
		_pending.enqueue(wave)


## Amenaza por id. Si una oleada nombra un tipo que no está en threats.json, se crea uno genérico
## (una sola vez) para que el juego siga funcionando y el error se vea en la consola.
func get_threat(threat_id: String) -> Threat:
	if not threats.has(threat_id):
		push_error("La amenaza '%s' no está en %s; se usa una genérica." % [threat_id, threats_path])
		threats[threat_id] = Threat.from_dictionary(threat_id, {})
	return threats[threat_id]


## Amenazas débiles ante un hábito (para mostrar "Fuerte contra: ..." en las cartas).
func threats_weak_to(habit_id: String) -> Array[Threat]:
	var result: Array[Threat] = []
	for threat: Threat in threats.values():
		if threat.is_weak_to(habit_id):
			result.append(threat)
	return result


func _physics_process(delta: float) -> void:
	if _finished:
		return
	match_time += delta
	_activate_pending_waves()
	_advance_active_waves(delta)
	if match_time >= match_duration:
		_finished = true
		match_won.emit()


func _activate_pending_waves() -> void:
	# Solo miramos el frente: si a esa todavía no le toca, a ninguna de atrás tampoco.
	while not _pending.is_empty() and (_pending.front() as Wave).start <= match_time:
		var wave := _pending.dequeue() as Wave
		wave.reset()
		_active.append(wave)


func _advance_active_waves(delta: float) -> void:
	# Recorremos al revés para poder quitar oleadas terminadas sin saltarnos ninguna.
	for i in range(_active.size() - 1, -1, -1):
		var wave := _active[i]
		wave.elapsed += delta
		wave.accumulated += delta
		while wave.accumulated >= wave.interval:
			wave.accumulated -= wave.interval
			for _k in wave.per_spawn:
				_spawn(wave)
		if wave.elapsed >= wave.duration:
			_active.remove_at(i)


func _spawn(wave: Wave) -> void:
	if _alive_count >= max_enemies or target == null:
		return
	var threat := get_threat(wave.threat_type)
	if not _meshes.has(threat.id):
		_meshes[threat.id] = Enemy.build_mesh(threat.shape)
	# Punto al azar en un círculo alrededor del jugador: es el componente aleatorio de la aparición.
	var angle := randf() * TAU
	var spawn_position := target.global_position + Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius
	var enemy := _pool.acquire() as Enemy
	if not enemy.killed.is_connected(_on_enemy_killed):
		enemy.killed.connect(_on_enemy_killed)
		enemy.damaged.connect(_on_enemy_damaged)
	enemy.activate(wave, threat, _meshes[threat.id], spawn_position, target)
	_alive_count += 1


func _on_enemy_killed(enemy: Enemy) -> void:
	_alive_count -= 1
	enemy_killed.emit(enemy.threat.xp)


func _on_enemy_damaged(enemy: Enemy, effective: bool) -> void:
	if hit_feedback != null:
		hit_feedback.show_hit(enemy.global_position, effective)


## Texto para el panel del HUD que muestra las estructuras en vivo (en español: lo ve el jugador).
func describe_data_structures() -> String:
	var lines := PackedStringArray()
	lines.append("COLA de oleadas pendientes: %d" % _pending.size())
	var index := 0
	for value: Variant in _pending.to_array():
		if index == 3:
			lines.append("   ...")
			break
		var wave := value as Wave
		var marker := "frente ->" if index == 0 else "         "
		lines.append("  %s %s (seg %d)" % [marker, wave.threat_type, int(wave.start)])
		index += 1
	lines.append("PILA del pool: %d libres / %d creados" % [_pool.available_count(), _pool.created_count()])
	lines.append("Enemigos vivos: %d" % _alive_count)
	return "\n".join(lines)
