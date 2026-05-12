extends Node2D

# word stuff
var word_set
var word_set_file_path
var word_set_file
var word_set_content
var word_set_array
var custom = false

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
var max_delay = 10
var min_delay = 10
var delay = max_delay
var base_speed = 750
var comet_speed = base_speed
var difficulty = 0

# numbers
var spawn_timer = 0
var max_character_count = 0

# stats
var health = 100
var hit_count = 0.0
var miss_count = 0.0
var comets_processed = 0.0
var total_comets = 0.0

# ui init
#var acc_label
#var score_label
#var max_combo_label

@onready var background_ui = get_node("Background")
@onready var background_control = background_ui.get_node("Control")
@onready var pink_bar = background_control.get_node("Bar")


# objects
var note_source = preload("res://scenes/objects/game/note.tscn")
var metro_bar = preload("res://scenes/objects/game/metrobar.tscn")
var score_screen = preload("res://scenes/beat/score_screen.tscn")
#var acc_plate = preload("res://scenes/objects/ui/accplate.tscn")

var fade
var pause_menu

# starting ui organization for realsies
@onready var on_top = get_node("OnTop")

@onready var HUD = on_top.get_node("HUD")
@onready var score_stack = HUD.get_node("ScoreStack")
@onready var combo_stack = HUD.get_node("ComboStack")
@onready var mod_stack = HUD.get_node("Mods")
@onready var CountdownLabel = HUD.get_node("CountdownLabel")

@onready var acc_label = score_stack.get_node("Accuracy")
@onready var score_label = score_stack.get_node("Score")
@onready var max_combo_label = combo_stack.get_node("MaxCombo")

@onready var health_bar = HUD.get_node("HealthBar")
@onready var progress_circle = HUD.get_node("ProgressCircle")

@onready var bg = get_node("ActiveBackground")

@onready var kiai_sound = get_node("Kiai")
@onready var countdown_sound = get_node("Countdown")
@onready var acc_plate = HUD.get_node("AccuracyPlate")

@onready var options_dim = on_top.get_node("OptionsDim")

# rhythm stuff
var offset
var bpm_timestamps = []
var bpm
var divider = 4
var duration = 0
var total_beats = 0
var mappings = []
var music
var video
var playback_position = 0.0
var next_beat = 0
var leniency = float(150)/float(1000)
var judgments = {"perfect": 0, "good": 0, "meh": 0, "miss": 0}
var judgment_scores = {"perfect": 300, "good": 100, "meh": 50, "miss": 0}
var beatmap_filename
var combo = 0
var max_combo = 0
var acc_score
var acc_total
var total_score = 0
var accuracy
var mods
var hit_point

var song_title
var artist
var diff_name
var background
var legacy
var official
var dur_in_pos

# difficulty
var HP = 5
var OD = 5
var AR = 5

# timing windows
var perfect_window = 80 - (6 * OD)
var good_window = 140 - (8 * OD)
var meh_window = 200 - (10 * OD)

var playing_index = 0
var look_ahead_index = 0
var note_dict = {}
var metro_dict = {}

var original_height = 1080.0

var started = false

var metronome_active = false
var metro_count = 4
var kiai_indices = []

@onready var active_bg = get_node("ActiveBackground")
@onready var tux = active_bg.get_node("Tux")
@onready var cheerleft = active_bg.get_node("KiaiCheerLeft")
@onready var cheerright = active_bg.get_node("KiaiCheerRight")
@onready var particlesleft = cheerleft.get_node("KiaiParticles")
@onready var particlesright = cheerright.get_node("KiaiParticles")
var init_cl_pos
var init_cr_pos

