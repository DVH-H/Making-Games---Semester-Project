# File: LoadoutMenu.gd
# UI for customizing the gun loadout
extends Control
class_name LoadoutMenu

var bullet_list: ItemList
var apply_button: Button
var cancel_button: Button

var working_loadout: Array[PackedScene] = []
var original_loadout: Array[PackedScene] = []

signal loadout_applied(loadout: Array[PackedScene])
signal menu_closed()
signal bullet_selected(bullet_scene: PackedScene)

func _get_node_references() -> void:
	# Get UI nodes
	bullet_list = get_node_or_null("VBoxContainer/BulletList")
	apply_button = get_node_or_null("VBoxContainer/ButtonContainer/ApplyButton")
	cancel_button = get_node_or_null("VBoxContainer/ButtonContainer/CancelButton")

func _ready() -> void:
	# Set process mode to always process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start with input ignored
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_get_node_references()
	_setup_ui()
	_connect_signals()
	_populate_bullet_list()
	visible = false

func _setup_ui() -> void:
	# Check if LoadoutManager is available
	if not LoadoutManager:
		push_error("LoadoutMenu: LoadoutManager autoload not found!")
		return
	
	# Configure bullet list
	if bullet_list:
		bullet_list.set_max_columns(1)
		bullet_list.fixed_column_width = 180

func _connect_signals() -> void:
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if bullet_list:
		bullet_list.item_selected.connect(_on_bullet_selected)

func _populate_bullet_list() -> void:
	print("LoadoutMenu: _populate_bullet_list called")
	if not bullet_list:
		print("LoadoutMenu: bullet_list is null!")
		return
	
	bullet_list.clear()
	print("LoadoutMenu: bullet_list cleared")
	
	# Add "Empty" option
	bullet_list.add_item("Empty Chamber")
	bullet_list.set_item_metadata(0, null)
	print("LoadoutMenu: Added Empty Chamber")
	
	# Add available bullets
	if not LoadoutManager:
		print("LoadoutMenu: LoadoutManager is null!")
		return
		
	var available_bullets = LoadoutManager.get_available_bullets()
	print("LoadoutMenu: Found ", available_bullets.size(), " available bullets")
	for i in range(available_bullets.size()):
		var bullet_scene = available_bullets[i]
		var bullet = LoadoutManager.get_bullet_info(bullet_scene)
		var item_text = bullet.display_name if bullet else "Unknown Bullet"
		
		print("LoadoutMenu: Adding bullet ", i, ": ", item_text)
		var item_index = bullet_list.add_item(item_text)
		bullet_list.set_item_metadata(item_index, bullet_scene)
		
		# Set color if available
		if bullet:
			bullet_list.set_item_custom_bg_color(item_index, bullet.ui_color * Color(1, 1, 1, 0.3))
		
			# Set tooltip with detailed info
			var tooltip = "%s\nDamage: %.0f\nSpeed: %d\nLoad Time: %.1fs" % [
				bullet.display_name,
				bullet.damage,
				bullet.SPEED,
				bullet.load_time
			]
			bullet_list.set_item_tooltip(item_index, tooltip)
	
	print("LoadoutMenu: Finished populating bullet list. Total items: ", bullet_list.get_item_count())

func open_menu() -> void:
	if not LoadoutManager:
		push_error("LoadoutMenu: LoadoutManager not available")
		return
		
	# Store original loadout for cancel functionality
	original_loadout = LoadoutManager.get_loadout()
	working_loadout = original_loadout.duplicate()
	
	visible = true
	# Pause the game
	get_tree().paused = true
	# Block input to prevent background shooting
	mouse_filter = Control.MOUSE_FILTER_STOP

func close_menu() -> void:
	visible = false
	# Unpause the game
	get_tree().paused = false
	# Restore input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	emit_signal("menu_closed")

func _on_apply_pressed() -> void:
	if not LoadoutManager:
		return
		
	LoadoutManager.set_loadout(working_loadout)
	emit_signal("loadout_applied", working_loadout)
	close_menu()

func _on_cancel_pressed() -> void:
	# Restore original loadout
	working_loadout = original_loadout.duplicate()
	close_menu()

func _on_bullet_selected(index: int) -> void:
	if not bullet_list:
		return
	
	var bullet_scene = bullet_list.get_item_metadata(index) as PackedScene
	if bullet_scene:
		var bullet = LoadoutManager.get_bullet_info(bullet_scene)
		if bullet:
			print("  - Display Name: ", bullet.display_name)
			print("  - Damage: ", bullet.damage)
			print("  - Speed: ", bullet.SPEED)
	else:
		print("  - Empty chamber selected")
	
	emit_signal("bullet_selected", bullet_scene)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("loadout_menu"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		open_menu()
