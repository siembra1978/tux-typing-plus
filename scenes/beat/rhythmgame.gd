extends Node2D

# initialize ui
@onready var control = get_node("CanvasLayer/Control")
@onready var hud = control.get_node("HUD")

# preview ui
@onready var preview = control.get_node("Preview")
@onready var scroll_box = preview.get_node("Scroll")
@onready var song_artist_label = scroll_box.get_node("SongArtist")
@onready var mapper_label = preview.get_node("Panel/HBoxContainer/Mapper")
@onready var difficulty_label = preview.get_node("Difficulty")
@onready var duration_label = preview.get_node("Panel/HBoxContainer/Duration")
@onready var dropshadow = control.get_node("DropShadow")
@onready var ar_label = preview.get_node("Panel/HBoxContainer/VBoxContainer/AR")
@onready var od_label = preview.get_node("Panel/HBoxContainer/VBoxContainer/OD")
@onready var hp_label = preview.get_node("Panel/HBoxContainer/VBoxContainer/HP")
@onready var bpm_label2 = preview.get_node("Panel/HBoxContainer/BPM")

# top ui
@onready var top = hud.get_node("Top")
@onready var word_select = top.get_node("WordSelect")
@onready var word_dropdown = word_select.get_node("WordDropdown")

# middle ui
#@onready var mid = hud.get_node("Middle")
#@onready var header = mid.get_node("Header")
#@onready var selected_beatmap_label = mid.get_node("SelectedMapLabel")

#@onready var sorted = control.get_node("MapsBox")
# beatmap info
#@onready var beatmap_info = sorted.get_node("BeatmapInfo")
#@onready var song_name_label = beatmap_info.get_node("SongName")
#@onready var artist_label = beatmap_info.get_node("Artist")
#@onready var mapper_label = beatmap_info.get_node("Mapper")
#@onready var bpm_label = beatmap_info.get_node("BPM")
#@onready var difficulty_label = beatmap_info.get_node("Difficulty")
#@onready var audio_name_label = beatmap_info.get_node("AudioName")
#@onready var ar_label = beatmap_info.get_node("AR")
#@onready var od_label = beatmap_info.get_node("OD")
#@onready var hp_label = beatmap_info.get_node("HP")
#@onready var duration_label = beatmap_info.get_node("Duration")
# button scroller
@onready var button_scroll = control.get_node("ScrollContainer")
@onready var select_buttons = button_scroll.get_node("SelectButtons")

# bottom ui
@onready var btm = control.get_node("Options")
@onready var mod_dim = control.get_node("ModDim")
@onready var mod_button = btm.get_node("Mods")
@onready var mod_menu = control.get_node("ModMenu")
@onready var mods_stack = mod_menu.get_node("Mods")
@onready var basic_mods = mods_stack.get_node("BasicMods")
@onready var gameplay_mods = mods_stack.get_node("GameplayMods")

@onready var ez_button = gameplay_mods.get_node("Easy")
@onready var hr_button = gameplay_mods.get_node("Hardrock")
#@onready var nf_button = mod_menu.get_node("NoFail")
@onready var ht_button = basic_mods.get_node("HalfTime")
@onready var dt_button = basic_mods.get_node("DoubleTime")
#@onready var ap_button = mod_menu.get_node("Auto")

# extra ui
@onready var fade = control.get_node("Fade")

# objects
@onready var music = $Music
@onready var video = $CanvasLayer/Control/VideoStreamPlayer
@onready var button_sound = $ButtonPress
@onready var error_sound = $Error
var pop_sound_temp = preload("res://scenes/objects/ui/pop.tscn")

# initialize variables
#var selected_word_set
var selected_file
var legacy_file_loaded
var official_file_loaded
#var word_sets = []

var mods = {
	"EZ": false,
	"NF": false,
	"HT": false,
	"DT": false,
	"AP": false,
	"HR": false,
	"CS": false,
	"HD": false,
}

var min_bpm = 0
var max_bpm = 0

var AR = 1
var OD = 1
var HP = 1

# initialize objects
var beatmap_select_button = preload("res://scenes/objects/ui/beatmap_select_button.tscn")

var active_button

func format_time(s: int) -> String:
	if mods["DT"]:
		s = s*(2.0/3.0)
	if mods["HT"]:
		s = s*(4.0/3.0)

	var minutes = int(s / 60)
	var seconds = fmod(s,60.0)

	return "%02d:%02d" % [minutes, seconds]

