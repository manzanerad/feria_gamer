class_name Hud
extends CanvasLayer
## Interfaz encima del mundo 3D: vida, tiempo, eliminados y el panel que muestra
## en vivo el estado de las estructuras de datos (cola de oleadas y pila del pool).
## Los textos que ve el jugador siguen en español porque el público de la feria es hispanohablante.

@onready var _health_bar: ProgressBar = $Status/HealthBar
@onready var _time_label: Label = $Status/TimeLabel
@onready var _kills_label: Label = $Status/KillsLabel
@onready var _data_structures_panel: Label = $DataStructuresPanel
@onready var _end_message: Label = $EndMessage


func update_health(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func update_time(seconds: float, total: float) -> void:
	_time_label.text = "%s / %s" % [_format_clock(seconds), _format_clock(total)]


func update_kills(count: int) -> void:
	_kills_label.text = "Eliminados: %d" % count


func update_data_structures(text: String) -> void:
	_data_structures_panel.text = text


func show_message(text: String) -> void:
	_end_message.text = text
	_end_message.visible = true


func _format_clock(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]
