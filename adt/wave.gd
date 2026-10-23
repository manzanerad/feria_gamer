class_name Wave
extends RefCounted
## TAD Oleada: un grupo de amenazas que aparece durante un tramo de la partida.
## Se construye desde el JSON de data/waves.json y valida cada campo:
## si el archivo trae un valor raro (texto donde va un número, negativos, etc.)
## se usa un valor por defecto en vez de romper el juego (requisito de confiabilidad).

var threat_type: String = "notification"
var start: float = 0.0         # segundo de la partida en que empieza
var duration: float = 30.0     # cuántos segundos sigue generando enemigos
var interval: float = 1.0      # segundos entre cada grupo
var per_spawn: int = 1         # enemigos por grupo
var health: float = 10.0
var speed: float = 3.0
var color: Color = Color(1.0, 0.25, 0.35)

# Estado mientras la oleada está activa (no viene del archivo).
var elapsed: float = 0.0
var accumulated: float = 0.0


static func from_dictionary(data: Dictionary) -> Wave:
	var wave := Wave.new()
	wave.threat_type = str(data.get("type", wave.threat_type))
	wave.start = maxf(0.0, read_number(data, "start", wave.start))
	wave.duration = maxf(1.0, read_number(data, "duration", wave.duration))
	# Mínimo 0.1 s: un intervalo de 0 haría un bucle infinito de apariciones.
	wave.interval = maxf(0.1, read_number(data, "interval", wave.interval))
	wave.per_spawn = clampi(int(read_number(data, "per_spawn", wave.per_spawn)), 1, 20)
	wave.health = maxf(1.0, read_number(data, "health", wave.health))
	wave.speed = clampf(read_number(data, "speed", wave.speed), 0.5, 15.0)
	wave.color = Color.from_string(str(data.get("color", "")), wave.color)
	return wave


## Devuelve el número guardado en `key` o `default_value` si no existe o no es un número.
static func read_number(data: Dictionary, key: String, default_value: float) -> float:
	var value: Variant = data.get(key, default_value)
	if value is float or value is int:
		return float(value)
	return default_value


func reset() -> void:
	elapsed = 0.0
	# Empieza "lleno" para que el primer grupo salga apenas arranca la oleada.
	accumulated = interval
