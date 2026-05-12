extends Node2D

# word stuff
var word_set
var word_set_file_path
var word_set_file
var word_set_content
var word_set_array
var custom

var penguin = false
var selected_penguin_index = 0
var string_count = 25
var word_count_per = 8

# random vars
var alphabet = [
"a","b","c","d","e","f","g","h","i","j","k","l","m","n",
"o","p","q","r","s","t","u","v","w","x","y","z"
]

var symbols = {
"space" : " ",
"apostrophe" : "'",
"shift+slash" : "?",
"period" : ".",
"bracketleft" : "{",
"bracketright" : "}",
"shift+bracketleft" : "[",
"shift+bracketright" : "]",
"comma" : ",",
"shift+apostrophe" : '"',
"semicolon" : ";",
"shift+1" : "!",
"shift+2" : "@",
"shift+3" : "#",
"shift+4" : "$",
"shift+5" : "%",
"shift+6" : "^",
"shift+7" : "&",
"shift+8" : "*",
"shift+9" : "(",
"shift+0" : ")",
"shift+minus" : "_",
"shift+plus" : "+",
"minus" : "-",
"plus" : "+",
"shift+semicolon" : ":"
}

var exceptions = [
	"escape",
	"shift",
	"enter",
	"meta",
	"alt"
]

var active
var winned = false
var started = false

@onready var on_top = get_node("OnTop")

@onready var hud = on_top.get_node("HUD")

@onready var text = hud.get_node("Text")
@onready var penguin_options = hud.get_node("PenguinOptions")

@onready var word_stack = hud.get_node("WordSelect")
@onready var word_dropdown = word_stack.get_node("WordDropdown")

@onready var sound_stack = hud.get_node("SoundSelect")
@onready var sound_dropdown = sound_stack.get_node("SoundDropdown")

@onready var info = hud.get_node("Info")
@onready var wpm_label = info.get_node("WPM")
@onready var word_label = info.get_node("Words")
@onready var error_label = info.get_node("Errors")

#sounds
#@onready var type_sound = get_node("Hitsound")
@onready var button_press = get_node("ButtonPress")
@onready var back_sound = get_node("Back")
@onready var error_sound = get_node("Error")
@onready var win_sound = get_node("Win")

@onready var options_dim = on_top.get_node("OptionsDim")

var fade
var pause_menu

var strings = []
var char_index = 0
var string_index = 0

var error_count = 0
var word_count = 0

var start_time
var current_time
var end_time

var sound_set = []
var sound_object = preload("res://scenes/objects/game/typesound.tscn")
var selected_sound_index = 0

var dyslexic_font = preload("res://assets/visual/fonts/dyslexic.otf")