func refresh_detail_labels():
	if mods["EZ"]:
		ar_label.text = "AR " + str(AR*.5)
		ar_label.label_settings.font_color = Color.GREEN
		od_label.text = "OD " + str(OD*.5)
		od_label.label_settings.font_color = Color.GREEN
		hp_label.text = "HP " + str(HP*.5)
		hp_label.label_settings.font_color = Color.GREEN
	elif mods["HR"]:
		ar_label.text = "AR " + str(AR*1.25)
		ar_label.label_settings.font_color = Color.RED
		od_label.text = "OD " + str(OD*1.25)
		od_label.label_settings.font_color = Color.RED
		hp_label.text = "HP " + str(HP*1.25)
		hp_label.label_settings.font_color = Color.RED
	else:
		ar_label.text = "AR " + str(AR)
		ar_label.label_settings.font_color = Color.WHITE
		od_label.text = "OD " + str(OD)
		od_label.label_settings.font_color = Color.WHITE
		hp_label.text = "HP " + str(HP)
		hp_label.label_settings.font_color = Color.WHITE

	if min_bpm == max_bpm:
		if mods["DT"]:
			bpm_label2.text = "BPM\n" + str(max_bpm*1.5)
			bpm_label2.label_settings.font_color = Color.RED
		elif mods["HT"]:
			bpm_label2.text = "BPM\n" + str(max_bpm*.75)
			bpm_label2.label_settings.font_color = Color.GREEN
		else:
			bpm_label2.text = "BPM\n" + str(max_bpm)
			bpm_label2.label_settings.font_color = Color.WHITE
	else:
		if mods["DT"]:
			bpm_label2.text = "BPM\n" + str(min_bpm*1.5) + "-" + str(max_bpm*1.5)
			bpm_label2.label_settings.font_color = Color.RED
		elif mods["HT"]:
			bpm_label2.text = "BPM\n" + str(min_bpm*.75) + "-" + str(max_bpm*.75)
			bpm_label2.label_settings.font_color = Color.GREEN
		else:
			bpm_label2.text = "BPM\n" + str(min_bpm) + "-" + str(max_bpm)
			bpm_label2.label_settings.font_color = Color.WHITE

