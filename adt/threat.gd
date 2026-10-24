class_name Threat
extends RefCounted
## TAD Amenaza: un tipo de riesgo de las redes sociales (notificaciones, troll, etc.).
## Aquí vive la regla central del juego: cada amenaza tiene UN hábito que la contrarresta
## (`weak_to`). Ese hábito le hace el doble de daño; cualquier otro, la mitad.
## Así el jugador aprende la relación "riesgo -> hábito sano" sin que se le pregunte nada.

const EFFECTIVE_MULTIPLIER := 2.0
const RESISTED_MULTIPLIER := 0.5
## Formas válidas. Cada amenaza tiene una silueta distinta para que se reconozca
## sin depender del color (pensado para personas con daltonismo).
const SHAPES := ["sphere", "box", "prism", "torus"]

var id: String = "unknown"
var display_name: String = "Amenaza"
var shape: String = "sphere"
var color: Color = Color(1.0, 0.25, 0.35)
var weak_to: String = ""
var xp: int = 1
var tip: String = ""


static func from_dictionary(p_id: String, data: Dictionary) -> Threat:
	var threat := Threat.new()
	threat.id = p_id
	threat.display_name = str(data.get("name", p_id))
	var requested_shape := str(data.get("shape", threat.shape))
	threat.shape = requested_shape if requested_shape in SHAPES else "sphere"
	threat.color = Color.from_string(str(data.get("color", "")), threat.color)
	threat.weak_to = str(data.get("weak_to", ""))
	threat.xp = clampi(int(JsonLoader.read_number(data, "xp", threat.xp)), 1, 50)
	threat.tip = str(data.get("tip", ""))
	return threat


func is_weak_to(habit_id: String) -> bool:
	return habit_id != "" and habit_id == weak_to


func damage_multiplier(habit_id: String) -> float:
	return EFFECTIVE_MULTIPLIER if is_weak_to(habit_id) else RESISTED_MULTIPLIER
