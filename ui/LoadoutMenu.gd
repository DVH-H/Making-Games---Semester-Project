# File: LoadoutMenu.gd
# UI for customizing the gun loadout
extends Control
class_name LoadoutMenu

var bullet_list: ItemList
var apply_button: Button
var cancel_button: Button
var chamber_container: VBoxContainer
var chamber_grid: GridContainer
var chamber_buttons: Array[Button] = []

var working_loadout: Array[PackedScene] = []
var original_loadout: Array[PackedScene] = []
var selected_chamber_index: int = -1
var gun_reference: Gun = null

signal loadout_applied(loadout: Array[PackedScene])
signal menu_closed()
signal bullet_selected(bullet_scene: PackedScene)

func _get_node_references() -> void:
	# Get UI nodes
	bullet_list = get_node_or_null("VBoxContainer/ContentContainer/BulletList")
	apply_button = get_node_or_null("VBoxContainer/ButtonContainer/ApplyButton")
	cancel_button = get_node_or_null("VBoxContainer/ButtonContainer/CancelButton")
	chamber_container = get_node_or_null("VBoxContainer/ContentContainer/ChamberContainer")

func _ready() -> void:
	# Set process mode to always process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start with input ignored
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_get_node_references()
	_setup_ui()
	_setup_chamber_display()
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
		bullet_list.fixed_column_width = 120

func _setup_chamber_display() -> void:
	if not chamber_container:
		push_error("LoadoutMenu: Chamber container not found!")
		return
	
	# Create chamber grid
	chamber_grid = GridContainer.new()
	chamber_grid.name = "ChamberGrid"
	chamber_grid.columns = 3  # 3x2 grid for 6 chambers
	chamber_grid.add_theme_constant_override("h_separation", 2)
	chamber_grid.add_theme_constant_override("v_separation", 2)
	
	chamber_container.add_child(chamber_grid)
	
	# Create chamber buttons
	_create_chamber_buttons()

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
	
	# Ensure working loadout has correct size
	var capacity = LoadoutManager.loadout_capacity
	working_loadout.resize(capacity)
	
	# Clear any previous selection
	selected_chamber_index = -1
	
	# Update chamber display
	_update_chamber_display()
	
	# Clear any instruction label
	var instruction_label = chamber_container.get_node_or_null("InstructionLabel") if chamber_container else null
	if instruction_label:
		instruction_label.queue_free()
	
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
	
	# Update chamber display after applying changes
	call_deferred("_update_chamber_display")
	
	close_menu()

func _on_cancel_pressed() -> void:
	# Restore original loadout
	working_loadout = original_loadout.duplicate()
	close_menu()

func _on_bullet_selected(index: int) -> void:
	if not bullet_list or selected_chamber_index == -1:
		return
	
	var bullet_scene = bullet_list.get_item_metadata(index) as PackedScene
	
	# Insert bullet into selected chamber
	if selected_chamber_index < working_loadout.size():
		working_loadout[selected_chamber_index] = bullet_scene
		print("Inserted bullet into chamber ", selected_chamber_index + 1)
		
		# Update display
		_update_chamber_display()
		
		# Clear selection
		selected_chamber_index = -1
	
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



func _update_chamber_display() -> void:
	if chamber_buttons.is_empty():
		return
	
	# Update chamber buttons based on working loadout
	for i in range(chamber_buttons.size()):
		var button = chamber_buttons[i]
		var bullet_scene = working_loadout[i] if i < working_loadout.size() else null
		
		if bullet_scene != null:
			# Get bullet info and display
			var bullet_info = LoadoutManager.get_bullet_info(bullet_scene) if LoadoutManager else null
			var bullet_name = bullet_info.display_name if bullet_info else "Bullet"
			var bullet_color = bullet_info.ui_color if bullet_info else Color.WHITE
			
			# Shorten bullet name if too long
			if bullet_name.length() > 6:
				bullet_name = bullet_name.substr(0, 6)
			
			button.text = str(i + 1) + ":" + bullet_name
			button.modulate = bullet_color
		else:
			button.text = str(i + 1) + ":Empty"
			button.modulate = Color.GRAY
		
		# Highlight selected chamber
		if i == selected_chamber_index:
			button.add_theme_color_override("font_color", Color.YELLOW)
		else:
			button.remove_theme_color_override("font_color")

func _create_chamber_buttons() -> void:
	if not chamber_grid:
		return
	
	# Get capacity from LoadoutManager or default to 6
	var capacity = 6
	if LoadoutManager:
		capacity = LoadoutManager.loadout_capacity
	
	chamber_buttons.clear()
	
	# Create buttons for each chamber
	for i in capacity:
		var button = Button.new()
		button.name = "Chamber" + str(i)
		button.text = str(i + 1) + "\nEmpty"
		button.custom_minimum_size = Vector2(35, 25)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Connect button signals
		button.pressed.connect(_on_chamber_selected.bind(i))
		button.gui_input.connect(_on_chamber_input.bind(i))
		
		chamber_buttons.append(button)
		chamber_grid.add_child(button)
	
	print("LoadoutMenu: Created ", capacity, " chamber buttons")

func _on_chamber_selected(chamber_index: int) -> void:
	selected_chamber_index = chamber_index
	print("LoadoutMenu: Selected chamber ", chamber_index + 1)
	
	# Update visual feedback
	_update_chamber_display()
	
	# Show instruction to user
	if bullet_list:
		var instruction_label = chamber_container.get_node_or_null("InstructionLabel")
		if not instruction_label:
			instruction_label = Label.new()
			instruction_label.name = "InstructionLabel"
			instruction_label.text = "Select a bullet type to insert into chamber " + str(chamber_index + 1) + "\n(Right-click to clear)"
			instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			chamber_container.add_child(instruction_label)
		else:
			instruction_label.text = "Select a bullet type to insert into chamber " + str(chamber_index + 1) + "\n(Right-click to clear)"

func _on_chamber_input(event: InputEvent, chamber_index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to clear chamber
			if chamber_index < working_loadout.size():
				working_loadout[chamber_index] = null
				print("LoadoutMenu: Cleared chamber ", chamber_index + 1)
				_update_chamber_display()
				
				# Clear instruction if this was the selected chamber
				if selected_chamber_index == chamber_index:
					selected_chamber_index = -1
					var instruction_label = chamber_container.get_node_or_null("InstructionLabel")
					if instruction_label:
						instruction_label.queue_free()
