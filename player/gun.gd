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

@export var normal_color: Color = Color.hex(0x6ec1e4ff)
@export var knockback_color: Color = Color.hex(0xf5c542ff)

# Runtime cylinder
var chambers: Array[PackedScene] = []
var colors: Array[Color] = []

# Loadout mapping (what each chamber SHOULD contain)
var loadout_scenes: Array[PackedScene] = []
var loadout_colors: Array[Color] = []

# Reload state
var _is_reloading: bool = false
var _load_time_cache: Dictionary = {}  # resource_path -> float

func _ready() -> void:
	_resize_all_arrays()
	_set_default_alternating_loadout()
	_fill_all_from_loadout()  # start full; remove if you want to start empty
	current_index = posmod(current_index, capacity)
	_emit_all()


func shoot(direction: Vector2) -> float:
	var force: float = 0.0
	var round_scene: PackedScene = chambers[current_index]

	if round_scene != null:
		var bullet := round_scene.instantiate()
		get_tree().root.add_child(bullet)

		if "global_position" in bullet:
			bullet.global_position = muzzle.global_position
		if bullet.has_method("initialize"):
			bullet.initialize(direction)
		if "knockback_force" in bullet:
			force = float(bullet.knockback_force)

		emit_signal("fired", bullet)

		chambers[current_index] = null
		colors[current_index] = Color.TRANSPARENT
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
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1

# -----------------------
# Reload: ONE bullet to match loadout (with per-bullet load_time)
# -----------------------

func reload_all_to_loadout() -> void:
	if _is_reloading:
		return

	# Build the sequence of chambers to load (nearest first, scanning backward from current_index)
	var order: Array[int] = []
	for i in capacity:
		var idx := posmod(current_index - i, capacity)
		if chambers[idx] == null and loadout_scenes[idx] != null:
			order.append(idx)

	if order.is_empty():
		return

	_is_reloading = true

	for idx in order:
		# In case something loaded this slot while we waited
		if chambers[idx] != null:
			continue

		var scene := loadout_scenes[idx]
		if scene == null:
			continue

		var delay := _get_round_load_time(scene)
		emit_signal("reload_started", idx, delay)

		# Wait the per-bullet load time
		await get_tree().create_timer(delay).timeout

		# If still empty, insert and notify
		if chambers[idx] == null:
			chambers[idx] = scene
			colors[idx] = loadout_colors[idx]
			_emit_all()

		emit_signal("reload_finished", idx)

	# Done reloading this batch
	_is_reloading = false


# Optional: full refill to loadout instantly (not used by single-step reload)
func force_refill_from_loadout() -> void:
	_fill_all_from_loadout()
	_emit_all()

# -----------------------
# Loadout helpers
# -----------------------

func _set_default_alternating_loadout() -> void:
	for i in capacity:
		var is_normal := (i % 2 == 0)
		loadout_scenes[i] = (normal_round if is_normal else knockback_round)
		loadout_colors[i] = (normal_color if is_normal else knockback_color)

func set_loadout(scenes: Array[PackedScene], colors_in: Array[Color], fill_now: bool = false) -> void:
	if scenes.size() != capacity or colors_in.size() != capacity:
		push_warning("set_loadout: arrays must be length == capacity")
		return
	loadout_scenes = scenes.duplicate()
	loadout_colors = colors_in.duplicate()
	if fill_now:
		_fill_all_from_loadout()
	_emit_all()

# -----------------------
# Utility & signals
# -----------------------

func get_ammo_count() -> int:
	var c := 0
	for i in capacity:
		if chambers[i] != null:
			c += 1
	return c

func _advance_cylinder() -> void:
	current_index = posmod(current_index + 1, capacity)
	emit_signal("chamber_changed", current_index)

func _emit_all() -> void:
	emit_signal("ammo_changed", get_ammo_count())
	emit_signal("chamber_changed", current_index)
	emit_signal("chambers_updated", _bool_states())
	emit_signal("chamber_colors_updated", colors.duplicate())

func _bool_states() -> Array[bool]:
	var states: Array[bool] = []
	states.resize(capacity)
	for i in capacity:
		states[i] = (chambers[i] != null)
	return states

func _fill_all_from_loadout() -> void:
	for i in capacity:
		chambers[i] = loadout_scenes[i]
		colors[i] = (loadout_colors[i] if loadout_scenes[i] != null else Color.TRANSPARENT)

func _resize_all_arrays() -> void:
	chambers.resize(capacity)
	colors.resize(capacity)
	loadout_scenes.resize(capacity)
	loadout_colors.resize(capacity)
	for i in capacity:
		if chambers[i] == null:
			chambers[i] = null
		if colors[i] == null:
			colors[i] = Color.TRANSPARENT

# Choose the next empty chamber to load, scanning backward from current_index (feels nice during combat)
func _find_next_empty_slot_from_current() -> int:
	for i in capacity:
		var idx := posmod(current_index - i, capacity)
		if chambers[idx] == null and loadout_scenes[idx] != null:
			return idx
	return -1

# Reads @export var load_time: float from a bullet scene (cached by resource_path)
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
