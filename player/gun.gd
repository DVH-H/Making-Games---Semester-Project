extends Node2D
class_name Gun

signal ammo_changed(current_ammo: int)
signal chamber_changed(current_index: int)
signal chambers_updated(states: Array[bool])
signal chamber_colors_updated(colors: Array[Color])
signal dry_fire()
signal fired(bullet_instance: Node)
signal reload_started(chamber_index: int, duration: float)
signal reload_finished(chamber_index: int)

@onready var muzzle: Marker2D = $Marker2D

@export_group("Revolver")
@export_range(1, 12, 1) var capacity: int = 6
@export_range(0, 11, 1) var current_index: int = 0
@export var clockwise: bool = true

@export_group("Rounds")
@export var normal_round: PackedScene = preload("res://Bullets/prefabs/bullet.tscn")
@export var knockback_round: PackedScene = preload("res://Bullets/prefabs/knockback_bullet.tscn")

# Single source of truth: what’s actually loaded now (null = empty)
var chambers: Array[PackedScene] = []

# Loadout “blueprint”: which scene each chamber should contain when topped up
var loadout_scenes: Array[PackedScene] = []

# Caches to avoid re-instantiating scenes to read properties
var _load_time_cache: Dictionary = {}  # path -> float
var _ui_color_cache: Dictionary = {}   # path -> Color
var _is_reloading: bool = false

func _ready() -> void:
	_resize_arrays()
	_set_default_alternating_loadout()
	_fill_all_from_loadout()  # start full; remove if you want to start empty
	current_index = posmod(current_index, capacity)
	_emit_all()

func shoot(direction: Vector2) -> float:
	var force := 0.0
	var scene := chambers[current_index]
	if scene != null and not _is_reloading:
		var bullet := scene.instantiate()
		get_tree().root.add_child(bullet)
		if "global_position" in bullet:
			bullet.global_position = muzzle.global_position
		if bullet.has_method("initialize"):
			bullet.initialize(direction)
		if "knockback_force" in bullet:
			force = float(bullet.knockback_force)
		emit_signal("fired", bullet)
		chambers[current_index] = null
	else:
		emit_signal("dry_fire")

	_advance_cylinder()
	_emit_all()
	return force

func aim(dir: Vector2) -> void:
	var stick_dir := Vector2.ZERO
	if len(Input.get_connected_joypads()) > 0:
		stick_dir = dir
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()
		stick_dir = (mouse_pos - global_position).normalized()
	look_at(global_position + stick_dir)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	scale.y = -1 if rotation_degrees > 90 and rotation_degrees < 270 else 1

func reload_all_to_loadout() -> void:
	if _is_reloading:
		return
	var order: Array[int] = []
	for i in capacity:
		var idx := posmod(current_index - i, capacity)
		if chambers[idx] == null and loadout_scenes[idx] != null:
			order.append(idx)
	if order.is_empty():
		return

	_is_reloading = true
	for idx in order:
		if chambers[idx] != null:
			continue
		var scene := loadout_scenes[idx]
		if scene == null:
			continue

		var delay := _get_round_load_time(scene)
		emit_signal("reload_started", idx, delay)
		await get_tree().create_timer(delay).timeout
		if chambers[idx] == null:
			chambers[idx] = scene
			_emit_all()
		emit_signal("reload_finished", idx)
	_is_reloading = false

# ── Loadout helpers ──────────────────────────────────────────────────────────
func _set_default_alternating_loadout() -> void:
	for i in capacity:
		loadout_scenes[i] = (normal_round if (i % 2) == 0 else knockback_round)
		
func _fill_all_from_loadout() -> void:
	for i in capacity:
		chambers[i] = loadout_scenes[i]
# ── Notify HUD ───────────────────────────────────────────────────────────────
func _emit_all() -> void:
	emit_signal("ammo_changed", get_ammo_count())
	emit_signal("chamber_changed", current_index)
	emit_signal("chambers_updated", _states_from(chambers))
	emit_signal("chamber_colors_updated", _colors_from(chambers))  # <- derived from bullet.ui_color

# ── Small utilities ──────────────────────────────────────────────────────────
func get_ammo_count() -> int:
	var c := 0
	for i in capacity:
		if chambers[i] != null:
			c += 1
	return c

func _advance_cylinder() -> void:
	current_index = posmod(current_index + 1, capacity)
	emit_signal("chamber_changed", current_index)

func _resize_arrays() -> void:
	chambers.resize(capacity)
	loadout_scenes.resize(capacity)
	for i in capacity:
		if chambers[i] == null:
			chambers[i] = null
		if loadout_scenes[i] == null:
			loadout_scenes[i] = null

func _find_next_empty_slot_from_current() -> int:
	for i in capacity:
		var idx := posmod(current_index - i, capacity)
		if chambers[idx] == null and loadout_scenes[idx] != null:
			return idx
	return -1

# Build bool array once per emit (no stored duplicate state)
func _states_from(src: Array[PackedScene]) -> Array[bool]:
	var out: Array[bool] = []
	out.resize(capacity)
	for i in capacity:
		out[i] = (src[i] != null)
	return out

# Build color array from bullet.ui_color (cached by resource path)
func _colors_from(src: Array[PackedScene]) -> Array[Color]:
	var out: Array[Color] = []
	out.resize(capacity)
	for i in capacity:
		var scene := src[i]
		out[i] = _get_round_ui_color(scene) if scene != null else Color.TRANSPARENT
	return out

# ── Caches for load_time and ui_color on bullet scenes ───────────────────────
func _get_round_load_time(scene: PackedScene) -> float:
	if scene == null:
		return 0.2
	var key := scene.resource_path
	if _load_time_cache.has(key):
		return float(_load_time_cache[key])
	var t := 0.2
	var node := scene.instantiate()
	if node and "load_time" in node:
		t = float(node.load_time)
	if node:
		node.queue_free()
	_load_time_cache[key] = t
	return t

func _get_round_ui_color(scene: PackedScene) -> Color:
	if scene == null:
		return Color.TRANSPARENT
	var key := scene.resource_path
	if _ui_color_cache.has(key):
		return _ui_color_cache[key]
	var col := Color.TRANSPARENT
	var node := scene.instantiate()
	if node and "ui_color" in node:
		col = node.ui_color
	if node:
		node.queue_free()
	_ui_color_cache[key] = col
	return col
	
func get_chamber_colors() -> Array[Color]:
	return _colors_from(chambers)