func load_sounds(type_enum):
	print("loading sounds")
	selected_sound_index = type_enum
	for thing in sound_set:
		thing.queue_free()
	sound_set.clear()
	var path
	
	match type_enum:
		0:
			path = "res://assets/audio/clicks/clack"
		1:
			path = "res://assets/audio/clicks/dit"
		2:
			path = "res://assets/audio/clicks/pop"
		3:
			path = "res://assets/audio/clicks/type"
	
	print(path)
			
	var dir = DirAccess.open(path)
	print(dir)

	if dir:
		print("Scanning...")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			#print("Proceeding...")
			print(file_name)
			if file_name.ends_with(".ogg"):
				print("loading: " + str(file_name))
				var new_sound = sound_object.instantiate()
				print(path + file_name)
				new_sound.stream = load(path + "/" + file_name)
				add_child(new_sound)
				sound_set.append(new_sound)
				
			file_name = dir.get_next()
	else:
		pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Config.wumba:
		$OnTop/HUD/Wumba.visible = true
	
	if Config.dyslexic_mode:
		text.add_theme_font_override("normal_font", dyslexic_font)

	if Config.improve_readability:
		on_top.get_node("Background").visible = false

	#Discord RPC
	#Discord RPC
	var platform = OS.get_name()
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.details = "Typing..."
			rpc.large_image = "icon" # Image key from "Art Assets"
			rpc.small_image = 'phrase'
			rpc.small_image_text = 'Phrase Typing'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
			
			rpc.refresh()
	
	sound_dropdown.selected = selected_sound_index
	load_sounds(selected_sound_index)
	
	active = true
	
	pause_menu = on_top.get_node("Pause")
	fade = on_top.get_node("Fade")
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	#Load phrases
	if penguin:
		#penguin_Config.visible = true
		word_stack.visible = true

		word_dropdown.selected = selected_penguin_index

		word_set_file_path = "res://gameplay/word_sets/" + word_set + ".txt"

		#print(word_set_file_path)
		word_set_file = FileAccess.open(word_set_file_path, FileAccess.READ)
		
		word_set_content = word_set_file.get_as_text()
		word_set_array = word_set_content.split("\n", true)
		word_set_array.remove_at(0)

		for i in range(string_count):
			var new_string = word_set_array[randi_range(0,len(word_set_array)-1)].to_lower()

			for j in range(word_count_per):
				var new_word = word_set_array[randi_range(0,len(word_set_array)-1)]
				new_string = new_string + " " + new_word.to_lower()
			
			if i < string_count:
				new_string = new_string + " "

			strings.append(new_string)
		
		if strings[len(strings)-1] == "":
			strings.remove_at(len(strings)-1)
		
		text.text = strings[0] + "\n" + strings[1]
		
			#Discord RPC
		if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
			var rpc = Engine.get_singleton("DiscordRPC")
			if rpc:
				rpc.details = '"PenguinType Mode"'
				rpc.refresh()
	else:
		if Config.wumba:
			word_set_file_path = "res://gameplay/wumba/" + word_set + ".txt"
		else:
			if custom:
				word_set_file_path = "user://phrases/" + word_set + ".txt"
			else:
				word_set_file_path = "res://gameplay/phrases/" + word_set + ".txt"

		print(word_set_file_path)
		word_set_file = FileAccess.open(word_set_file_path, FileAccess.READ)
		
		# Gets file contents as text
		word_set_content = word_set_file.get_as_text()
		
		# Splits text file contents by line and removes the first entry (its just the name)
		strings = word_set_content.split("\n", true)
		strings.remove_at(0)
		
		if strings[len(strings)-1] == "":
			strings.remove_at(len(strings)-1)
		
		text.text = strings[0]
		
			#Discord RPC
		if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
			var rpc = Engine.get_singleton("DiscordRPC")
			if rpc:
				rpc.details = '"' + word_set_content.split("\n", true)[0] + '"'
				rpc.refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not winned:
		current_time = Time.get_unix_time_from_system()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
				if pause_menu.visible:
					pause_menu.resume()
				elif $OnTop/GameOver.visible:
						pass
				else:
					#$Back.play()
					active = false
					pause_menu.visible = true
					pause_menu.position = Vector2(0, get_viewport_rect().size.y)
					var tween = create_tween().set_parallel(true)
					tween.tween_property(options_dim, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tween.tween_property(pause_menu, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					#$BackgroundMusic.volume_db = -15
					
		if event.keycode == KEY_ENTER:
			if penguin:
				var penguin_sets = ["penguintype100", "penguintype1k", "penguintype10k"]


				var tween := create_tween()
				tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				await get_tree().create_timer(1).timeout
				await get_tree().process_frame
				var next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
				next_scene.word_set = penguin_sets[selected_penguin_index]
				next_scene.selected_penguin_index = selected_penguin_index
				next_scene.word_set = word_set
				next_scene.penguin = true
				next_scene.selected_sound_index = selected_sound_index
				get_tree().change_scene_to_node(next_scene)
			else:
				var tween := create_tween()
				tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				await get_tree().create_timer(1).timeout
				await get_tree().process_frame
				var next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
				next_scene.word_set = word_set
				next_scene.selected_sound_index = selected_sound_index
				get_tree().change_scene_to_node(next_scene)
		
		var input_char = event.as_text().to_lower()
		if active and not winned:
			var shifting = Input.is_key_pressed(KEY_SHIFT)
			#print(input_char)

			if input_char in symbols.keys():
				input_char = symbols[input_char]
			elif shifting:
				input_char = input_char.replace("shift+", "")
				input_char = input_char.to_upper()

			#print(input_char)
			
			if input_char == strings[string_index][char_index]:
				if not started:
					start_time = Time.get_unix_time_from_system()
					started = true
				
				if input_char == " ":
					word_count+=1
					word_label.text = "Words: " + str(word_count)

					wpm_label.text = "WPM: " + str(int((word_count*60/(current_time-start_time))))
				
				#type_sound.play()
				if len(sound_set) > 0:
					sound_set.pick_random().play()
				if char_index == len(strings[string_index])-1:
					string_index += 1
					
					word_count+=1
					word_label.text = "Words: " + str(word_count)
					wpm_label.text = "WPM: " + str(int((word_count*60/(current_time-start_time))))
					
					if string_index <= (len(strings)-1):
						if penguin:
							if (string_index+1) <= (len(strings)-1):
								text.text = strings[string_index] + "\n" + strings[string_index+1]
							else:
								text.text = strings[string_index]
						else:
							text.text = strings[string_index]
					else:
						winned = true
						active = false
						
						var h = str(strings[string_index-1])
						h = h.insert(char_index+1, "[/color]")
						h = h.insert(0, "[color=green]")
						text.text = h
						win_sound.play()
						print("you win")
					char_index = 0
				else:
					var h = ""
					char_index += 1
					
					if penguin:
						#print("penguin!")
						if (string_index+1) <= (len(strings)-1):
							#print("oo")
							h = strings[string_index] + "\n" + strings[string_index+1]
						else:
							#print("aa")
							h = strings[string_index]
					else:
						h = str(strings[string_index])

					#var h = "[color=green]" + str(strings[string_index])
					h = h.insert(char_index, "[/color]")
					h = h.insert(0, "[color=green]")
					#print(h)
					text.text = h
			elif not input_char.to_lower() in exceptions:
				error_count += 1
				error_label.text = "Errors: " + str(error_count)
				#error_sound.play()


func _on_word_dropdown_item_selected(index: int) -> void:
	var penguin_sets = ["penguintype100", "penguintype1k", "penguintype10k"]

	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	var next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
	next_scene.word_set = penguin_sets[index]
	next_scene.selected_penguin_index = index
	next_scene.penguin = true
	next_scene.selected_sound_index = selected_sound_index
	get_tree().change_scene_to_node(next_scene)


func _on_sound_dropdown_item_selected(index: int) -> void:
	load_sounds(index)
