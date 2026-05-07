extends Node2D

# word stuff
var word_set
var word_set_file_path
var word_set_file
var word_set_content
var word_set_array
var active_words = []
var current_index = 0
var word_loc = []

# init random
var alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N",
"O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var fishs = [] 
var letter_bank = []
var fish_speed = 75
var active
var streak = 0
var fish_count = 0

# display
var viewport_size
var scale_factor_x
var scale_factor_y
	
#Sets random background + music
var backgrounds = [
		'res://assets/tux4kids/images/kcas0.jpg',
		'res://assets/tux4kids/images/kcas1.jpg',
		'res://assets/tux4kids/images/kcas2.jpg',
		'res://assets/tux4kids/images/kcas3.jpg',
		'res://assets/tux4kids/images/kcas4.jpg',
		'res://assets/tux4kids/images/kcas5.jpg',
		'res://assets/tux4kids/images/kcas6.jpg',
		'res://assets/tux4kids/images/kcas7.jpg',
		'res://assets/tux4kids/images/kcas8.jpg',
		'res://assets/tux4kids/images/kcas9.jpg',
		'res://assets/tux4kids/images/kcas10.jpg',
		'res://assets/tux4kids/images/kcas11.jpg'
	]
var music = [
		'res://assets/tux4kids/sounds/amidst_the_raindrops.ogg',
		'res://assets/tux4kids/sounds/chiptune2.ogg'
	]

# ui init
#var on_top
var level_label
var fish_label
var health_label
var pointer


# numbers
var max_delay = 2.5 # default
var min_delay = 1 # default
var delay = max_delay
var spawn_timer = 0
var max_character_count = 0

# difficulty
var difficulty
var health = 10
var level: int


# objects
var fish_source = preload("res://scenes/objects/game/fish.tscn")
var fade
var pause_menu
@onready var tux = $Tux

@onready var on_top = get_node("OnTop")
@onready var options_dim = on_top.get_node("OptionsDim")


# Runs on start
func _ready() -> void:
	if Config.wumba:
		$OnTop/HUD/Wumba.visible = true

	var platform = OS.get_name()
	if platform != "Web" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		rpc.details = "Typing..."
		rpc.large_image = "icon" # Image key from "Art Assets"
		rpc.small_image = 'fish'
		rpc.small_image_text = 'Fish Cascade'

		rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
		# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		
		rpc.refresh()

	on_top = self.get_node("OnTop")
	level_label = on_top.get_node("HUD").get_node("Level")
	fish_label = on_top.get_node("HUD").get_node("VBoxContainer").get_node("Fish")
	health_label = on_top.get_node("HUD").get_node("VBoxContainer").get_node("Health")
	pointer = on_top.get_node("HUD").get_node("Pointer")
	active = true
	letter_bank.clear()
	
	pause_menu = self.get_node("OnTop").get_node("Pause")
	fade = self.get_node("OnTop").get_node("Fade")
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tux.position.x = get_viewport_rect().size.x / 2
	tux.position.y = get_viewport_rect().size.y - 60
	
	
	# Load Corresponding Text File
	if Config.wumba:
		word_set_file_path = "res://gameplay/wumba/" + word_set + ".txt"
	else:
		word_set_file_path = "res://gameplay/word_sets/" + word_set + ".txt"
	word_set_file = FileAccess.open(word_set_file_path, FileAccess.READ)
	
	# Gets file contents as text
	word_set_content = word_set_file.get_as_text()
	
	# Splits text file contents by line and removes the first entry (its just the name)
	word_set_array = word_set_content.split("\n", true)
	word_set_array.remove_at(0)
	
	if word_set_array[len(word_set_array)-1] == "":
		word_set_array.remove_at(len(word_set_array)-1)
	
	#print(word_set_array)
	
	
	# Set difficulty properly
	if level < 1:
		level = 1
		fish_count = difficulty * level
		if difficulty == 1:
			fish_speed = 50
			health = 20
			max_delay = 5
			min_delay = 2
			delay = max_delay
		elif difficulty == 2:
			fish_speed = 75
			health = 15
			max_delay = 3
			min_delay = 1.5
			delay = max_delay
		elif difficulty == 3:
			fish_speed = 100
			health = 10
			max_delay = 2.5
			min_delay = 2
			delay = max_delay
		elif difficulty == 4:
			fish_speed = 150
			health = 10
			max_delay = 2
			min_delay = 1.5
			delay = max_delay
		elif difficulty == 5:
			fish_speed = 200
			health = 5
			max_delay = 1.5
			min_delay = 1
			delay = max_delay
	
		
		
	$CanvasLayer/Control/TextureRect.texture = load(backgrounds.pick_random())
	$BackgroundMusic.stream = load(music.pick_random())
	$BackgroundMusic.play()
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
# Runs every frame
func _process(delta: float) -> void:
	#print('current index = ' + str(current_index))
	#print('active words = ' + str(active_words))
	#if len(fishs) > 0:
		#print('fish 0' + str(fishs[0]))
	if active:
		spawn_timer += delta
		if health <= 0:
			health = 0
			game_over()
		
		if spawn_timer >= delay:
			spawn_timer = 0
			spawn_word()
			
		level_label.text = "Level: " + str(level)
		fish_label.text = "Fish: " + str(fish_count)
		health_label.text = "Health: " + str(health)
		
		'''
		if word_loc.size() > 0:
			tux.move_to(word_loc[0], 300)
		'''
		
		#Detects when last letter of word entered | Tux... activate! GRaHHHH
		if len(fishs)>0:
			if len(active_words) > 0:
				if current_index == len(active_words[0]):
					#print('heck yeah')
					#tux.moving = true
					current_index = 0
					if word_loc.size() > 0:
						tux.move_to(word_loc[0], 300)
						word_loc.remove_at(0)
					active_words.remove_at(0)
					
					for char in letter_bank:
						#print(char.get_node("Sprite").get_node("Label").text)
						if char != letter_bank[letter_bank.size() / 2]:
							char.queue_free()
						char.readbox.visible = false
						char.get_node("Sprite").get_node("Label").text = ''
					letter_bank.clear()
					
		if fish_count == 0:
			active = false
			$BackgroundMusic.stop()
			$Win.play()
			tux.get_node('FishTux').play('cheer')
				
			var next_scene = load("res://scenes/game/fish_cascade.tscn").instantiate()
				
			await $Win.finished
			$CanvasLayer/Control/TextureRect.texture = load(backgrounds.pick_random())
			$BackgroundMusic.stream = load(music.pick_random())
			$BackgroundMusic.play()
			level += 1
			health += 1
			fish_count = difficulty * level
			
			
			if max_delay > 0:
				print("max delay: " + str(max_delay))
				max_delay *= ((100.0-float(difficulty))/100.0)
				print("max delay: " + str(max_delay))

			if min_delay > 0:
				print("min delay: " + str(min_delay))
				min_delay *= ((100.0-float(difficulty))/100.0)
				print("min delay: " + str(min_delay))
				
			fish_speed += (difficulty) * log(fish_speed)
			
			next_scene.word_set = get_tree().current_scene.word_set
			next_scene.difficulty = get_tree().current_scene.difficulty
			next_scene.level = get_tree().current_scene.level
			next_scene.health = get_tree().current_scene.health
			next_scene.fish_count = get_tree().current_scene.fish_count
			next_scene.fish_speed = get_tree().current_scene.fish_speed
			next_scene.max_delay = get_tree().current_scene.max_delay
			next_scene.min_delay = get_tree().current_scene.min_delay
			get_tree().change_scene_to_node(next_scene)
			
			active = true


