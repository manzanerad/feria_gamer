extends Node3D
## Escena principal: conecta jugador, generador de oleadas, HUD y panel de subida de nivel.
## Main corre en modo ALWAYS para poder leer "reiniciar" con el juego en pausa;
## los nodos de juego están en PAUSABLE, así que se congelan al subir de nivel o al terminar.

const CARDS_PER_LEVEL := 3
## Cuando ya no quedan mejoras, subir de nivel cura en vez de mostrar cartas.
const HEAL_WHEN_MAXED := 25.0

@onready var _player: Player = $Player
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _hud: Hud = $Hud
@onready var _level_up_panel: LevelUpPanel = $LevelUpPanel

var _kills := 0
var _finished := false
# Elecciones pendientes: si se suben 2 niveles de golpe, se muestran 2 rondas de cartas seguidas.
var _pending_choices := 0


func _ready() -> void:
	_spawner.target = _player
	_player.health_changed.connect(_hud.update_health)
	_player.experience_changed.connect(_hud.update_experience)
	_player.leveled_up.connect(_on_player_leveled_up)
	_player.died.connect(_end_match.bind("La pantalla te consumió.\nPresiona Enter para reintentar."))
	_player.habits.habits_changed.connect(_on_habits_changed)
	_spawner.match_won.connect(_end_match.bind("¡Sobreviviste el día!\nPresiona Enter para jugar otra vez."))
	_spawner.enemy_killed.connect(_on_enemy_killed)
	_level_up_panel.habit_chosen.connect(_on_habit_chosen)
	_hud.update_health(_player.health, _player.max_health)
	_hud.update_experience(_player.experience, _player.experience_to_next_level(), _player.level)
	# El jugador empieza sin hábitos: la primera decisión de la partida es elegir uno.
	_pending_choices = 1
	_offer_next_choice("Elige tu primer hábito")


func _process(_delta: float) -> void:
	_hud.update_time(_spawner.match_time, _spawner.match_duration)
	_hud.update_data_structures(_spawner.describe_data_structures() + "\n" + _player.habits.catalog.describe())


func _unhandled_input(event: InputEvent) -> void:
	if _finished and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_killed(experience: int) -> void:
	_kills += 1
	_hud.update_kills(_kills)
	_player.add_experience(experience)


func _on_player_leveled_up() -> void:
	_pending_choices += 1
	# Si el panel ya está abierto, esta elección se mostrará cuando termine la actual.
	if not _level_up_panel.visible:
		_offer_next_choice("¡Subiste de nivel! Elige un hábito")


func _offer_next_choice(title: String) -> void:
	var offers := _player.habits.random_offers(CARDS_PER_LEVEL)
	if offers.is_empty():
		_pending_choices = 0
		_player.heal(HEAL_WHEN_MAXED)
		return
	var cards: Array[Dictionary] = []
	for habit in offers:
		cards.append(_build_card(habit))
	get_tree().paused = true
	_level_up_panel.show_cards(title, cards)


## Arma los datos de una carta. Aquí se juntan las dos fuentes: el hábito (multilista)
## y las amenazas que contrarresta (threats.json).
func _build_card(habit: Habit) -> Dictionary:
	var next_level := habit.level + 1
	var stats := _player.habits.catalog.stats_for(habit.id, next_level)
	var countered := _spawner.threats_weak_to(habit.id)
	var names := PackedStringArray()
	for threat in countered:
		names.append(threat.display_name)
	var badge := "NUEVO" if habit.level == 0 else "Nivel %d -> %d" % [habit.level, next_level]
	var summary := str(stats.get("summary", ""))
	if habit.level == 0 and habit.description != "":
		summary = habit.description + " " + summary
	return {
		"id": habit.id,
		"name": habit.display_name,
		"badge": badge,
		"summary": summary,
		"strong_against": ", ".join(names) if not names.is_empty() else "-",
		"color": countered[0].color if not countered.is_empty() else Color.WHITE,
		"tip": habit.tip,
	}


func _on_habit_chosen(habit_id: String) -> void:
	_player.habits.apply_upgrade(habit_id)
	_pending_choices -= 1
	if _pending_choices > 0:
		_offer_next_choice("¡Subiste de nivel! Elige un hábito")
	else:
		_level_up_panel.close()
		get_tree().paused = false


func _on_habits_changed() -> void:
	_hud.update_habits(_player.habits.describe_owned())


func _end_match(message: String) -> void:
	if _finished:
		return
	_finished = true
	_hud.show_message(message)
	get_tree().paused = true
