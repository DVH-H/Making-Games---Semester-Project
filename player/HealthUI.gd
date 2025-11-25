# HealthUI.gd
# Displays player health as hearts in the top-left corner of the screen
extends HBoxContainer

@export var heart_full_texture: Texture2D
@export var heart_half_texture: Texture2D
@export var heart_empty_texture: Texture2D

var max_health: int = 0
var current_health: int = 0
var hearts_per_health: int = 20  # Each heart represents 20 health (5 hearts for 100 health)
var heart_sprites: Array[TextureRect] = []

func _ready() -> void:
	print("HealthUI: _ready called")
	# Don't create hearts yet - wait for set_max_health to be called

func _create_hearts() -> void:
	# Clear existing hearts
	for child in get_children():
		child.queue_free()
	heart_sprites.clear()
	
	# Calculate number of hearts needed
	var num_hearts = ceili(float(max_health) / float(hearts_per_health))
	print("HealthUI: Creating ", num_hearts, " hearts for max_health=", max_health)
	
	# Create heart sprites
	for i in range(num_hearts):
		var heart = TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.texture = heart_full_texture if heart_full_texture else null
		add_child(heart)
		heart_sprites.append(heart)
		print("HealthUI: Created heart ", i, " with texture: ", heart.texture != null)
	
	# Update to show current health
	update_hearts()

func set_max_health(new_max_health: int) -> void:
	print("HealthUI: set_max_health called with: ", new_max_health)
	max_health = new_max_health
	_create_hearts()

func set_health(new_health: int) -> void:
	print("HealthUI: set_health called with: ", new_health, " (max: ", max_health, ")")
	current_health = clampi(new_health, 0, max_health)
	update_hearts()

func update_hearts() -> void:
	if heart_sprites.is_empty():
		return
	
	# Calculate how many full, half, and empty hearts we need
	var health_per_heart = float(hearts_per_health)
	
	for i in range(heart_sprites.size()):
		var heart_min_health = i * hearts_per_health
		var heart_max_health = (i + 1) * hearts_per_health
		
		if current_health >= heart_max_health:
			# Full heart
			heart_sprites[i].texture = heart_full_texture if heart_full_texture else null
			heart_sprites[i].modulate = Color.WHITE
		elif current_health > heart_min_health:
			# Partial heart - calculate how full it is
			var health_in_heart = current_health - heart_min_health
			var fill_percentage = float(health_in_heart) / float(hearts_per_health)
			
			if fill_percentage > 0.5:
				# More than half - show full heart with transparency
				heart_sprites[i].texture = heart_full_texture if heart_full_texture else null
				heart_sprites[i].modulate = Color(1, 1, 1, 0.5 + fill_percentage * 0.5)
			else:
				# Half or less - show half heart
				if heart_half_texture:
					heart_sprites[i].texture = heart_half_texture
					heart_sprites[i].modulate = Color.WHITE
				else:
					# No half texture, use full with low opacity
					heart_sprites[i].texture = heart_full_texture if heart_full_texture else null
					heart_sprites[i].modulate = Color(1, 1, 1, fill_percentage)
		else:
			# Empty heart
			if heart_empty_texture:
				heart_sprites[i].texture = heart_empty_texture
				heart_sprites[i].modulate = Color.WHITE
			else:
				# No empty texture, just hide it or make it very transparent
				heart_sprites[i].texture = heart_full_texture if heart_full_texture else null
				heart_sprites[i].modulate = Color(1, 1, 1, 0.2)
