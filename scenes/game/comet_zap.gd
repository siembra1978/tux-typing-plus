extends Node2D

# word stuff
var word_set
var word_set_file_path
var word_set_file
var word_set_content
var word_set_array

# init random
var alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N",
"O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var comets = []
var active

# display
var viewport_size
var scale_factor_x
var scale_factor_y

# difficulty
var difficulty
var max_delay = 2.5 # default
var min_delay = 1 # default
var delay = max_delay
var comet_speed = 250 # default
var next_wave_req = 25

# numbers
var spawn_timer = 0
var max_character_count = 0

# stats
var health = 100
var hit_count = 0.0
var words = []
var hit_index = 0
var completed_words = 0
var miss_count = 0.0
var comets_processed = 0.0
var total_comets = 0.0
var wave = 1

# ui init
#var hp_label
#var acc_label
#var miss_label
#var damage_overlay

@onready var on_top = get_node("OnTop")
@onready var damage_overlay = on_top.get_node("Damage")
@onready var HUD = on_top.get_node("HUD")
@onready var wave_label = HUD.get_node("Wave")
@onready var health_bar = HUD.get_node("HealthBar")

@onready var tux = on_top.get_node("Tux").get_node("TuxSprite")

# objects
var comet_source = preload("res://scenes/objects/game/comet.tscn")
var fade
var pause_menu

var backgrounds = [
	'res://assets/tux4kids/images/backgrounds/0.jpg',
	'res://assets/tux4kids/images/backgrounds/1.jpg',
	'res://assets/tux4kids/images/backgrounds/2.jpg',
	'res://assets/tux4kids/images/backgrounds/3.jpg',
	'res://assets/tux4kids/images/backgrounds/4.jpg'
]
var music = [
	'res://assets/audio/music/game/comet_zap/game.mp3',
	'res://assets/audio/music/game/comet_zap/game2.mp3',
	'res://assets/audio/music/game/comet_zap/game3.mp3'
]

var current_background
var current_music

@onready var options_dim = on_top.get_node("OptionsDim")

# Runs on start
func _ready() -> void:
	if Config.wumba:
		$OnTop/HUD/Wumba.visible = true
		
	print(Config.min_effects)
	print(Config.improve_readability)
	print(Config.dyslexic_mode)
	#Discord RPC
	var platform = OS.get_name()
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.details = "Typing..."
			rpc.large_image = "icon" # Image key from "Art Assets"
			rpc.small_image = 'comet'
			rpc.small_image_text = 'Comet Zap'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
			
			rpc.refresh()
	
	# ready ui
	viewport_size = get_viewport_rect().size

	#hp_label = on_top.get_node("HUD").get_node("Stack").get_node("Health")
	#acc_label = on_top.get_node("HUD").get_node("Stack").get_node("Accuracy")
	#miss_label = on_top.get_node("HUD").get_node("Stack").get_node("MissCount")
	
	active = true
	
	pause_menu = on_top.get_node("Pause")
	fade = on_top.get_node("Fade")
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
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
		
	for word in word_set_array:
		if len(word) > max_character_count:
			#print("new longest word: " + str(word) + " " + str(len(word)))
			max_character_count = len(word)
	
	# Set difficulty properly
	if difficulty == 1:
		health = 250
		max_delay = 5
		min_delay = 2
		delay = max_delay
		comet_speed = 100
	elif difficulty == 2:
		health = 150
		max_delay = 3
		min_delay = 1.5
		delay = max_delay
		comet_speed = 150
	elif difficulty == 3:
		health = 100
		max_delay = 2.5
		min_delay = 1
		delay = max_delay
		comet_speed = 200
	elif difficulty == 4:
		health = 78
		max_delay = 2
		min_delay = .75
		delay = max_delay
		comet_speed = 250
	elif difficulty == 5:
		health = 25
		max_delay = .75
		min_delay = .25
		delay = max_delay
		comet_speed = 400
	
	health_bar.max_value = health
	health_bar.value = health
		
	#Sets random background + music
	current_background = backgrounds.pick_random()
	current_music = music.pick_random()
	$Background/Control/TextureRect.texture = load(current_background)
	$BackgroundMusic.stream = load(current_music)
	$BackgroundMusic.play()
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
	tux.play("intro")
	await get_tree().create_timer(1).timeout
	$Lose.play()
	await tux.animation_finished
	tux.play("left")

# Runs every frame
func _process(delta: float) -> void:
	if active:

		if health <= 0:
			health = 0
			game_over()

		spawn_timer += delta
		
		#hp_label.text = "HP: " + str(health)
		#miss_label.text = "X: " + str(miss_count)
		
		if spawn_timer >= delay:
			spawn_timer = 0
			spawn_word()

