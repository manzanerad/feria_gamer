class_name PulseHabit
extends HabitBehavior
## Hábito "Modo descanso": cada cierto tiempo lanza una onda que daña y EMPUJA
## a los enemigos cercanos. El empujón da espacio para respirar, que es justo la idea
## de alejarse un rato de la pantalla. Fuerte contra el doomscroll (rápido e insistente).

const WAVE_DURATION := 0.35

var _radius := 5.0
var _damage := 12.0
var _cooldown := 3.0
var _knockback := 7.0
var _timer := 0.0
var _tween: Tween

@onready var _ring: MeshInstance3D = $Ring
var _ring_material: StandardMaterial3D


func _ready() -> void:
	# Material propio para poder animar su transparencia sin afectar otras instancias.
	_ring_material = (_ring.mesh as PrimitiveMesh).material.duplicate() as StandardMaterial3D
	_ring.material_override = _ring_material
	_ring.visible = false
	# La primera onda sale a mitad del tiempo de espera, para que el jugador vea pronto qué hace.
	_timer = _cooldown * 0.5


func configure(stats: Dictionary) -> void:
	_radius = clampf(stat(stats, "radius", _radius), 1.0, 20.0)
	_damage = maxf(0.0, stat(stats, "damage", _damage))
	_cooldown = maxf(0.3, stat(stats, "cooldown", _cooldown))
	_knockback = maxf(0.0, stat(stats, "knockback", _knockback))


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _cooldown
	_emit_pulse()


func _emit_pulse() -> void:
	var radius_squared := _radius * _radius
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() <= radius_squared:
			enemy.take_damage(_damage, habit_id)
			enemy.knock_back(offset.normalized() * _knockback)
	_play_ring_animation()


func _play_ring_animation() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_ring.visible = true
	_tween = create_tween()
	_tween.tween_property(_ring, "scale", Vector3(_radius, 1.0, _radius), WAVE_DURATION).from(Vector3(0.3, 1.0, 0.3))
	_tween.parallel().tween_property(_ring_material, "albedo_color:a", 0.0, WAVE_DURATION).from(0.8)
	_tween.tween_callback(_ring.hide)
