class_name LevelUpPanel
extends CanvasLayer
## Pantalla de subida de nivel: muestra hasta 3 cartas de hábito y espera a que el jugador elija una.
## Corre en modo ALWAYS porque aparece con el juego en pausa.
## Es una vista "tonta": no sabe de multilistas ni de amenazas; Main le pasa los datos ya armados
## (un diccionario por carta) y ella solo dibuja y avisa cuál se eligió.

signal habit_chosen(habit_id: String)

const CARD_WIDTH := 290.0

var _card_ids := PackedStringArray()
# Evita elegir dos veces si el jugador hace doble clic o presiona dos teclas seguidas.
var _waiting_choice := false

@onready var _title: Label = $Center/Content/Title
@onready var _cards: HBoxContainer = $Center/Content/Cards


## Cada carta: {id, name, badge, summary, strong_against, color, tip}.
func show_cards(title: String, cards: Array[Dictionary]) -> void:
	_title.text = title
	# remove_child antes de queue_free: queue_free borra al final del cuadro,
	# y mientras tanto las cartas viejas seguirían contando como hijas del contenedor.
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	_card_ids.clear()
	for i in cards.size():
		_card_ids.append(str(cards[i].get("id", "")))
		_cards.add_child(_build_card(cards[i], i))
	visible = true
	_waiting_choice = true
	# Foco en la primera carta: así también se puede elegir con flechas + Enter (accesibilidad).
	if _cards.get_child_count() > 0:
		var first_button := _cards.get_child(0).find_child("ChooseButton", true, false) as Button
		if first_button != null:
			first_button.grab_focus.call_deferred()


func close() -> void:
	visible = false
	_waiting_choice = false


func _build_card(card: Dictionary, index: int) -> Control:
	var accent: Color = card.get("color", Color.WHITE)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(_make_label(str(card.get("name", "")), 24, Color.WHITE))
	column.add_child(_make_label(str(card.get("badge", "")), 18, accent))
	column.add_child(_make_label(str(card.get("summary", "")), 17, Color(0.85, 0.85, 0.9)))
	column.add_child(_make_label("Fuerte contra: " + str(card.get("strong_against", "-")), 17, accent))
	column.add_child(_make_label(str(card.get("tip", "")), 15, Color(0.7, 0.75, 0.85)))

	var button := Button.new()
	button.name = "ChooseButton"
	button.text = "Elegir  [%d]" % (index + 1)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(_choose.bind(index))
	column.add_child(button)
	return panel


func _make_label(content: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(CARD_WIDTH - 32.0, 0.0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _waiting_choice:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Teclas 1, 2, 3 (fila superior o teclado numérico). Cualquier otra tecla se ignora.
	var index := -1
	match key.physical_keycode:
		KEY_1, KEY_KP_1:
			index = 0
		KEY_2, KEY_KP_2:
			index = 1
		KEY_3, KEY_KP_3:
			index = 2
	if index >= 0:
		get_viewport().set_input_as_handled()
		_choose(index)


func _choose(index: int) -> void:
	# Índice fuera de rango (por ejemplo, tecla 3 cuando solo hay 2 cartas): no hace nada.
	if not _waiting_choice or index < 0 or index >= _card_ids.size():
		return
	_waiting_choice = false
	habit_chosen.emit(_card_ids[index])
