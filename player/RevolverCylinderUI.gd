# File: RevolverCylinderUI.gd
@tool
extends Control
class_name RevolverCylinderUI

## --- Exposed properties ---
@export_range(1, 12, 1) var capacity: int = 6 : set = _set_capacity
@export_range(0, 12, 1) var ammo: int = 6 : set = _set_ammo
@export_range(0, 11, 1) var current_index: int = 0 : set = _set_current_index
@export var clockwise: bool = true : set = _set_clockwise

# Visual tuning (scaled for 320×180)
@export var outer_radius: float = 16.0 : set = _set_outer_radius
@export var chamber_radius: float = 3.5 : set = _set_chamber_radius
@export var ring_thickness: float = 1.0 : set = _set_ring_thickness
@export var gap_from_edge: float = 3.0 : set = _set_gap_from_edge

@export var color_outline: Color = Color(0.9, 0.9, 0.9, 1.0) : set = _redraw
@export var color_fallback_filled: Color = Color(0.95, 0.8, 0.1, 1.0) : set = _redraw
@export var color_empty: Color = Color(0.2, 0.2, 0.2, 1.0) : set = _redraw
@export var color_active: Color = Color(0.2, 0.7, 1.0, 1.0) : set = _redraw
@export var show_center_pivot: bool = true : set = _redraw
@export var show_indices: bool = false : set = _redraw

## Data inputs from game
var chamber_states: Array[bool] = [] : set = _set_chamber_states
var chamber_colors: Array[Color] = [] : set = _set_chamber_colors  # aligns with capacity when used

signal chamber_clicked(index: int)

func set_ammo_count(new_ammo: int) -> void: _set_ammo(new_ammo)
func set_current_index(idx: int) -> void: _set_current_index(idx)
func set_chambers(states: Array[bool]) -> void: _set_chamber_states(states)
func set_chamber_colors(colors: Array[Color]) -> void: _set_chamber_colors(colors)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()

func _minimum_size() -> Vector2:
	var r = outer_radius + ring_thickness + gap_from_edge
	return Vector2(r * 2.0 + 2.0, r * 2.0 + 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _chamber_at_position(event.position)
		if idx != -1:
			emit_signal("chamber_clicked", idx)

func _draw() -> void:
	if capacity <= 0:
		return

	var center := size * 0.5
	var big_r := outer_radius
	var small_r := chamber_radius
	var step := TAU / float(capacity)

	# Disc
	draw_circle(center, big_r, color_outline * Color(1,1,1,0.08))
	draw_arc(center, big_r, 0.0, TAU, 64, color_outline, ring_thickness)
	if show_center_pivot:
		draw_circle(center, 3.0, color_outline)

	# States
	var states: Array[bool] = []
	if chamber_states.is_empty():
		var a := clampi(ammo, 0, capacity)
		for i in capacity: states.append(i < a)
	else:
		states = chamber_states.duplicate()

	# Colors length guard
	if chamber_colors.size() != capacity:
		var fixed: Array[Color] = []
		fixed.resize(capacity)
		for i in capacity:
			fixed[i] = chamber_colors[i] if (i < chamber_colors.size()) else color_fallback_filled
		chamber_colors = fixed

	# Place so current_index points up
	var base_angle := -PI * 0.5
	var dir := 1.0 if clockwise else -1.0

	for i in capacity:
		var chamber_idx := posmod(current_index + int(dir) * i, capacity)
		var angle := base_angle + dir * (step * i)
		var pos := center + Vector2(cos(angle), sin(angle)) * (big_r - gap_from_edge)
		var filled := states[chamber_idx]
		var fill_color := color_empty
		if filled:
			fill_color = chamber_colors[chamber_idx] if chamber_colors.size() == capacity else color_fallback_filled

		draw_circle(pos, small_r, fill_color)
		draw_arc(pos, small_r, 0.0, TAU, 24, color_outline, 1.0)

		if i == 0:
			draw_arc(pos, small_r + 2.5, 0.0, TAU, 28, color_active, 1.5)

		if show_indices:
			var txt := str(chamber_idx)
			var f := get_theme_default_font()
			var fs := 9
			if f:
				var m := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				draw_string(f, pos - m * 0.5 + Vector2(0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color_outline)

func _chamber_at_position(p: Vector2) -> int:
	var center := size * 0.5
	var big_r := outer_radius
	var small_r := chamber_radius
	var step := TAU / float(capacity)
	var base_angle := -PI * 0.5
	var dir := 1.0 if clockwise else -1.0
	for i in capacity:
		var angle := base_angle + dir * (step * i)
		var pos := center + Vector2(cos(angle), sin(angle)) * (big_r - gap_from_edge)
		if p.distance_to(pos) <= small_r + 3.0:
			return posmod(current_index + int(dir) * i, capacity)
	return -1

# --- Setters that actually store values (so Inspector works) ---
func _set_capacity(v: int) -> void:
	capacity = max(1, v)
	ammo = clampi(ammo, 0, capacity)
	if not chamber_states.is_empty():
		var s: Array[bool] = []
		for i in capacity: s.append(i < chamber_states.size() and bool(chamber_states[i]))
		chamber_states = s
	if not chamber_colors.is_empty():
		var c: Array[Color] = []
		for i in capacity: c.append(chamber_colors[i] if i < chamber_colors.size() else color_fallback_filled)
		chamber_colors = c
	queue_redraw()

func _set_ammo(v: int) -> void:
	ammo = clampi(v, 0, capacity)
	queue_redraw()

func _set_current_index(v: int) -> void:
	current_index = posmod(v, max(1, capacity))
	queue_redraw()

func _set_clockwise(v: bool) -> void:
	clockwise = v
	queue_redraw()

func _set_outer_radius(v: float) -> void:
	outer_radius = v
	queue_redraw()

func _set_chamber_radius(v: float) -> void:
	chamber_radius = v
	queue_redraw()

func _set_ring_thickness(v: float) -> void:
	ring_thickness = v
	queue_redraw()

func _set_gap_from_edge(v: float) -> void:
	gap_from_edge = v
	queue_redraw()

func _redraw(_v = null) -> void:
	queue_redraw()

func _set_chamber_states(states: Array[bool]) -> void:
	chamber_states = states.duplicate()
	queue_redraw()

func _set_chamber_colors(colors: Array[Color]) -> void:
	chamber_colors = colors.duplicate()
	queue_redraw()