# Runs on start
func _ready() -> void:
	if Config.wumba:
		$ActiveBackground/Wumba.visible = true
	if Config.min_effects:
		$Background/Control/TextureRect.visible = false
		active_bg.visible = false

	var platform = OS.get_name()
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.large_image = "icon"
			rpc.small_image = 'music'
			rpc.small_image_text = 'Proper Rhythm'
			
			rpc.refresh()
	
	# ready ui
	viewport_size = get_viewport_rect().size
	
	music = $BackgroundMusic
	video = $Background/Control/VideoStreamPlayer
	playback_position = 0.0
	init_cl_pos = cheerleft.position
	init_cr_pos = cheerright.position
	
	active = true
	
	pause_menu = self.get_node("OnTop").get_node("Pause")
	fade = self.get_node("OnTop").get_node("Fade")
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	pink_bar.position.x = .25*viewport_size.x
	pink_bar.size.x = .75*viewport_size.x
	hit_point = pink_bar.position.y

	# Load Corresponding Text File
	if Config.wumba:
		word_set_file_path = "res://gameplay/wumba/" + word_set + ".txt"
	else:
		if custom:
			word_set_file_path = "user://word_sets/" + word_set + ".txt"
			print(word_set_file_path)
		else:
			word_set_file_path = "res://gameplay/word_sets/" + word_set + ".txt"
	#word_set_file_path = "res://gameplay/word_sets/" + "shapes" + ".txt"
	word_set_file = FileAccess.open(word_set_file_path, FileAccess.READ)
	
	# Gets file contents as text
	word_set_content = word_set_file.get_as_text()
	
	# Splits text file contents by line and removes the first entry (its just the name)
	word_set_array = word_set_content.split("\n", true)
	word_set_array.remove_at(0)
	
	if word_set_array[len(word_set_array)-1] == "":
		print("L")
		word_set_array.remove_at(len(word_set_array)-1)
	
	if official:
		load_official_beatmap(beatmap_filename)
	else:
		load_beatmap(beatmap_filename)

	duration = music.stream.get_length()

	if mods["HT"]:
		music.pitch_scale = .75
		video.speed_scale = .75
		#recreate_bpm_timestamps()
	if mods["DT"]:
		music.pitch_scale = 1.5
		video.speed_scale = 1.5
		#recreate_bpm_timestamps()
	if mods["HR"]:
		AR *= 1.25
		OD *= 1.25
		HP *= 1.25
	if mods["EZ"]:
		AR *= .5
		OD *= .5
		HP *= .5
	
	for mod in mods.keys():
		#print(mod + " " + str(mods[mod]))
		mod_stack.get_node(mod).visible = mods[mod]
	
	# determines approach rates
	dur_in_pos = (1500*(float(AR)/10))*duration
	
	perfect_window = 80 - (6 * OD)
	good_window = 140 - (8 * OD)
	meh_window = 200 - (10 * OD)
	
	# timing windows
	
	for word in word_set_array:
		if len(word.remove_char(32)) > max_character_count:
			#print("new longest word: " + str(word) + " " + str(len(word)))
			max_character_count = len(word)
	
	#offset = 0.133
	#create_bpm_timestamps()
	
	var letter_count = 0
	var selected_word_array = []
	
	while letter_count < mappings.size():
		var new_word = word_set_array[randi_range(0,len(word_set_array)-1)]
		
		if mods["CS"]:
			new_word = new_word.to_lower()
			new_word[0] = new_word[0].to_upper()
			
		letter_count += len(new_word.remove_char(32))
		selected_word_array.append(new_word.remove_char(32))
	
	var play_area = viewport_size.x * .75
	var scan_commet = note_source.instantiate()
	var comet_width = scan_commet.get_node("Sprite").texture.get_width()
	var new_word = word_set_array[randi_range(0,len(word_set_array)-1)]
	var dist = (play_area-(2*comet_width))/(max_character_count-1)
	var offset = ((viewport_size.x - play_area)/2) + comet_width
	scan_commet.queue_free()
	
	if mods["HR"]:
		offset = viewport_size.x - (((viewport_size.x - play_area)/2) + comet_width)
		dist = -(play_area-(2*comet_width))/(max_character_count-1)
	
	var word_index = 0
	var current_word = selected_word_array[word_index]
	var current_word_length = len(current_word)
	var current_char_index = 0
	
	for i in mappings.size():
		var note_timestamp = bpm_timestamps[i]

		#var spawn_pos = hit_point - (comet_speed*((note_timestamp/1000) + 3))
		var spawn_pos = 0

		if (i % int(divider)) == 0:
			var new_bar = metro_bar.instantiate()
			#new_bar.position = Vector2(((viewport_size.x - play_area)/2),spawn_pos)
			new_bar.position = Vector2(((viewport_size.x - play_area)/2),-100)
			new_bar.get_node("ColorRect").color = Color(0.49, 0.49, 0.49, 1.0)
			new_bar.timestamp = note_timestamp
			metro_dict[i] = new_bar
			#bg.add_child(new_bar)
		else:
			var new_bar = metro_bar.instantiate()
			#new_bar.position = Vector2(((viewport_size.x - play_area)/2),spawn_pos)
			new_bar.position = Vector2(((viewport_size.x - play_area)/2),-100)
			new_bar.timestamp = note_timestamp
			metro_dict[i] = new_bar
			#bg.add_child(new_bar)

		if mappings[i] == 1:
			var new_note = note_source.instantiate()
			total_comets += 1
			#new_note.position = Vector2(offset,spawn_pos)
			new_note.position = Vector2(offset,-100)
			new_note.get_node("Sprite").get_node("Label").text = current_word[current_char_index]
			new_note.timestamp = note_timestamp
			#add_child(new_note)
			note_dict[i] = new_note
			comets.append(new_note)
			
			if current_char_index < current_word_length-1:
				current_char_index += 1
				offset += dist
			else:
				current_char_index = 0
				word_index += 1
				current_word = selected_word_array[word_index]
				current_word_length = len(current_word)
				offset = ((viewport_size.x - play_area)/2) + comet_width
				if mods["HR"]:
					offset = viewport_size.x - (((viewport_size.x - play_area)/2) + comet_width)
	
	total_beats = len(bpm_timestamps)
	
	spawn_ahead()
	
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.details = str(song_title) + " - " + str(artist)
			rpc.refresh()
	
	var wait_time = 60/bpm
	
	CountdownLabel.visible = true
	await get_tree().create_timer(2).timeout
	CountdownLabel.text = "4"
	countdown_sound.play()
	var ctween := create_tween()
	ctween.tween_property(CountdownLabel, "scale", Vector2(1.05,1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ctween.tween_property(CountdownLabel, "scale", Vector2(1,1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(wait_time).timeout
	CountdownLabel.text = "3"
	countdown_sound.play()
	var ctween2 := create_tween()
	ctween2.tween_property(CountdownLabel, "scale", Vector2(1.05,1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ctween2.tween_property(CountdownLabel, "scale", Vector2(1,1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(wait_time).timeout
	CountdownLabel.text = "2"
	countdown_sound.play()
	var ctween3 := create_tween()
	ctween3.tween_property(CountdownLabel, "scale", Vector2(1.05,1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ctween3.tween_property(CountdownLabel, "scale", Vector2(1,1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(wait_time).timeout
	CountdownLabel.text = "1"
	countdown_sound.play()
	var ctween4 := create_tween()
	ctween4.tween_property(CountdownLabel, "scale", Vector2(1.05,1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ctween4.tween_property(CountdownLabel, "scale", Vector2(1,1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(wait_time).timeout
	CountdownLabel.text = ""
	CountdownLabel.visible = false
	
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			rpc.refresh()

	if Config.min_effects:
		$Background/Control/TextureRect.visible = false
		active_bg.visible = false

	music.play()
	if not Config.min_effects:
		if video.stream:
			video.play()
	started = true

func recreate_bpm_timestamps():
	if offset:
		#print(bpm_timestamps)
		var modfactor = 1

		if mods["DT"]:
			modfactor = 1.5
			offset *= .75
		if mods["HT"]:
			modfactor = .75
			offset *= 1.33

		#print(offset)
		bpm_timestamps.clear()
		var a = offset*1000
		#print(bpm)
		var change_by = ((60/(bpm*modfactor))*1000)/divider
		#print(change_by)
		
		for mapping in mappings:
			bpm_timestamps.append(a)
			a += change_by
		
		#print(bpm_timestamps)

func spawn_ahead():
	for i in range(playing_index, playing_index+100):
		var note = note_dict.get(i)
		var bar = metro_dict.get(i)
		if bar:
			bg.add_child(bar)
			metro_dict.erase(i)
		if note:
			add_child(note)
			note_dict.erase(i)

# Runs every frame
func _process(delta: float) -> void:
	var viewport_sizen = get_viewport_rect().size

	pink_bar.position.x = .125*viewport_sizen.x
	pink_bar.size.x = .75*viewport_sizen.x
	hit_point = pink_bar.position.y

	#var sf = viewport_sizen.y / original_height
	#comet_speed = base_speed * sf


	if active:
		playback_position = music.get_playback_position() + AudioServer.get_time_since_last_mix()

		progress_circle.value = (playback_position/duration)*100
		health_bar.value = health

		var position_ms = playback_position*1000
		
		if started:
			health -= HP*delta
		
		if health <= 0:
			if not mods["NF"]:
				game_over()
			
		if health > 100:
			health = 100
		
		if health < 0:
			health = 0

		spawn_timer += delta
		
		if bpm_timestamps:
			if next_beat < total_beats-1:
				if position_ms > bpm_timestamps[next_beat]:
					#$Metronome.play()
					if metronome_active:
						print("metro!")
						if (next_beat % (4*metro_count)) == 0:
							$Metronome.play()
						elif (next_beat % (metro_count)) == 0:
							$Metronome2.play()

					if (next_beat % (int(divider))) == 0:
						tux_react()
						#tux.flip_h = not tux.flip_h
						
					if next_beat in kiai_indices:
						if not Config.min_effects:
							kiai_sound.play()
							cheer()

					next_beat += 1
			if mappings:
				if position_ms > bpm_timestamps[playing_index]:
					if playing_index < total_beats-1:
						spawn_ahead()
						playing_index += 1
						
		if spawn_timer >= delay:
			spawn_timer = 0
			#spawn_word()

func calculate_accuracy():
	acc_score = (judgments["perfect"]*judgment_scores["perfect"])+(judgments["good"]*judgment_scores["good"])+(judgments["meh"]*judgment_scores["meh"])+(judgments["miss"]*judgment_scores["miss"])
	acc_total = comets_processed*judgment_scores["perfect"]
	#print(judgments)
	accuracy = snapped((acc_score/acc_total)*100, .02)
	acc_label.text = str(accuracy) + "%"
	
func miss(comet):
	comet.active = false

	#if mods["NF"] == false:
	health -= comet.damage
		
	display_acc_plate("Miss", comet.position.x)

	if combo >= 15:
		$Miss.play()
	combo = 0
	comets_processed += 1
	miss_count += 1.0
	judgments["miss"] += 1
	calculate_accuracy()
	comets.erase(comet)
	comet.queue_free()
	
func game_over():
	active = false
	$BackgroundMusic.stop()
	video.paused = true
	self.get_node("OnTop").get_node("GameOver").visible = true
	$Lose.play()
	await $Lose.finished
	$Sad.play()

# res://gameplay/beatmaps/

func load_official_beatmap(file_name: String):
	#print("res://gameplay/beatmaps/" + file_name)
	if not DirAccess.dir_exists_absolute("res://gameplay/beatmaps/" + file_name):
		#print("No beatmap folder found")
		return

	var file = FileAccess.open("res://gameplay/beatmaps/" + file_name + "/" + file_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data

		song_title = data["name"]
		artist = data["artist"]
		diff_name = data["difficulty"]
		bpm = data["bpm"]
		offset = data["offset"]
		divider = data["divider"]
		mappings = data["mappings"]
		bpm_timestamps = data["bpm_timestamps"]
		
		# difficulty
		HP = data["HP"]
		AR = data["AR"]
		OD = data["OD"]
		
		#print("user://beatmaps/" + file_name + "/" + str(data["song_name"]))
		var music_path = "res://gameplay/beatmaps/" + file_name + "/" + str(data["song_name"])

		var stream = load(music_path)

		if stream:
			music.stream = stream
		else:
			push_error("Failed to load music at: " + music_path)

		duration = music.stream.get_length()

		if data["background"]:
			if not Config.min_effects:
				$Background/Control/TextureRect.visible = true
				$Background/Control/BGDim.visible = true
				#print("res://gameplay/beatmaps/" + file_name + "/background.jpg")
				$Background/Control/TextureRect.texture = load("res://gameplay/beatmaps/" + file_name + "/" + data["background"])
				background = load("res://gameplay/beatmaps/" + file_name + "/" + data["background"])

		if data["tux_skin"]:
			$ActiveBackground/Tux.texture = load("res://gameplay/beatmaps/" + file_name + "/" + data["tux_skin"])
		
		if "kiai_indices" in data:
			if data["kiai_indices"]:
				kiai_indices.clear()
				var temp_indices = data["kiai_indices"]
				for index in temp_indices:
					kiai_indices.append(int(index))

		if "video" in data:
			if data["video"]:
				$Background/Control/BGDim.visible = true
				$Background/Control/TextureRect.visible = false
				$Background/Control/VideoStreamPlayer.visible = true
				#print("res://gameplay/beatmaps/" + file_name + "/video.ogv")
				video.stream = load("res://gameplay/beatmaps/" + file_name + "/video.ogv")
				#await get_tree().create_timer(3.0).timeout
				#video.play()

		#print("Loaded beatmap successfully!")
	else:
		pass
		#print("JSON Parse Error: ", json.get_error_message())

func load_beatmap(file_name: String):
	#print("user://beatmaps/" + file_name)
	if not DirAccess.dir_exists_absolute("user://beatmaps/" + file_name):
		#print("No beatmap folder found")
		return

	var file = FileAccess.open("user://beatmaps/" + file_name + "/" + file_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data

		song_title = data["name"]
		artist = data["artist"]
		diff_name = data["difficulty"]
		bpm = data["bpm"]
		offset = data["offset"]
		divider = data["divider"]
		mappings = data["mappings"]
		bpm_timestamps = data["bpm_timestamps"]
		
		# difficulty
		HP = data["HP"]
		AR = data["AR"]
		OD = data["OD"]
		
		#print("user://beatmaps/" + file_name + "/" + str(data["song_name"]))
		var music_path = "user://beatmaps/" + file_name + "/" + str(data["song_name"])

		if data["song_name"].ends_with(".mp3"):
			if FileAccess.file_exists(music_path):
				#print("Loading MP3")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamMP3.new()
				stream.data = buffer
				music.stream = stream
				#music.play()
		elif data["song_name"].ends_with(".ogg"):
			if FileAccess.file_exists(music_path):
				#print("Loading OGG")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
				music.stream = stream
				#music.play()

		duration = music.stream.get_length()

		if data["background"]:
			if not Config.min_effects:
				$Background/Control/TextureRect.visible = true
				$Background/Control/BGDim.visible = true
				#print("user://beatmaps/" + file_name + "/background.jpg")
				$Background/Control/TextureRect.texture = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["background"]))
				background = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["background"]))

		if data["tux_skin"]:
			$ActiveBackground/Tux.texture = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["tux_skin"]))
		
		if "kiai_indices" in data:
			if data["kiai_indices"]:
				kiai_indices.clear()
				var temp_indices = data["kiai_indices"]
				for index in temp_indices:
					kiai_indices.append(int(index))

		if "video" in data:
			if data["video"]:
				$Background/Control/BGDim.visible = true
				$Background/Control/TextureRect.visible = false
				$Background/Control/VideoStreamPlayer.visible = true
				#print("user://beatmaps/" + file_name + "/video.ogv")
				video.stream = load("user://beatmaps/" + file_name + "/video.ogv")

		#print("Loaded beatmap successfully!")
	else:
		pass
		#print("JSON Parse Error: ", json.get_error_message())

var acc_tween1: Tween
var acc_ctween: Tween
var acc_tween2: Tween

func display_acc_plate(hit_type, comet_position=0):
	if acc_tween1: acc_tween1.kill()
	if acc_ctween: acc_ctween.kill()
	if acc_tween2: acc_tween2.kill()
	
	var color = Color(1,1,1,1)
	
	match hit_type:
		"Perfect!":
			color = Color(0.0, 0.799, 0.801, 1.0)
		"Good!":
			color = Color(0.0, 0.711, 0.0, 1.0)
		"Meh...":
			color = Color(0.774, 0.774, 0.0, 1.0)
		"Miss":
			color = Color(1.0, 0.0, 0.0, 1.0)
			
	var plate_label = acc_plate.get_node("Label")
	
	plate_label.text = hit_type
	plate_label.modulate = color
	#plate_label.position.x = comet_position - 1000
	#plate_label.position.y += 300
	
	#on_top.add_child(new_plate)
	
	#var pivot_offset = new_plate.size / 2
	#new_plate.resized.connect(func(): pivot_offset = new_plate / 2)
	
	acc_tween1 = create_tween()
	acc_tween1.tween_property(acc_plate, "modulate:a", 1, .125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	acc_ctween = create_tween()
	acc_ctween.tween_property(acc_plate, "scale", Vector2(1.05, 1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	acc_ctween.tween_property(acc_plate, "scale", Vector2(1, 1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await acc_ctween.finished
	
	acc_tween2 = create_tween()
	acc_tween2.tween_property(acc_plate, "modulate:a", 0, .25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
	#new_plate.queue_free()

func hit(comet, note_latency):
	if len(comets) > 0:
		comet.in_play = false
		#var comet = comets[0]
		#var note_latency = 887 - comet.position.y

		var base_points = 0
		
		#note_latency *= 1000
		
		#print(str(note_latency) + " : " + str(perfect_window) + " : " + str(good_window) + " : " + str(meh_window))
		
	
		if mods["AP"]:
			judgments["perfect"] += 1
			base_points = judgment_scores["perfect"]
			
			health += 7.5
			
			display_acc_plate("Perfect!", comet.position.x)
		else:
			if (abs(note_latency) < perfect_window):
				judgments["perfect"] += 1
				base_points = judgment_scores["perfect"]
				
				health += 7.5
				
				display_acc_plate("Perfect!", comet.position.x)
			elif (abs(note_latency) < good_window):
				judgments["good"] += 1
				
				health += 5
				
				base_points = judgment_scores["good"]
				display_acc_plate("Good!", comet.position.x)
			elif (abs(note_latency) < meh_window):
				judgments["meh"] += 1
				
				health += 1
				
				base_points = judgment_scores["meh"]
				display_acc_plate("Meh...", comet.position.x)


		var pre_points = base_points + (base_points * combo * .1)

		if mods["DT"]:
			pre_points *= 1.25
		if mods["HT"]:
			pre_points *= .5
		if mods["EZ"]:
			pre_points *=.75
		if mods["HR"]:
			pre_points *= 1.15
		if mods["HD"]:
			pre_points *= 1.05
		if mods["CS"]:
			pre_points *= 1.20

		total_score += int(pre_points)
		
		score_label.text = str(total_score).pad_zeros(8)
		comets_processed += 1
		hit_count += 1
		combo += 1
		if combo > max_combo:
			max_combo = combo
			max_combo_label.text = str(max_combo) + "x"
			var tween := create_tween()
			tween.tween_property(max_combo_label, "scale", Vector2(1.05,1.05), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(max_combo_label, "scale", Vector2(1,1), 0.0625).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		calculate_accuracy()
		#tux_react()
		tux.flip_h = not tux.flip_h
		comet.self_active = false
		comets.erase(comet)
		$CometBreakSound.play()
		var tween := create_tween().set_parallel(true)
		tween.tween_property(comet, "modulate:a", 0, .125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(comet, "scale", Vector2(2,2), 0.125).set_ease(Tween.EASE_OUT)
		await tween.finished
		if comet:
			comet.queue_free()

func _input(event):
	if event is InputEventKey and event.pressed:
		var shifting = Input.is_key_pressed(KEY_SHIFT)
		var input_char = event.as_text().to_lower()
		
		if mods["CS"]:
			if shifting:
				#print(input_char)
				input_char = input_char.replace("shift+", "")
				input_char = input_char.to_upper()
				#print(input_char)
			else:
				input_char = input_char.to_lower()
		else:
			input_char = input_char.to_upper()
		
		#print(input_char.to_upper())
		if input_char.to_upper() in alphabet:
			if active:
				if len(comets) > 0:
					var comet = comets[0]
					var note_latency = hit_point - comet.position.y
					if (playback_position >= ((comet.timestamp/1000) - leniency)) and (playback_position <= ((comet.timestamp/1000) + leniency)):
						if input_char == comet.get_node("Sprite").get_node("Label").text:
							hit(comet, note_latency)
							'''
							if abs(note_latency) < 25:
								judgments["perfect"] += 1
							elif abs(note_latency) > 25 and abs(note_latency) < 50:
								#print("early: " + str(note_latency))
								judgments["good"] += 1
							elif abs(note_latency) > 50 and abs(note_latency) < leniency:
								judgments["meh"] += 1	
							
							comets_processed += 1
							hit_count += 1
							combo += 1
							if combo > max_combo:
								max_combo = combo
								max_combo_label.text = str(max_combo) + "x"
							calculate_accuracy()
							comet.self_active = false
							comets.erase(comet)
							$CometBreakSound.play()
							var tween := create_tween()
							tween.parallel().tween_property(comet, "modulate:a", 0, .125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
							await tween.finished
							comet.queue_free()
							'''
		elif event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.resume()
				if video.stream:
					video.paused = false
					video.stream_position = playback_position
			elif $OnTop/GameOver.visible or CountdownLabel.visible:
				pass
			else:
				$Back.play()
				active = false
				pause_menu.visible = true
				pause_menu.position = Vector2(0, get_viewport_rect().size.y)
				var tween = create_tween().set_parallel(true)
				tween.tween_property(options_dim, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(pause_menu, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				$BackgroundMusic.stop()
				if video.stream:
					video.paused = true
		elif event.keycode == KEY_ENTER:
			if pause_menu.visible:
				var tween := create_tween()
				tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				#button_sound.play()
				await get_tree().create_timer(1).timeout
				await get_tree().process_frame
				var current_scene = get_tree().current_scene
				var next_scene = load("res://scenes/beat/beat.tscn").instantiate()
				next_scene.word_set = current_scene.word_set
				next_scene.custom = current_scene.custom
				next_scene.mods = current_scene.mods
				next_scene.legacy = current_scene.legacy
				next_scene.official = current_scene.official
				next_scene.beatmap_filename = current_scene.beatmap_filename
				get_tree().change_scene_to_node(next_scene)

'''
func create_bpm_timestamps():
	print("creating bpm timestamps")
	if offset:
		bpm_timestamps.clear()
		var a = offset*1000
		print(bpm)
		var change_by = ((60/bpm)*1000)/divider
		print(change_by)
		
		while (a + change_by) < duration*1000:
			#print("h", a)
			bpm_timestamps.append(a)
			a += change_by
		
		total_beats = len(bpm_timestamps) - 1
		
		mappings.clear()
		for i in range(total_beats):
			if (i) % 2 == 0:
				mappings.append(1)
			else:
				mappings.append(0)
		print(bpm_timestamps)
		print(mappings)
		print(int(offset*1000))
'''


func _on_background_music_finished() -> void:
	started = false
	
	if video.stream:
		video.paused = true
	
	var next_scene = score_screen.instantiate()
	next_scene.song_title = str(song_title) + " [" + str(diff_name) + "]" + " by " + str(artist)
	next_scene.score = total_score
	next_scene.mods = mods
	next_scene.judgments = judgments
	next_scene.accuracy = accuracy
	next_scene.combo = max_combo
	next_scene.legacy = legacy
	next_scene.official = official

	if legacy:
		next_scene.background = load("res://scenes/beat/images/" + str(background))
	else:
		next_scene.background = background

	if max_combo == total_comets:
		next_scene.fc = true
	
	await get_tree().create_timer(2).timeout

	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	get_tree().change_scene_to_node(next_scene)
	

func tux_react():
	if not Config.min_effects:
		var tween := create_tween()
		tween.parallel().tween_property($ActiveBackground/Tux, "position:y", 890, 0.125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		var tween2 := create_tween()
		tween2.parallel().tween_property($ActiveBackground/Tux, "position:y", 900, 0.125).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween2.finished
		
func cheer():
	var tween: Tween
	var tween2: Tween
	if not Config.min_effects:
		cheerleft.position = init_cl_pos
		cheerright.position = init_cr_pos
		cheerleft.modulate.a = 1
		cheerright.modulate.a = 1
		cheerleft.visible = true
		cheerright.visible = true
		particlesleft.emitting = false
		particlesright.emitting = false
		
		tween = create_tween().set_parallel(true)
		tween.tween_property(cheerleft, "position", Vector2(cheerleft.position.x+300, 540), 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		tween.tween_property(cheerright, "position", Vector2(cheerright.position.x-300, 540), 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		await tween.finished
		particlesleft.emitting = true
		particlesright.emitting = true
		
		await get_tree().create_timer(1).timeout
		
		tween2 = create_tween().set_parallel(true)
		tween2.tween_property(cheerleft, "modulate:a", 0, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween2.tween_property(cheerright, "modulate:a", 0, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween2.finished
		
		cheerleft.visible = false
		cheerright.visible = false