'''
func calculate_accuracy():
	var accper = (hit_count)/(comets_processed)*100
	acc_label.text = "ACC: " + str(snapped(accper, .02)) + "%"
'''

func spawn_word():
	var scan_commet = comet_source.instantiate()
	var comet_width = scan_commet.get_node("Sprite").sprite_frames.get_frame_texture("comet",0).get_width()
	var new_word = word_set_array[randi_range(0,len(word_set_array)-1)]
	words.append(new_word)
	#var dist = (viewport_size.x - (2*comet_width))/(max_character_count-1)
	var dist = (viewport_size.x - (2*(viewport_size.x * .125)))/(max_character_count-1)
	#var offset = comet_widthv
	var offset = viewport_size.x * .125
	scan_commet.queue_free()
	
	for chara in new_word:
		if chara != " ":
			var new_commet = comet_source.instantiate()
			total_comets += 1
			new_commet.position = Vector2(offset,-128)
			new_commet.get_node("Sprite").get_node("Label").text = chara
			new_commet.speed = comet_speed
			add_child(new_commet)
			comets.append(new_commet)
		offset += dist
		
	delay = randf_range(min_delay,max_delay)
	
func miss(comet):
	$Miss.play()
	tux.play('miss')
	health -= comet.damage
	health_bar.value = health
	comets_processed += 1
	miss_count += 1.0
	hit_index = 0
	#calculate_accuracy()
	comets.erase(comet)
	comet.queue_free()

	var tween1 := create_tween()
	tween1.parallel().tween_property(damage_overlay, "modulate:a", .5, .125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween1.finished

	var tween2 := create_tween()
	tween2.parallel().tween_property(damage_overlay, "modulate:a", 0, .125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func game_over():
	active = false
	tux.play("lose")
	$BackgroundMusic.stop()
	on_top.get_node("GameOver").visible = true
	$Lose.play()
	await $Lose.finished
	$Sad.play()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.as_text() in alphabet:
			if active:
				if len(comets) > 0:
					var comet = comets[0]
					if event.as_text() == comet.get_node("Sprite").get_node("Label").text:
						comets.erase(comet)
						comets_processed += 1
						hit_count += 1
						hit_index += 1
						
						if ((comet.position.x) < (viewport_size.x/2)):
							tux.play("left")
						else:
							tux.play("right")
						
						if hit_index == len(words[0]):
							print("completed word: " + str(words[0]))
							words.erase(words[0])
							hit_index = 0
							completed_words += 1
						
						if completed_words >= next_wave_req:
							completed_words = 0
							wave += 1
								
							if max_delay > 0:
								print("max delay: " + str(max_delay))
								max_delay *= ((100.0-float(difficulty))/100.0)
								print("max delay: " + str(max_delay))
							
							if min_delay > 0:
								print("min delay: " + str(min_delay))
								min_delay *= ((100.0-float(difficulty))/100.0)
								print("min delay: " + str(min_delay))
								
							#delay = max_delay
							comet_speed += (difficulty) * log(comet_speed)
							wave_label.text = "Wave: " + str(wave)
							
							next_wave_req = randi_range(10,35)
							
							var bg_to_choose = backgrounds.duplicate()
							bg_to_choose.erase(current_background)
							
							var music_to_choose = music.duplicate()
							music_to_choose.erase(current_music)
							
							current_background = bg_to_choose.pick_random()
							current_music = music_to_choose.pick_random()
							$Background/Control/TextureRect.texture = load(current_background)
							$BackgroundMusic.stream = load(current_music)
							$BackgroundMusic.play()
						
						comet.self_active = false
						var laser = Line2D.new()
						laser.default_color = Color.RED
						laser.points = PackedVector2Array([Vector2(viewport_size.x / 2, viewport_size.y-100),comet.position])
						add_child(laser)
						comet.get_node("Sprite").play("cometbreak")
						$CometBreakSound.play()
						await comet.get_node("Sprite").animation_finished
						laser.queue_free()
						comet.queue_free()
		elif event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.resume()
				$BackgroundMusic.volume_db = 0
			elif $OnTop/GameOver.visible:
					pass
			else:
				$Back.play()
				active = false
				pause_menu.visible = true
				pause_menu.position = Vector2(0, get_viewport_rect().size.y)
				var tween = create_tween().set_parallel(true)
				tween.tween_property(options_dim, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(pause_menu, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				$BackgroundMusic.volume_db = -15
				
func _on_viewport_size_changed():
	viewport_size = get_viewport_rect().size
