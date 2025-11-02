# File: reload_bar.gd
extends Control
class_name ReloadBarControl

@export var player_path: NodePath
@export var gun_path: NodePath

# Visuals for 320×180
@export var size_px: Vector2i = Vector2i(22, 3)
@export var offset_px: Vector2i = Vector2i(0, 18)   # below player
@export var border_px: int = 1

@export var color_bg: Color = Color.hex(0x00000080)
@export var color_fg: Color = Color.hex(0xF5C542FF)
@export var color_border: Color = Color.hex(0x000000FF)

var _player: Node2D
var _gun: Node
var _active := false
var _duration := 0.2
var _elapsed := 0.0

func _ready() -> void:
	visible = false
	_player = get_node_or_null(player_path)
	_gun = get_node_or_null(gun_path)

	if _gun:
		# gun emits: reload_started(chamber_index: int, duration: float), reload_finished(chamber_index: int)
		_gun.reload_started.connect(_on_reload_started)
		_gun.reload_finished.connect(_on_reload_finished)

	custom_minimum_size = Vector2(size_px.x, size_px.y)
	set_anchors_preset(Control.PRESET_TOP_LEFT)

func _process(delta: float) -> void:
	_update_screen_position()

	if not _active:
		return

	_elapsed = min(_elapsed + delta, _duration)
	queue_redraw()

	if _elapsed >= _duration:
		_active = false
		visible = false

func _draw() -> void:
	if not visible:
		return

	var w: int = size_px.x
	var h: int = size_px.y

	# background
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), color_bg, true)

	# fill
	var p := clampf(_elapsed / _duration, 0.0, 1.0)
	var fill_w := int(round(w * p))
	if fill_w > 0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, h)), color_fg, true)

	# border
	if border_px > 0:
		draw_line(Vector2(0, 0), Vector2(w, 0), color_border, border_px)
		draw_line(Vector2(0, h), Vector2(w, h), color_border, border_px)
		draw_line(Vector2(0, 0), Vector2(0, h), color_border, border_px)
		draw_line(Vector2(w, 0), Vector2(w, h), color_border, border_px)

func _on_reload_started(_idx: int, duration: float) -> void:
	_duration = max(0.001, duration)
	_elapsed = 0.0
	_active = true
	visible = true
	queue_redraw()

func _on_reload_finished(_idx: int) -> void:
	# We let _process hide it at the end of the current bullet's duration.
	pass

func _update_screen_position() -> void:
	if not _player:
		_player = get_node_or_null(player_path)
		if not _player:
			return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var world := _player.global_position
	var zoom := cam.zoom
	var screen_center := get_viewport_rect().size * 0.5
	var screen := (world - cam.global_position) * zoom + screen_center
	screen = Vector2(round(screen.x), round(screen.y))

	# place this control so its top-left sits at (screen + offset - half width)
	var pos := screen + Vector2(offset_px) - Vector2(size_px.x / 2, 0)
	position = pos
