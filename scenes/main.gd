extends Node3D
## Escena principal: conecta jugador, generador de oleadas y HUD mediante señales.
## Main corre en modo ALWAYS para poder leer "reiniciar" con el juego en pausa;
## los nodos de juego están en PAUSABLE, así que se congelan cuando termina la partida.

@onready var _player: Player = $Player
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _hud: Hud = $Hud

var _kills := 0
var _finished := false


func _ready() -> void:
	_spawner.target = _player
	_player.health_changed.connect(_hud.update_health)
	_player.died.connect(_end_match.bind("La pantalla te consumió.\nPresiona Enter para reintentar."))
	_spawner.match_won.connect(_end_match.bind("¡Sobreviviste el día!\nPresiona Enter para jugar otra vez."))
	_spawner.enemy_killed.connect(_on_enemy_killed)
	_hud.update_health(_player.health, _player.max_health)


func _process(_delta: float) -> void:
	_hud.update_time(_spawner.match_time, _spawner.match_duration)
	_hud.update_data_structures(_spawner.describe_data_structures())


func _unhandled_input(event: InputEvent) -> void:
	if _finished and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_killed() -> void:
	_kills += 1
	_hud.update_kills(_kills)


func _end_match(message: String) -> void:
	if _finished:
		return
	_finished = true
	_hud.show_message(message)
	get_tree().paused = true