func load_official_beatmap(file_name: String):
	preview.visible = true
	#print("user://beatmaps/" + file_name)

	var file = FileAccess.open("res://gameplay/beatmaps/" + file_name + "/" + file_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error == OK:
		var data = json.data

		#selected_beatmap_label.text = "Currently Selected Map: " + str(file_name)
		#song_name_label.text = "Song Name: " + str(data["name"])
		#artist_label.text = "Artist: " + str(data["artist"])
		song_artist_label.text = str(data["name"]) + " - " + str(data["artist"])
		mapper_label.text = "Mapper\n" + str(data["mapper"])
		#bpm_label.text = "BPM: " + str(data["bpm"])
		difficulty_label.text = "[" + str(data["difficulty"]) + "]"
		#audio_name_label.text = "Audio: " + str(data["song_name"])
		selected_file = str(file_name)

		AR = data["AR"]
		OD = data["OD"]
		HP = data["HP"]

		scroll_box.reset()

		#print("user://beatmaps/" + file_name + "/" + str(data["song_name"]))
		var music_path = "res://gameplay/beatmaps/" + file_name + "/" + str(data["song_name"])
		var pbp = 0.0

		if "preview_point" in data:
			pbp = data["preview_point"]

		var stream = load(music_path)

		if stream:
			music.stream = stream
			music.play(pbp)
			duration_label.text = "" + format_time(music.stream.get_length())
		else:
			duration_label.text = "???"
			push_error("Failed to load music at: " + music_path)

		legacy_file_loaded = false
		official_file_loaded = true

		var bpms = [data["bpm"]]

		if "changed_indices" in data:
			var changed_bpms = data["changed_indices"]
			if data["changed_indices"]:
				for index in changed_bpms.keys():
					bpms.append(changed_bpms[index])

		min_bpm = bpms.min()
		max_bpm = bpms.max()

		refresh_detail_labels()

		if data["background"]:
			$CanvasLayer/Control/CustomBackground.visible = true
			$CanvasLayer/Control/BGDim.visible = true
			#print("res://gameplay/beatmaps/" + file_name + "/background.jpg")
			var img = load("res://gameplay/beatmaps/" + file_name + "/" + data["background"])
			$CanvasLayer/Control/CustomBackground.texture = img
			$CanvasLayer/Control/Preview/PanelContainer/SongPreview.texture = img
		else:
			$CanvasLayer/Control/Preview/PanelContainer/SongPreview.texture = null
			$CanvasLayer/Control/CustomBackground.visible = false
			#$CanvasLayer/Control/BGDim.visible = false
		#print("Loaded beatmap successfully!")
		if "video" in data:
			if data["video"]:
				$CanvasLayer/Control/BGDim.visible = true
				$CanvasLayer/Control/CustomBackground.visible = false
				video.visible = true
				#print("user://beatmaps/" + file_name + "/video.ogv")
				video.stream = load("res://gameplay/beatmaps/" + file_name + "/video.ogv")
				video.play()
				video.stream_position = pbp
			else:
				video.visible = false
				video.stop()
		else:
			video.visible = false
			video.stop()
	else:
		pass
		#print("JSON Parse Error: ", json.get_error_message())

func load_beatmap(file_name: String):
	preview.visible = true
	if not DirAccess.dir_exists_absolute("user://beatmaps/" + file_name):
		print("No beatmap folder found")
		return

	var file = FileAccess.open("user://beatmaps/" + file_name + "/" + file_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error == OK:
		var data = json.data

		#selected_beatmap_label.text = "Currently Selected Map: " + str(file_name)
		#song_name_label.text = "Song Name: " + str(data["name"])
		#artist_label.text = "Artist: " + str(data["artist"])
		song_artist_label.text = str(data["name"]) + " - " + str(data["artist"])
		mapper_label.text = "Mapper\n" + str(data["mapper"])
		#bpm_label.text = "BPM: " + str(data["bpm"])
		difficulty_label.text = "[" + str(data["difficulty"]) + "]"
		#audio_name_label.text = "Audio: " + str(data["song_name"])
		selected_file = str(file_name)

		AR = data["AR"]
		OD = data["OD"]
		HP = data["HP"]

		scroll_box.reset()

		#print("user://beatmaps/" + file_name + "/" + str(data["song_name"]))
		var music_path = "user://beatmaps/" + file_name + "/" + str(data["song_name"])
		var pbp = 0.0

		if "preview_point" in data:
			pbp = data["preview_point"]

		var bpms = [data["bpm"]]

		if "changed_indices" in data:
			var changed_bpms = data["changed_indices"]
			if data["changed_indices"]:
				for index in changed_bpms.keys():
					bpms.append(changed_bpms[index])

		min_bpm = snappedf(bpms.min(), .1)
		max_bpm = snappedf(bpms.max(), .1)

		refresh_detail_labels()

		if data["song_name"].ends_with(".mp3"):
			if FileAccess.file_exists(music_path):
				#print("Loading MP3")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamMP3.new()
				stream.data = buffer
				music.stream = stream
				music.play(pbp)
		elif data["song_name"].ends_with(".ogg"):
			if FileAccess.file_exists(music_path):
				#print("Loading OGG")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
				music.stream = stream
				music.play(pbp)
		duration_label.text = "" + format_time(music.stream.get_length())

		legacy_file_loaded = false
		official_file_loaded = false

		if data["background"]:
			$CanvasLayer/Control/CustomBackground.visible = true
			$CanvasLayer/Control/BGDim.visible = true
			#print("user://beatmaps/" + file_name + "/background.jpg")
			$CanvasLayer/Control/CustomBackground.texture = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["background"]))
			$CanvasLayer/Control/Preview/PanelContainer/SongPreview.texture = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["background"]))
		else:
			$CanvasLayer/Control/CustomBackground.visible = false
			$CanvasLayer/Control/Preview/PanelContainer/SongPreview.texture = null
			#$CanvasLayer/Control/BGDim.visible = false
		#print("Loaded beatmap successfully!")
		if "video" in data:
			if data["video"]:
				$CanvasLayer/Control/BGDim.visible = true
				$CanvasLayer/Control/CustomBackground.visible = false
				video.visible = true
				#print("user://beatmaps/" + file_name + "/video.ogv")
				video.stream = load("user://beatmaps/" + file_name + "/video.ogv")
				video.play()
				video.stream_position = pbp
			else:
				video.visible = false
				video.stop()
		else:
			$CanvasLayer/Control/CustomBackground.visible = false
			video.visible = false
			video.stop()

	else:
		pass
		#print("JSON Parse Error: ", json.get_error_message())