func spawn_word():
	var new_word = word_set_array[randi_range(0,len(word_set_array)-1)]
	var viewport_size = get_viewport_rect().size
	var offset = randf_range(0,viewport_size.x-500)
	var char_index = 0
	var middle_index = floor((len(new_word) / 2))
	active_words.append(new_word)
	
	for char in new_word:
		if char != " ":
			var new_fish = fish_source.instantiate()
			new_fish.position = Vector2(128+offset,-128)
			new_fish.get_node("Sprite").get_node("Label").text = char
			new_fish.speed = fish_speed
			new_fish.my_index = char_index
			add_child(new_fish)
			fishs.append(new_fish)
			
			if char_index == middle_index:
				word_loc.append(new_fish.position)
			char_index += 1
		else:
			var new_fish = fish_source.instantiate()
			new_fish.position = Vector2(128+offset,-128)
			new_fish.get_node("Sprite").get_node("Label").text = '_'
			new_fish.speed = fish_speed
			add_child(new_fish)
			fishs.append(new_fish)
			
			if char_index == middle_index:
				word_loc.append(new_fish.position)
			char_index += 1
		offset += 30
	
	delay = randf_range(min_delay,max_delay)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.as_text() in alphabet:
			if active:
				#print(event.as_text())
				if len(fishs) > 0:
					var fish = fishs[0]
					if event.as_text() == fish.get_node("Sprite").get_node("Label").text:
						$Pop.play()
						streak += 1
						current_index += 1
						#print('streak: ' + str(streak))
						letter_bank.append(fish)
						fishs.erase(fish)
						fish.get_node("Sprite").get_node("Label").add_theme_color_override("font_color", Color.RED)
					else:
						streak = 0
		#temp
		elif event.keycode == KEY_SPACE:
			if active:
				print(event.as_text())
				if len(fishs) > 0:
					var fish = fishs[0]
					if '_' == fish.get_node("Sprite").get_node("Label").text:
						$Pop.play()
						streak += 1
						current_index += 1
						#print('streak: ' + str(streak))
						letter_bank.append(fish)
						fishs.erase(fish)
						fish.get_node("Sprite").get_node("Label").add_theme_color_override("font_color", Color.RED)
					else:
						streak = 0
			else:
				streak = 0
		elif event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.resume()
				$BackgroundMusic.volume_db = -15
			elif $OnTop/GameOver.visible or $Win.is_playing():
					pass
			else:
				$Back.play()
				active = false
				pause_menu.visible = true
				pause_menu.position = Vector2(0, get_viewport_rect().size.y)
				var tween = create_tween().set_parallel(true)
				tween.tween_property(options_dim, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(pause_menu, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				$BackgroundMusic.volume_db = -30

func game_over():
	active = false
	tux.get_node('FishTux').play('die')
	$BackgroundMusic.stop()
	on_top.get_node("GameOver").visible = true
	$Lose.play()
	await $Lose.finished
	$Sad.play()
	
func _on_viewport_size_changed():
	viewport_size = get_viewport_rect().size
	tux.position.y = get_viewport_rect().size.y - 60
