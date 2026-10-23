class_name WaveSpawner
extends Node
## Lee las oleadas de un archivo JSON, las guarda en nuestra Queue ordenadas por segundo
## de inicio y las va activando cuando llega su momento.
## La cola encaja porque las oleadas se consumen en el mismo orden en que se programaron:
## solo hace falta mirar el frente para saber si ya le toca a la siguiente.

signal enemy_killed
signal match_won

@export var enemy_scene: PackedScene
@export var container: Node3D
@export_file("*.json") var waves_path: String = "res://data/waves.json"
## Distancia al jugador donde aparecen: un poco más allá de lo que alcanza a ver la cámara.
@export var spawn_radius: float = 24.0
## Tope de enemigos vivos para que el rendimiento no se caiga.
@export var max_enemies: int = 250

var target: Node3D
var match_time: float = 0.0
var match_duration: float = 300.0

var _pending := Queue.new()
# Oleadas que ya empezaron. Array solo como almacenamiento interno: la estructura
# que se evalúa aquí es la Queue de pendientes.
var _active: Array[Wave] = []
var _pool: ObjectPool
var _alive_count: int = 0
var _finished := false


func _ready() -> void:
	_pool = ObjectPool.new(enemy_scene, container)
	load_waves(waves_path)


func load_waves(path: String) -> void:
	var data := _read_json(path)
	match_duration = maxf(30.0, Wave.read_number(data, "match_duration", match_duration))
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


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("No existe %s; se usará una oleada por defecto." % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("%s tiene un error en la línea %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


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
	# Punto al azar en un círculo alrededor del jugador: es el componente aleatorio de la aparición.
	var angle := randf() * TAU
	var spawn_position := target.global_position + Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius
	var enemy := _pool.acquire() as Enemy
	if not enemy.killed.is_connected(_on_enemy_killed):
		enemy.killed.connect(_on_enemy_killed)
	enemy.activate(wave, spawn_position, target)
	_alive_count += 1


func _on_enemy_killed(_enemy: Enemy) -> void:
	_alive_count -= 1
	enemy_killed.emit()


## Texto para el panel del HUD que muestra las estructuras en vivo (en español: lo ve el jugador).
func describe_data_structures() -> String:
	var lines := PackedStringArray()
	lines.append("COLA de oleadas pendientes: %d" % _pending.size())
	var index := 0
	for value: Variant in _pending.to_array():
		if index == 4:
			lines.append("   ...")
			break
		var wave := value as Wave
		var marker := "frente ->" if index == 0 else "         "
		lines.append("  %s %s (seg %d)" % [marker, wave.threat_type, int(wave.start)])
		index += 1
	lines.append("Oleadas activas: %d" % _active.size())
	lines.append("PILA del pool: %d libres / %d creados" % [_pool.available_count(), _pool.created_count()])
	lines.append("Enemigos vivos: %d" % _alive_count)
	return "\n".join(lines)