# get text files
func check_text_files(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var set_name = file_name.trim_suffix(".txt").capitalize()
				word_dropdown.add_item(set_name)

			file_name = dir.get_next()
	else:
		pass
		#print("An error occurred when trying to access the path.")

# get beatmap files
func check_official_beatmap_files(path):
	var dir = DirAccess.open(path)
	#print("Opened directory: " + path)
	if dir:
		#print("Scanning...")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			#print("Proceeding...")
			if dir.current_is_dir():
				#print("Fetching beatmap json...")
				var file = FileAccess.open(path + "/" + file_name + "/" + file_name + ".json", FileAccess.READ)
				var content = file.get_as_text()
				file.close()

				var json = JSON.new()
				var error = json.parse(content)

				if error == OK:
					var data = json.data
					var new_select_button = beatmap_select_button.instantiate()
					new_select_button.text = str(data["name"]) + " \n[" + str(data["difficulty"]) + "] "
					if data.has("background") and data['background'] != null:
						new_select_button.get_node("Image").texture = load("res://gameplay/beatmaps/" + file_name + "/" + data["background"])
					new_select_button.given_filename = str(file_name)
					new_select_button.legacy = false
					new_select_button.official = true
					select_buttons.add_child(new_select_button)

					#print("Loaded beatmap successfully!")
				else:
					pass
					#print("JSON Parse Error: ", json.get_error_message())
			file_name = dir.get_next()
	else:
		pass
		#print("An error occurred when trying to access the path.")

func check_beatmap_files(path):
	var dir = DirAccess.open(path)
	#print("Opened directory: " + path)
	if dir:
		#print("Scanning...")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			#print("Proceeding...")
			if dir.current_is_dir():
				#print("Fetching beatmap json...")
				var file = FileAccess.open(path + "/" + file_name + "/" + file_name + ".json", FileAccess.READ)
				#print(file_name)
				var content = file.get_as_text()
				file.close()

				var json = JSON.new()
				var error = json.parse(content)

				if error == OK:
					var data = json.data
					var new_select_button = beatmap_select_button.instantiate()
					new_select_button.text = str(data["name"]) + "* \n[" + str(data["difficulty"]) + "] "
					if data.has("background") and data['background'] != null:
						#print("kys: " + data["name"])
						new_select_button.get_node("Image").texture = ImageTexture.create_from_image(Image.load_from_file("user://beatmaps/" + file_name + "/" + data["background"]))
					new_select_button.given_filename = str(file_name)
					new_select_button.legacy = false
					select_buttons.add_child(new_select_button)

					#print("Loaded beatmap successfully!")
				else:
					pass
					#print("JSON Parse Error: ", json.get_error_message())
			file_name = dir.get_next()
	else:
		pass
		#print("An error occurred when trying to access the path.")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	preview.visible = false
	if Config.wumba:
		$CanvasLayer/Control/Wumba.visible = true
	#Discord RPC
		#Discord RPC
	var platform = OS.get_name()
	if platform != "Web" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			print("rhythm rpcs!!")
			rpc.details = "♫ Choosing a Song ♫"
			rpc.large_image = "icon"
			rpc.small_image = 'music'
			rpc.small_image_text = 'Proper Rhythm'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

			rpc.refresh()

	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if Config.wumba:
		check_text_files("res://gameplay/wumba")
	else:
		check_text_files("res://gameplay/word_sets")
	#check_legacy_beatmap_files("res://scenes/beat/maps")
	check_official_beatmap_files("res://gameplay/beatmaps")
	check_beatmap_files("user://beatmaps")

	preview.up()
	dropshadow.up()

	for button in select_buttons.get_children():
		button.active = false
		#button.visible = true
		button.modulate.a = 0
		button.scale = Vector2(0.0,0.0)

	await get_tree().create_timer(.25).timeout

	var last_tween
	for button in select_buttons.get_children():
		button.scale = Vector2(0.0,0.0)
		button.modulate.a = 1
		last_tween = create_tween()
		last_tween.tween_property(button, "scale", Vector2(1, 1), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		#var new_pop = pop_sound_temp.instantiate()
		#self.add_child(new_pop)
		#new_pop.play()
		#new_pop.finished.connect(new_pop.queue_free)
		await get_tree().create_timer(.04).timeout
		button.active = true

	#for button in select_buttons.get_children():
		#button.active = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select_file(button, give_filename, official, legacy):
	if active_button:
		var tween = create_tween()
		tween.tween_property(active_button, "scale", Vector2(1.0, 1.00), 0.1).set_ease(Tween.EASE_OUT)
		await tween.finished
		active_button.active = true
	active_button = button
	active_button.active = false
	var tween = create_tween()
	tween.tween_property(active_button, "scale", Vector2(1.075, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	#active_button.set_pressed_no_signal(true)
	dropshadow.visible = true

	if official:
		load_official_beatmap(give_filename)
	else:
		load_beatmap(give_filename)


func _on_back_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/menus/select_mode/select_mode.tscn")


func _on_start_pressed() -> void:
	if selected_file:
		var tween := create_tween()
		tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button_sound.play()
		await get_tree().create_timer(1).timeout
		await get_tree().process_frame
		var word_set = word_dropdown.get_item_text(word_dropdown.get_selected_id()).to_lower().replace(" ", "")
		print(word_set)
		var next_scene = load("res://scenes/beat/beat.tscn").instantiate()
		next_scene.word_set = word_set
		next_scene.beatmap_filename = selected_file
		next_scene.mods = mods
		next_scene.legacy = legacy_file_loaded
		next_scene.official = official_file_loaded
		print(selected_file)
		get_tree().change_scene_to_node(next_scene)
	else:
		error_sound.play()


func _on_editor_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	Config.load_scene("res://scenes/beat/editor.tscn")


func _on_mods_pressed() -> void:
	button_sound.play()

	mod_menu.position.x = get_viewport_rect().size.x

	mod_dim.visible = true
	mod_menu.visible = true

	var tween = create_tween().set_parallel(true)
	tween.tween_property(mod_dim, "modulate:a", 1, .25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mod_menu, "position", Vector2(1074.0, mod_menu.position.y), .5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _on_auto_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["AP"] = toggled_on


func _on_double_time_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["DT"] = toggled_on

	if toggled_on:
		music.pitch_scale = 1.5
		video.speed_scale = 1.5
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())
	else:
		music.pitch_scale = 1
		video.speed_scale = 1
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())

	if mods["HT"]:
		ht_button.set_pressed_no_signal(false)
		mods["HT"] = false
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())

	refresh_detail_labels()


func _on_half_time_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["HT"] = toggled_on

	if toggled_on:
		music.pitch_scale = .75
		video.speed_scale = .75
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())
	else:
		music.pitch_scale = 1
		video.speed_scale = 1
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())

	if mods["DT"]:
		dt_button.set_pressed_no_signal(false)
		mods["DT"] = false
		if music.stream != null:
			duration_label.text = "" + format_time(music.stream.get_length())

	refresh_detail_labels()


