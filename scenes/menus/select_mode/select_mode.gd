extends Control

var game_mode
var difficulty
var stage = 0
var word_select_button = preload("res://scenes/objects/ui/word_select_button.tscn")
var pop_sound_temp = preload("res://scenes/objects/ui/pop.tscn")
var audio_phase = false

@onready var header = self.get_node("Header")
@onready var fade = self.get_node("Fade")

@onready var menu = self.get_node("Menu")
@onready var main_buttons = menu.get_node("MainButtons")
@onready var difficulty_buttons = self.get_node("DifficultySelect")
@onready var word_select = self.get_node("WordSelectScroll").get_node("WordSelect")
@onready var options = self.get_node('Options')

@onready var back_button = get_node("BackButton")
@onready var title_button = get_node("TitleButton")
@onready var title_box = get_node("Title")

# sounds
@onready var button_press = get_node("ButtonPress")
@onready var bye_sound = get_node("Bye")
@onready var back_sound = get_node("Back")
@onready var error_sound = get_node("Error")

func check_text_files(path):
	#clear all prev wordsets
	for child in word_select.get_children():
		child.queue_free()
	var dir = DirAccess.open(path)

	if game_mode == "phrase":
		var new_select_button = word_select_button.instantiate()
		new_select_button.text = "PenguinType"
		new_select_button.penguin = true
		word_select.add_child(new_select_button)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var set_name = file_name.trim_suffix(".txt").capitalize()
				var new_select_button = word_select_button.instantiate()
				new_select_button.text = set_name
				word_select.add_child(new_select_button)
				
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		
func check_phrase_files(path):
	#clear all prev wordsets
	for child in word_select.get_children():
		child.queue_free()
	var dir = DirAccess.open(path)

	if game_mode == "phrase":
		var new_select_button = word_select_button.instantiate()
		new_select_button.text = "PenguinType Mode"
		new_select_button.penguin = true
		word_select.add_child(new_select_button)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var word_set_file_path = path + "/" + file_name
				print(word_set_file_path)
				var word_set_file = FileAccess.open(word_set_file_path, FileAccess.READ)
				var word_set_content = word_set_file.get_as_text()
				var word_set_array = word_set_content.split("\n", true)
				var set_name = word_set_array[0]
				#var set_name = file_name.trim_suffix(".txt").capitalize()
				var new_select_button = word_select_button.instantiate()
				new_select_button.text = set_name
				new_select_button.phrase_set = file_name.trim_suffix(".txt")
				#print(set_name)
				word_select.add_child(new_select_button)
				
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func set_difficulty(d):
	$ButtonPress.play()
	stage = 3

	await close_menu(difficulty_buttons)
	difficulty_buttons.visible = false
	
	var tween1 = create_tween().set_parallel(true)
	tween1.tween_property(header, "position", Vector2(header.position.x, -header.size.y), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween1.finished

	header.text = "Select Word Set"

	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(header, "position", Vector2(header.position.x, 36), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open_menu(word_select)

	difficulty = d
	word_select.visible = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Discord RPC
	var platform = OS.get_name()
	if platform != "Web" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			print("rpcing=================================")
			rpc.details = "Chilling on the Menu"
			rpc.large_image = "icon"
			rpc.small_image = 'None'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			#rpc.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
			
			rpc.refresh()
	
	var _user_beatmaps_folder = DirAccess.make_dir_recursive_absolute("user://beatmaps/")
	var _user_wordsets_folder = DirAccess.make_dir_recursive_absolute("user://word_sets/")
	
	$BackgroundMusic.play()
	game_mode = null
	difficulty = null
	fade.visible = true
	
	if Config.start:
		return_menu()
	
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_word_menu():
	pass

func _on_comet_pressed() -> void:
	
	stage = 1
	back_button.position = Vector2(-back_button.size.x, 0)
	back_button.visible = true
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(back_button, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game_mode = "comet"
	self.get_node("ButtonPress").play()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu, "position", Vector2(menu.position.x, get_viewport_rect().size.y), .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	header.position = Vector2(header.position.x, -header.size.y)
	header.text = "Select Difficulty"
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(header, "position", Vector2(header.position.x, 36), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#await tween2.finished

	menu.visible = false
	difficulty_buttons.visible = true
	open_menu(difficulty_buttons)

	if Config.wumba:
		check_text_files("res://gameplay/wumba")
	else:
		check_text_files("res://gameplay/word_sets")
	#audio_phase = true

func _on_cascade_pressed() -> void:
	stage = 1
	back_button.visible = true
	back_button.position = Vector2(-back_button.size.x, 0)
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(back_button, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game_mode = "cascade"
	self.get_node("ButtonPress").play()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu, "position", Vector2(menu.position.x, get_viewport_rect().size.y), .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	header.position = Vector2(header.position.x, -header.size.y)
	header.text = "Select Difficulty"
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(header, "position", Vector2(header.position.x, 36), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#await tween2.finished

	menu.visible = false
	difficulty_buttons.visible = true
	open_menu(difficulty_buttons)

	if Config.wumba:
		check_text_files("res://gameplay/wumba")
	else:
		check_text_files("res://gameplay/word_sets")
	#audio_phase = true

func _on_lessons_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	self.get_node("ButtonPress").play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	var next_scene = load("res://scenes/game/lessons.tscn").instantiate()
	get_tree().change_scene_to_node(next_scene)

func _on_options_pressed() -> void:
	self.get_node("ButtonPress").play()
	header.text = ""
	stage = 2
	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu, "position", Vector2(menu.position.x, -menu.size.y), .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	menu.visible = false
	options.visible = true
	options.open_menu(options.get_node("BoxContainer"))

func _on_quit_pressed() -> void:
	$BackgroundMusic.stop()
	$Bye.play()
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()

func open_menu(menut):
	print("h")
	for button in menut.get_children():
		button.active = false
		#button.visible = true
		button.modulate.a = 0
		button.scale = Vector2(0.0,0.0)
	
	menut.visible = true
	await get_tree().create_timer(.125).timeout
	
	var last_tween
	var buttons = menut.get_children()
	for button in buttons:
		button.scale = Vector2(0.0,0.0)
		button.modulate.a = 1
		last_tween = create_tween()
		#button.scale = Vector2(0.0,0.0)
		last_tween.tween_property(button, "scale", Vector2(1, 1), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await get_tree().create_timer(.04).timeout
		button.active = true
	#await last_tween.finished
			
func close_menu(menut):
	#scene.get_node('OnTop/Pause').get_node('BoxContainer').visible = true
	var last_tween	
	var buttons = menut.get_children()
	buttons.reverse()
	for button in buttons:
		button.scale = Vector2(1.0,1.0)
		last_tween = create_tween()
		last_tween.tween_property(button, "scale", Vector2(0, 0.0), .25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(.04).timeout
		#button.modulate.a = 0
		button.active = false
	await last_tween.finished
	menut.visible = false
	#self.visible = false
	return true

func go_back():
	back_button.disabled = true
	if stage == 1:
		$Back.play()
		stage = 0
		#back_button.visible = false
		var tween3 = create_tween().set_parallel(true)
		tween3.tween_property(back_button, "position", Vector2(-back_button.size.x, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		#await tween3.finished
		game_mode = null
		#difficulty_buttons.visible = false
		await close_menu(difficulty_buttons)
		back_button.visible = false
		var tween1 = create_tween().set_parallel(true)
		tween1.tween_property(header, "position", Vector2(header.position.x, -header.size.y), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween1.finished
		header.text = ""
		difficulty_buttons.visible = false
		menu.visible = true
		var tween = create_tween().set_parallel(true)
		tween.tween_property(menu, "position", Vector2(menu.position.x, 150.219), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		back_button.disabled = false
		#audio_phase = false
	if stage == 2:
		$Back.play()
		stage = 0
		game_mode = null

		if options.visible:
			await options.close_menu(options.get_node("BoxContainer"))
		elif word_select.visible:
			var tween3 = create_tween().set_parallel(true)
			tween3.tween_property(back_button, "position", Vector2(-back_button.size.x, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await close_menu(word_select)
			back_button.visible = false

		var tween1 = create_tween().set_parallel(true)
		tween1.tween_property(header, "position", Vector2(header.position.x, -header.size.y), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween1.finished

		header.text = ""

		menu.visible = true
		options.visible = false
		word_select.visible = false
		var tween = create_tween().set_parallel(true)
		tween.tween_property(menu, "position", Vector2(menu.position.x, 150.219), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
	if stage == 3:
		$Back.play()
		stage = 1
		difficulty = null
		await close_menu(word_select)
		open_menu(difficulty_buttons)

		var tween = create_tween().set_parallel(true)
		tween.tween_property(header, "position", Vector2(header.position.x, -header.size.y), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished

		header.text = "Select Difficulty"

		var tween2 = create_tween().set_parallel(true)
		tween2.tween_property(header, "position", Vector2(header.position.x, 36), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween2.finished

		difficulty_buttons.visible = true
		word_select.visible = false
		back_button.disabled = false
		
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if not back_button.disabled:
				go_back()

func _on_extreme_pressed() -> void:
	set_difficulty(5)

func _on_pro_pressed() -> void:
	set_difficulty(4)

func _on_hard_pressed() -> void:
	set_difficulty(3)

func _on_medium_pressed() -> void:
	set_difficulty(2)

func _on_easy_pressed() -> void:
	set_difficulty(1)

func _on_proper_rhythm_pressed() -> void:
	var platform = OS.get_name()

	if platform != "Web":
		var tween := create_tween()
		tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		self.get_node("ButtonPress").play()
		await get_tree().create_timer(1).timeout
		await get_tree().process_frame
		var next_scene = load("res://scenes/beat/rhythmgame.tscn").instantiate()
		get_tree().change_scene_to_node(next_scene)
	else:
		error_sound.play()


func _on_back_button_pressed() -> void:
	go_back()


func _on_phrase_typing_pressed() -> void:
	stage = 2
	back_button.visible = true
	back_button.position = Vector2(-back_button.size.x, 0)
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(back_button, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game_mode = "phrase"
	self.get_node("ButtonPress").play()

	if Config.wumba:
		check_phrase_files("res://gameplay/wumba")
	else:
		check_phrase_files("res://gameplay/phrases")

	header.position = Vector2(header.position.x, -header.size.y)
	header.text = "Select Phrase"
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(header, "position", Vector2(header.position.x, 36), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#await tween2.finished

	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu, "position", Vector2(menu.position.x, get_viewport_rect().size.y), .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	menu.visible = false
	open_menu(word_select)


func _on_title_button_pressed() -> void:
	Config.start = true
	print("pressed")
	button_press.play()
	title_button.active = false
	var tween = create_tween()
	tween.tween_property(title_button, "scale", Vector2(0.0, 0.0), .5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await tween.finished
	title_button.visible = false

	var platform = OS.get_name()
	if platform == "Web":
		main_buttons.get_node("Quit").queue_free()
		main_buttons.get_node("ProperRhythm").text = "Web Not Supported"
	
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(title_box.get_node("TitlePanel"), "self_modulate:a", 0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween2.tween_property(title_box, "position", Vector2(24, 848), .5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween2.tween_property(title_box, "scale", Vector2(0.5, 0.5), .5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await tween2.finished
	
	title_box.up()
	
	menu.position.y = -(menu.position.y + menu.size.y)
	menu.visible = true
	
	for button in main_buttons.get_children():
		button.active = false
		button.scale = Vector2(0.0,0.0)
	
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(menu, "position", Vector2(menu.position.x, 150.219), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween3.finished
	#menu.up()
	
	var last_tween
	for button in main_buttons.get_children():
			button.visible = true
			last_tween = create_tween()
			last_tween.tween_property(button, "scale", Vector2(1, 1), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			var new_pop = pop_sound_temp.instantiate()
			self.add_child(new_pop)
			new_pop.play()
			new_pop.finished.connect(new_pop.queue_free)
			await get_tree().create_timer(0.08).timeout
	
	await last_tween.finished
	
	for button in main_buttons.get_children():
		button.active = true

func return_menu() -> void:
	title_button.active = false
	title_button.visible = false

	var platform = OS.get_name()
	if platform == "Web":
		main_buttons.get_node("Quit").queue_free()
		main_buttons.get_node("ProperRhythm").text = "Web Not Supported"
	
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(title_box.get_node("TitlePanel"), "self_modulate:a", 0, 0.001).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween2.tween_property(title_box, "position", Vector2(24, 848), .001).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween2.tween_property(title_box, "scale", Vector2(0.5, 0.5), .001).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await tween2.finished
	
	title_box.up()
	
	menu.position.y = -(menu.position.y + menu.size.y)
	menu.visible = true
	
	for button in main_buttons.get_children():
		button.active = false
		button.scale = Vector2(0.0,0.0)
	
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(menu, "position", Vector2(menu.position.x, 150.219), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween3.finished
	#menu.up()
	
	var last_tween
	for button in main_buttons.get_children():
			button.visible = true
			last_tween = create_tween()
			last_tween.tween_property(button, "scale", Vector2(1, 1), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			var new_pop = pop_sound_temp.instantiate()
			self.add_child(new_pop)
			new_pop.play()
			new_pop.finished.connect(new_pop.queue_free)
			await get_tree().create_timer(0.08).timeout
	
	await last_tween.finished
	
	for button in main_buttons.get_children():
		button.active = true