func _on_no_fail_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["NF"] = toggled_on


func _on_easy_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["EZ"] = toggled_on

	if mods["HR"]:
		hr_button.set_pressed_no_signal(false)
		mods["HR"] = false

	refresh_detail_labels()

func _on_music_finished() -> void:
	music.play()

func _on_open_beatmap_folder_pressed() -> void:
	button_sound.play()
	OS.shell_open(OS.get_user_data_dir()+'/beatmaps')

func _on_close_mod_menu_pressed() -> void:
	button_sound.play()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(mod_dim, "modulate:a", 0, .75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mod_menu, "position", Vector2(get_viewport_rect().size.x, mod_menu.position.y), .5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished

	mod_dim.visible = false
	mod_menu.visible = false
	mod_menu.position.x = 1074.0


func _on_hidden_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["HD"] = toggled_on

func _on_caps_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["CS"] = toggled_on

func _on_hardrock_toggled(toggled_on: bool) -> void:
	button_sound.play()
	mods["HR"] = toggled_on

	if mods["EZ"]:
		ez_button.set_pressed_no_signal(false)
		mods["EZ"] = false

	refresh_detail_labels()


func _on_word_dropdown_pressed() -> void:
	button_sound.play()


func _on_word_dropdown_item_selected(index: int) -> void:
	button_sound.play()
