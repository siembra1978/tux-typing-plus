extends Node2D

const EDITOR_VERSION = "TuxEditor-0.2.11"

# init
var viewport_size
@onready var button_sound = get_node("ButtonPress")
@onready var error_sound = get_node("Error")
@onready var back_sound = get_node("Back")
@onready var kiai_sound = get_node("Kiai")

# init bottom ui
@onready var bottom_canvas_layer = get_node("Bottom")
@onready var bottom_control = bottom_canvas_layer.get_node("Control")
@onready var background_rect = bottom_control.get_node("Background")
@onready var custom_background = bottom_control.get_node("CustomBackground")
@onready var bg_video = bottom_control.get_node("VideoStreamPlayer")
@onready var background_dim = bottom_control.get_node("BGDim")

# init top ui
@onready var top_canvas_layer = get_node("Top")
@onready var top_control = top_canvas_layer.get_node("Control")

@onready var version_label = top_control.get_node("Version")

@onready var top_bar = top_control.get_node("TopBar")
@onready var menu_bar = top_bar.get_node("MenuBar")
@onready var file_button = menu_bar.get_node("File")
@onready var file_menu = file_button.get_node("FileMenu")
@onready var edit_button = menu_bar.get_node("Edit")
@onready var edit_menu = edit_button.get_node("EditMenu")
@onready var view_button = menu_bar.get_node("View")
@onready var view_menu = view_button.get_node("ViewMenu")
@onready var settings_button = menu_bar.get_node("Settings")
@onready var settings_menu = settings_button.get_node("SettingsMenu")
@onready var help_button = menu_bar.get_node("Help")
@onready var help_menu = help_button.get_node("HelpMenu")

@onready var map_info_popup = top_control.get_node("MapInfoPopUp")
@onready var map_difficulty_popup = top_control.get_node("DifficultyPopUp")
@onready var tempo_change_popup = top_control.get_node("TempoPopUp")
@onready var clear_warning_popup = top_control.get_node("ClearWarning")
@onready var osz_import_popup = top_control.get_node("OSZPopUp")
@onready var osz_diff_select = osz_import_popup.get_node("DiffStack").get_node("Interact").get_node("DiffSelect")
@onready var map_info_stack = map_info_popup.get_node("MapInfo")
@onready var name_entry = map_info_stack.get_node("Name")
@onready var artist_entry = map_info_stack.get_node("Artist")
@onready var mapper_entry = map_info_stack.get_node("Mapper")
@onready var difficulty_entry = map_info_stack.get_node("Difficulty")

# media controls
@onready var media_ui = top_control.get_node("Media")
@onready var media_controls = media_ui.get_node("MediaControls")
@onready var play_button = media_controls.get_node("Play")
@onready var playback = media_ui.get_node("Playback")
@onready var time_label = media_ui.get_node("TimeLabel")
@onready var scrubber = playback.get_node("Scrubber")
@onready var timeline_scroll = playback.get_node("TimelineScroll")
@onready var tick_count = scrubber.tick_count

# timeline markers
@onready var timeline_width = timeline_scroll.size.x
@onready var active_marker = timeline_scroll.get_node("ActiveMarker")
@onready var playhead_marker = timeline_scroll.get_node("PlayheadMarker")
@onready var tempo_marker = preload("res://scenes/objects/ui/tempo_marker.tscn")

var tempo_markers = []
var kiai_markers = []

# tempo ui
@onready var bpm_ui = top_control.get_node("BPM")
@onready var tap_bpm = bpm_ui.get_node("TapBPM")
@onready var tempo_controls = bpm_ui.get_node("TempoControls")

@onready var bpm_stack = tempo_controls.get_node("BPMStack")
@onready var offset_stack = tempo_controls.get_node("OffsetStack")
@onready var speed_stack = tempo_controls.get_node("SpeedStack")
@onready var divider_stack = tempo_controls.get_node("DividerStack")

@onready var bpm_entry = bpm_stack.get_node("BPM")
@onready var offset_entry = offset_stack.get_node("Offset")
@onready var speed_entry = speed_stack.get_node("Speed")
@onready var divider_entry = divider_stack.get_node("Divisor")
@onready var metronome_button = bpm_ui.get_node("MetronomeToggle")

#@onready var audio_label = other.get_node("Buttons/AudioLabel") #cosmos

#@onready var entry_box = beat_controls.get_node("Entry")
@onready var quit_panel = get_node('Top/Control/Quit') # cosmos

var pop_sound_temp = preload("res://scenes/objects/ui/pop.tscn")

var source_audio_path
var source_bg_path
var source_skin_path
var source_video_path

# music details
var music
var audio_file_name
var background_file_name
var tux_file_name
var playback_position
var duration
var playing

# media controls
var scrubbing = false
var metronome_active = false

# misc ui
var fade
@onready var audioload = get_node("FileMusic")
@onready var chartload = get_node("FileChart")
@onready var oszload = get_node("FileOSZ")
@onready var videoload = get_node("FileVideo")
@onready var imgload = get_node('FileImg')

# tempo stuff
var offset
var bpm = 0
var first_recorded_timestamp
var last_recorded_timestamp
var press_delta = 0
var bpm_deltas = []
var bpm_timeout = 1
var bpm_timeout_counter = 0
var bpm_timestamps = []
var last_integer_ms = 0
var next_beat = 0
var last_playback_position = 0

var divider = 4
var metro_count = 2
var preview_point = 0.0

# beatmap editing stuff
var active_beat = 0
var total_beats = 0
var mappings = []
var playing_index = 0

#info
var map_name
var map_artist
var map_mapper
var map_difficulty
var map_tux_skin = false
var map_background = false
var map_video = false
var imgloadaction: String = ""

#beatmap editing ui
var note_objects = []
var changed_indices = {}
var kiai_indices = []

#beatmap difficulty
var OD = 1.0
var AR = 1.0
var HP = 1.0

var new_bpm

var beatmarker_scene = preload("res://scenes/objects/game/beatmarker.tscn")

func format_time(s: float) -> String:
	var minutes = int(s / 60)
	var seconds = int(fmod(s, 60.0))
	var milliseconds = int(fmod(s * 1000, 1000))

	return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func set_time_label():
	time_label.text = str(format_time(scrubber.value)) + " | " + str(format_time(duration)) +"\nSelected Index: " + str(active_beat) + "\nPlayhead Index: " + str(playing_index)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("000000ff"))
	#Discord RPC
	var platform = OS.get_name()
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.details = "♫ Editing a Chart ♫"
			rpc.large_image = "icon"
			rpc.small_image = 'music'
			rpc.small_image_text = 'Proper Rhythm'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

			rpc.refresh()

	var temp_folder = DirAccess.make_dir_recursive_absolute("user://tmp/")

	# init
	viewport_size = get_viewport_rect().size
	version_label.text = str(Config.GAME_VERSION) + "\n" + str(EDITOR_VERSION)

	# top ui
	fade = self.get_node('Top/Fade')

	fade.visible = true
	fade.modulate.a = 1
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# music details
	music = $Music
	playback_position = 0.0
	#duration = music.stream.get_length()

	scrubber.min_value = 0
	scrubber.max_value = 0
	#scrubber.step = 1
	#scrubber.tick_count = int(duration)

	create_log('Ready!', true)
	get_tree().root.files_dropped.connect(_on_files_dropped)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bpm_timeout_counter += delta
	tick_count = scrubber.tick_count
	scrubber.min_value = 0
	if music.stream != null:
		scrubber.max_value = duration

	if bpm_timeout_counter >= bpm_timeout:
		if len(bpm_timestamps) == 0:
			create_bpm_timestamps()

	if music.playing:
		playback_position = music.get_playback_position() + AudioServer.get_time_since_last_mix()
		var integer_position_ms = playback_position*1000

		if bpm_timestamps:
			if next_beat < total_beats-1:
				if integer_position_ms > bpm_timestamps[next_beat]:
					#print(next_beat)
					if metronome_active:
						var last_changed_index = 0

						for j in changed_indices.keys():
							if j <= next_beat:
								last_changed_index = int(j)
						#print(next_beat-last_changed_index)
						if ((next_beat-last_changed_index) % (4*metro_count)) == 0:
							$Metronome.play()
						elif ((next_beat-last_changed_index) % (metro_count)) == 0:
							$Metronome2.play()

					if next_beat in kiai_indices:
						kiai_sound.play()

					next_beat += 1
			if mappings:
				if integer_position_ms > bpm_timestamps[playing_index]:
					if playing_index < total_beats-1:
						if mappings[playing_index] == 1:
							$Hitsound.play()
						if playing_index < len(note_objects):
							if (playing_index-1) == active_beat:
								note_objects[playing_index-1].get_node("ColorRect").color = Color(1,0,0)
							elif mappings[playing_index-1] == 1:
								note_objects[playing_index-1].get_node("ColorRect").color = Color(0,0,1)
							else:
								note_objects[playing_index-1].get_node("ColorRect").color = Color(1,1,1)
							note_objects[playing_index].get_node("ColorRect").color = Color(1,1,0)
						playing_index += 1

		set_time_label()
	elif not music.playing and not scrubbing:
		var integer_position_ms = playback_position*1000
		if music.stream:
			set_time_label()

	if scrubbing and not music.playing:
		var prev_playback_pos = playback_position
		playback_position = scrubber.value
		var integer_position_ms = playback_position*1000

		if mappings and bpm_timestamps:
			if playback_position > prev_playback_pos:
				for i in bpm_timestamps.size():
					if bpm_timestamps[i] > integer_position_ms:
						playing_index = i
						if playing_index < len(note_objects):
							if mappings[playing_index-2] == 1:
								note_objects[playing_index-2].get_node("ColorRect").color = Color(0,0,1)
							else:
								note_objects[playing_index-2].get_node("ColorRect").color = Color(1,1,1)
							note_objects[playing_index-1].get_node("ColorRect").color = Color(1,1,0)
						break
			elif prev_playback_pos > playback_position:
				var k = -1
				if mappings[playing_index+k] == 1:
					note_objects[playing_index+k].get_node("ColorRect").color = Color(0,0,1)
				else:
					note_objects[playing_index+k].get_node("ColorRect").color = Color(1,1,1)
				#note_objects[playing_index-2].get_node("ColorRect").color = Color(1,1,0)

			set_time_label()

	if not scrubbing:
		scrubber.value = playback_position

	if bpm_timestamps:
		active_marker.position.x = ((float(bpm_timestamps[active_beat])/1000.0)/float(duration))*timeline_width

	if playback_position and duration:
		playhead_marker.position.x = float(playback_position/duration)*timeline_width

	if duration:
		bpm_entry.editable = true
		speed_entry.editable = true
	if bpm_entry.text:
		offset_entry.editable = true
		divider_entry.editable = true


func _on_begin_pressed() -> void:
	if music.stream != null:
		playback_position = 0.0
		var integer_position_ms = playback_position*1000

		for i in bpm_timestamps.size():
			if bpm_timestamps[i] > integer_position_ms:
				next_beat = i
				playing_index = i
				break

		if playing:
			music.play(0.0)
			if bg_video.stream:
				bg_video.paused = false
				bg_video.play()
				bg_video.stream_position = playback_position
		else:
			scrubber.value = 0
			time_label.text = "0 / " + str(int(duration*1000))
	else:
		error_sound.play()


func _on_play_pressed() -> void:
	if playing:
		playing = false
		play_button.icon = load('res://assets/visual/sprites/play.png')
		playback_position = music.get_playback_position() + AudioServer.get_time_since_last_mix()
		if bg_video.stream:
			bg_video.paused = true
		music.stop()
	else:
		if music.stream != null:
			playing = true
			play_button.icon = load('res://assets/visual/sprites/pause.png')
			music.play(playback_position)
			if bg_video.stream:
				bg_video.paused = false
				bg_video.stream_position = playback_position
		else:
			error_sound.play()


func _on_end_pressed() -> void:
	pass # Replace with function body.

func _on_scrubber_drag_started() -> void:
	if music.stream != null:
		scrubbing = true

		kiai_sound.stop()

		if mappings and bpm_timestamps:
			if mappings[playing_index-1] == 1:
				note_objects[playing_index-1].get_node("ColorRect").color = Color(0,0,1)
			else:
				note_objects[playing_index-1].get_node("ColorRect").color = Color(1,1,1)
		if bg_video.stream:
			bg_video.paused = true
		music.stop()

func _on_scrubber_drag_ended(value_changed: bool) -> void:
	scrubbing = false
	playback_position = scrubber.value
	var integer_position_ms = playback_position*1000

	kiai_sound.stop()

	if mappings and bpm_timestamps:
		for i in bpm_timestamps.size():
			if bpm_timestamps[i] > integer_position_ms:
				playing_index = i
				#print("next play index: " + str(playing_index))
				break

		for i in bpm_timestamps.size():
			if (i % divider == 0):
				if bpm_timestamps[i] > integer_position_ms:
					next_beat = i
					#print("new next beat: " + str(next_beat))
					break

	if playing:
		if bg_video.stream:
			bg_video.paused = false
			bg_video.stream_position = playback_position
		music.play(playback_position)

func _input(event):
	if (not map_info_popup.visible) and (not map_difficulty_popup.visible):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_R:
				scrubber.size.x = viewport_size.x
				scrubber.position.x = (viewport_size.x/2) - (scrubber.size.x)*(timeline_scroll.value/100)
			if event.keycode == KEY_LEFT:
				if active_beat > 0:
					var old_marker = note_objects[active_beat]

					if mappings[active_beat] == 1:
						old_marker.get_node("ColorRect").color = Color(0,0,1)
					elif mappings[active_beat] == 0:
						old_marker.get_node("ColorRect").color = Color(1,1,1)

					active_beat -= 1
					var new_marker = note_objects[active_beat]

					new_marker.get_node("ColorRect").color = Color(1,0,0)

			if event.keycode == KEY_RIGHT:

				if active_beat < total_beats:
					var old_marker = note_objects[active_beat]

					if mappings[active_beat] == 1:
						old_marker.get_node("ColorRect").color = Color(0,0,1)
					elif mappings[active_beat] == 0:
						old_marker.get_node("ColorRect").color = Color(1,1,1)

					active_beat += 1
					var new_marker = note_objects[active_beat]

					new_marker.get_node("ColorRect").color = Color(1,0,0)

			if event.keycode == KEY_C or event.keycode == KEY_V:
				#$Hitsound.play()
				var ms = playback_position*1000

				var best_j = 0
				var best_diff = INF
				for j in bpm_timestamps.size():
					var diff = abs(float(bpm_timestamps[j]) - ms)
					if diff < best_diff:
						best_diff = diff
						best_j = j
					elif diff > best_diff:
						break

				mappings[best_j] = 1
				note_objects[best_j].get_node("ColorRect").color = Color(0,0,1)

				'''
				for i in bpm_timestamps.size():
					if bpm_timestamps[i] > integer_position_ms:
						mappings[i] = 1
						if i != active_beat:
							note_objects[i].get_node("ColorRect").color = Color(0,0,1)
						#print("beat places at index " + str(i))
						break
				'''

				#creating_mapping_visualizer()
			if event.keycode == KEY_Z:
				mappings[active_beat] = 1
				#note_objects[active_beat].get_node("ColorRect").color = Color(0,0,1)
			if event.keycode == KEY_X:
				mappings[active_beat] = 0
				#note_objects[active_beat].get_node("ColorRect").color = Color(1,1,1)

			if event.keycode == KEY_L:
				tap_bpm_input()

			if event.keycode == KEY_DOWN:
				if mappings[active_beat] == 1:
					note_objects[active_beat].get_node("ColorRect").color = Color(0,0,1)
				else:
					note_objects[active_beat].get_node("ColorRect").color = Color(1,1,1)

				active_beat = playing_index
				note_objects[active_beat].get_node("ColorRect").color = Color(1,0,0)

			if event.keycode == KEY_ESCAPE:
				if not quit_panel.visible:
					button_sound.play()
					quit_panel.scale = Vector2(0.0,0.0)
					quit_panel.visible = true
					var tween = create_tween()
					tween.tween_property(quit_panel, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				else:
					back_sound.play()
					var tween = create_tween()
					tween.tween_property(quit_panel, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
					await tween.finished
					quit_panel.visible = false
					quit_panel.scale = Vector2(1.0,1.0)

			if event.keycode == KEY_I:
				zoom_in()

			if event.keycode == KEY_O:
				zoom_out()


		if event is InputEventMouseButton and event.pressed:

			var scrolling = Input.is_key_pressed(KEY_CTRL)
			var d = 10000

			if (event.button_index == MOUSE_BUTTON_WHEEL_UP and scrolling):
				scrubber.size.x += d
				#scrubber.position.x -= d / 2.0
				scrubber.position.x = (viewport_size.x/2) - (scrubber.size.x)*(timeline_scroll.value/100)
				creating_mapping_visualizer()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and scrolling:
				if scrubber.size.x > d:
					scrubber.size.x -= d
					scrubber.position.x = (viewport_size.x/2) - (scrubber.size.x)*(timeline_scroll.value/100)
					creating_mapping_visualizer()

func zoom_in():
	var d = 10000
	scrubber.size.x += d
	#scrubber.position.x -= d / 2.0
	scrubber.position.x = (viewport_size.x/2) - (scrubber.size.x)*(timeline_scroll.value/100)
	creating_mapping_visualizer()

func zoom_out():
	var d = 10000
	scrubber.size.x -= d
	#scrubber.position.x -= d / 2.0
	scrubber.position.x = (viewport_size.x/2) - (scrubber.size.x)*(timeline_scroll.value/100)
	creating_mapping_visualizer()

func _on_timeline_scroll_scrolling() -> void:
	var current_size = scrubber.size.x
	scrubber.position.x = (viewport_size.x/2) - (current_size)*(timeline_scroll.value/100)


func _on_music_finished() -> void:
	playing = false
	music.stop()

func creating_mapping_visualizer():
	note_objects.clear()
	for child in scrubber.get_children():
		child.queue_free()

	if mappings:
		var scrubber_width = scrubber.size.x
		var total_duration_ms = duration * 1000.0

		var full_beat_ms = (60.0 / bpm) * 1000.0
		var marker_width_ms = full_beat_ms / divider

		for i in mappings.size():
			var beat_time_ms = bpm_timestamps[i]
			var pos_percentage = beat_time_ms / total_duration_ms
			var final_x_pos = pos_percentage * scrubber_width

			var new_marker = beatmarker_scene.instantiate()

			if active_beat == i:
				new_marker.get_node("ColorRect").color = Color(1,0,0)
			elif mappings[i] == 1:
				new_marker.text = "1"
				new_marker.get_node("ColorRect").color = Color(0,0,1)

			if i in changed_indices.keys():
				var indicator = new_marker.get_node("BPMIndicator")
				indicator.visible = true
				indicator.text = "BPM: " + str(changed_indices[i])
				full_beat_ms = (60.0 / changed_indices[i]) * 1000.0
				marker_width_ms = full_beat_ms / divider

			var last_changed_index = 0

			for j in changed_indices.keys():
				if j <= i:
					last_changed_index = int(j)

			if ((i-last_changed_index) % (4*metro_count)) == 0:
				new_marker.text = str((i % divider)+1)
				new_marker.position.y = new_marker.position.y - (new_marker.size.y*.50)/2
				new_marker.size.y = new_marker.size.y*1.50
			elif ((i-last_changed_index) % (metro_count)) == 0:
				new_marker.text = str((i % divider)+1)
				new_marker.position.y = new_marker.position.y - (new_marker.size.y*.125)/2
				new_marker.size.y = new_marker.size.y*1.125
			else:
				new_marker.text = str((i % divider)+1)

			if i in kiai_indices:
				new_marker.text = "*"

			new_marker.position.x = (bpm_timestamps[i] / total_duration_ms) * scrubber_width

			new_marker.size.x = (marker_width_ms / total_duration_ms) * scrubber_width

			note_objects.append(new_marker)
			scrubber.add_child(new_marker)

func create_bpm_timestamps():
	if offset != null:
		print(offset)
		bpm_timestamps.clear()
		var a = offset*1000
		print(bpm)
		var change_by = ((60/bpm)*1000)/divider
		#print(change_by)

		#while (a + change_by) < duration*1000:
			#pass
			#print("h")
			#bpm_timestamps.append(a)
			#a += change_by

		var h = ((duration*1000)-a)/change_by
		print(h)
		for i in range(int((duration*1000 - a)/change_by)):
			bpm_timestamps.append(a + change_by * i)

		total_beats = len(bpm_timestamps) - 1

		mappings.clear()
		for i in range(total_beats):
			mappings.append(0)

		bpm_deltas.clear()
		last_recorded_timestamp = null
		#print(bpm_timestamps)
		creating_mapping_visualizer()

func create_bpm_timestamps_from_osz():
	print("generating timestamps from osz")
	if offset != null:
		#print(offset)
		bpm_timestamps.clear()
		var a = offset*1000
		#print(bpm)
		var change_by = ((60/bpm)*1000)/divider
		#print(change_by)

		#while (a + change_by) < duration*1000:
			#pass
			#print("h")
			#bpm_timestamps.append(a)
			#a += change_by

		var h = ((duration*1000)-a)/change_by
		#print(h)
		for i in range(int((duration*1000 - a)/change_by)):
			bpm_timestamps.append(a + change_by * i)

		total_beats = len(bpm_timestamps) - 1

		mappings.clear()
		for i in range(total_beats):
			mappings.append(0)

		bpm_deltas.clear()
		last_recorded_timestamp = null
		#print(bpm_timestamps)
		#creating_mapping_visualizer()

func create_partial_bpm_timestamps():
	#print("generating partial timestamps from osz")
	if bpm_timestamps and new_bpm:
		#print("attempting 3")
		#bpm_timestamps.clear()

		bpm_timestamps = bpm_timestamps.slice(0,active_beat+1)

		var new_marker = tempo_marker.instantiate()
		timeline_scroll.add_child(new_marker)
		new_marker.position.x = ((bpm_timestamps[int(active_beat)]/1000)/duration)*timeline_width


		var a = bpm_timestamps[active_beat]
		changed_indices[active_beat] = new_bpm
		#print(new_bpm)
		var change_by = ((60/new_bpm)*1000)/divider
		#print(change_by)

		var h = ((duration*1000)-a)/change_by
		#print(h)
		for i in range(int((duration*1000 - a)/change_by)):
			bpm_timestamps.append(a + change_by * i)

		total_beats = len(bpm_timestamps) - 1

		mappings.clear()
		for i in range(total_beats):
			mappings.append(0)

		bpm_deltas.clear()
		last_recorded_timestamp = null
		#print(bpm_timestamps)
		creating_mapping_visualizer()

func create_partial_bpm_timestamps_from_osz(requested_timing, imported_bpm):
	print("generating partial timestamps from osz")
	if bpm_timestamps and imported_bpm:

		var best_j = 0
		var best_diff = INF
		for j in bpm_timestamps.size():
			var diff = abs(float(bpm_timestamps[j]) - requested_timing)
			if diff < best_diff:
				best_diff = diff
				best_j = j
			elif diff > best_diff:
				break

		#best_j+=1

		bpm_timestamps = bpm_timestamps.slice(0,best_j+1)

		var new_marker = tempo_marker.instantiate()
		timeline_scroll.add_child(new_marker)
		new_marker.position.x = ((bpm_timestamps[int(best_j)]/1000)/duration)*timeline_width

		#var a = offset*1000
		var a = bpm_timestamps[best_j]
		changed_indices[best_j] = imported_bpm
		#print(imported_bpm)
		var change_by = ((60/imported_bpm)*1000)/divider
		#print(change_by)

		var h = ((duration*1000)-a)/change_by
		#print(h)
		for i in range(int((duration*1000 - a)/change_by)):
			if i > 0:
				bpm_timestamps.append(a + change_by * i)

		total_beats = len(bpm_timestamps) - 1

		mappings.clear()
		for i in range(total_beats):
			mappings.append(0)

		bpm_deltas.clear()
		last_recorded_timestamp = null
		#print(bpm_timestamps)
		#creating_mapping_visualizer()

func shift_offset():
		var dif = bpm_timestamps[0] - (offset*1000)
		var new_timestamps = []
		print(str(bpm_timestamps[0]) + " and " + str(dif))
		print("before: " + str(bpm_timestamps[0]))
		for beat in bpm_timestamps:
			beat = beat - dif
			new_timestamps.append(beat)
		bpm_timestamps = new_timestamps
		print("after: " + str(bpm_timestamps[0]))
		creating_mapping_visualizer()

func calculate_offset():
	if len(bpm_deltas) > 0:
		if first_recorded_timestamp:
			var o = first_recorded_timestamp
			var change_by = 60/bpm

			while (o - change_by) > 0:
				#print(o*1000)
				o -= change_by

			offset = o
			offset_entry.text = str(int(offset*1000))

func save_beatmap():
	var map_data = {
		"name": map_name,
		"artist": map_artist,
		"mapper": map_mapper,
		"difficulty": map_difficulty,
		"song_name": audio_file_name,
		"background": map_background,
		#"background": background_file_name,
		"tux_skin": map_tux_skin,
		#"tux_skin": tux_file_name,
		"video": map_video,
		"HP": HP,
		"OD": OD,
		"AR": AR,
		"game_version": Config.GAME_VERSION,
		"editor_version": EDITOR_VERSION,
		"bpm": bpm,
		"offset": offset,
		"divider": divider,
		"preview_point": preview_point,
		"kiai_indices": kiai_indices,
		"changed_indices": changed_indices,
		"bpm_timestamps": bpm_timestamps,
		"mappings": mappings
	}

	var regex = RegEx.new()
	regex.compile("[^a-zA-Z]")

	var file_name = regex.sub(map_name + map_difficulty, "", true).to_lower()
	var beatmap_path = "user://beatmaps/" + file_name + "/"
	var error = DirAccess.make_dir_recursive_absolute(beatmap_path)

	if error != OK:
		print("Error creating directory: ", error)
		return

	var file = FileAccess.open(beatmap_path + file_name + ".json", FileAccess.WRITE)

	if file:
		var json_string = JSON.stringify(map_data, "\t", false)
		file.store_string(json_string)
		file.close()
		create_log("Saved beatmap to: "+ ProjectSettings.globalize_path(beatmap_path), true)
	else:
		create_log("Error: Could not save file!", false)
		error_sound.play()
		return

	if source_audio_path:
		var audio_dest = beatmap_path + source_audio_path.get_file()
		DirAccess.copy_absolute(source_audio_path, audio_dest)

	if source_bg_path:
		var bg_dest = beatmap_path + source_bg_path.get_file()
		DirAccess.copy_absolute(source_bg_path, bg_dest)

	if source_skin_path:
		var skin_dest = beatmap_path + source_skin_path.get_file()
		DirAccess.copy_absolute(source_skin_path, skin_dest)

	if source_video_path:
		var video_dest = beatmap_path + "video" + "." + source_video_path.get_extension()
		DirAccess.copy_absolute(source_video_path, video_dest)

	button_sound.play()

func tap_bpm_input():
	if playing:
		#print("bpm tapped")
		bpm_timestamps.clear()
		bpm_timeout_counter = 0

		if last_recorded_timestamp == null:
			last_recorded_timestamp = music.get_playback_position() + AudioServer.get_time_since_last_mix()
			first_recorded_timestamp = last_recorded_timestamp
		else:
			var current_timestamp = (music.get_playback_position() + AudioServer.get_time_since_last_mix())
			press_delta = current_timestamp - last_recorded_timestamp
			bpm_deltas.append(press_delta)
			last_recorded_timestamp = current_timestamp

		if len(bpm_deltas) > 0:
			bpm = ceil(60/(bpm_deltas.reduce(func(accum, bpm_delta): return accum + bpm_delta, 0)/len(bpm_deltas)))

		bpm_entry.text = str(bpm)
		calculate_offset()

func _on_tap_bpm_pressed() -> void:
	tap_bpm_input()

func _on_metronome_toggle_pressed() -> void:
	if metronome_active:
		metronome_active = false
		metronome_button.text = "Metronome: OFF"
	else:
		metronome_active = true
		metronome_button.text = "Metronome: ON"

func _on_increase_bpm_pressed() -> void:
	if duration and bpm < 1000:
		bpm += 1
		bpm_entry.text = str(bpm)
		create_bpm_timestamps()
		if not offset:
			offset = float(0)/1000

func _on_decrease_bpm_pressed() -> void:
	if duration and bpm > 1:
		bpm -= 1
		bpm_entry.text = str(bpm)
		create_bpm_timestamps()
		if not offset:
			offset = float(0)/1000

func _on_increase_offset_pressed() -> void:
	if bpm_entry.text:
		if not offset:
			offset = float(0)/1000
		offset = ((offset*1000)+1)/1000
		if not mappings:
			create_bpm_timestamps()
		else:
			shift_offset()
		offset_entry.text = str(int(offset*1000))

func _on_decrease_offset_pressed() -> void:
	if bpm_entry.text:
		if not offset:
			offset = float(0)/1000
		offset = ((offset*1000)-1)/1000
		if not mappings:
			create_bpm_timestamps()
		else:
			shift_offset()
		offset_entry.text = str(int(offset*1000))

func _on_faster_pressed() -> void:
	if duration:
		music.pitch_scale += .25
		bg_video.speed_scale += .25
		speed_entry.text = str(music.pitch_scale*100) + "%"

func _on_slower_pressed() -> void:
	if duration:
		music.pitch_scale -= .25
		bg_video.speed_scale -= .25
		speed_entry.text = str(music.pitch_scale*100) + "%"

func _on_file_music_file_selected(path: String) -> void:
	play_button.icon = load('res://assets/visual/sprites/play.png')
	var chosenmusic = FileAccess.open(path, FileAccess.READ)
	var stream
	var validformat = true

	source_audio_path = str(path)
	audio_file_name = str(path.get_file())

	if path.ends_with('.mp3'):
		stream = AudioStreamMP3.new()
		stream.data = chosenmusic.get_buffer(chosenmusic.get_length())
	elif path.ends_with('.wav'):
		stream = AudioStreamWAV.new()
	elif path.ends_with('.ogg'):
		stream = AudioStreamOggVorbis.load_from_file(path)
	else:
		create_log('Error: Could not read file! (Wrong Format)', false)
		validformat = false
	if validformat:
		create_log('Load Audio: '+ audio_file_name, true)
		chosenmusic.close()
		music.stream = stream
		playback_position = 0.0
		duration = music.stream.get_length()
		#audio_label.set_text(audiofilename)
		time_label.text = str(0) + "/" + str(int(duration*1000))
		#entry_box.get_node("BeatmapName").set_text(name_entry.text)

#Load Beatmap
func _on_file_chart_file_selected(path: String) -> void:
	#create_bpm_timestamps()
	print(path)
	play_button.icon = load('res://assets/visual/sprites/play.png')
	var file = FileAccess.open(path, FileAccess.READ)
	var chartfd_path = path.get_base_dir()
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error == OK:
		var data = json.data

		map_name = data["name"]
		map_artist = data["artist"]
		map_mapper = data["mapper"]
		map_difficulty = data["difficulty"]
		audio_file_name = data["song_name"]
		bpm = data["bpm"]
		offset = data["offset"]
		divider = int(data["divider"])
		metro_count = int(data["divider"])
		mappings = data["mappings"]
		bpm_timestamps = data["bpm_timestamps"]

		total_beats = len(bpm_timestamps) - 1

		# difficulty
		HP = data["HP"]
		AR = data["AR"]
		OD = data["OD"]

		#print("user://beatmaps/" + file_name + "/" + str(data["song_name"]))
		var music_path = chartfd_path + "/" + str(data["song_name"])


		if data["song_name"].ends_with(".mp3"):
			if FileAccess.file_exists(music_path):
				#print("Loading MP3")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamMP3.new()
				stream.data = buffer
				music.stream = stream
				#music.play()
				duration = music.stream.get_length()
				time_label.text = str(0) + "/" + str(int(duration*1000))
		elif data["song_name"].ends_with(".ogg"):
			if FileAccess.file_exists(music_path):
				#print("Loading OGG")
				var music_file = FileAccess.open(music_path, FileAccess.READ)
				var buffer = music_file.get_buffer(music_file.get_length())

				var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
				music.stream = stream
				#music.play()
				duration = music.stream.get_length()
				playback_position = 0.0
				time_label.text = str(0) + "/" + str(int(duration*1000))
		source_audio_path = music_path

		#create_bpm_timestamps()
		#bpm_timestamps = data["bpm_timestamps"]
		#mappings = data["mappings"]

		bpm_entry.text = str(bpm)
		offset_entry.text = str(int(offset*1000))
		divider_entry.text = str(divider)
		name_entry.text = str(map_name)
		artist_entry.text = str(map_artist)
		mapper_entry.text = str(map_mapper)
		difficulty_entry.text = str(map_difficulty)
		$Top/Control/DifficultyPopUp/MapInfo/OD/ODSpin.value = float(OD)
		$Top/Control/DifficultyPopUp/MapInfo/AR/ARSpin.value = float(AR)
		$Top/Control/DifficultyPopUp/MapInfo/HP/HPSpin.value = float(HP)

		#if data["editor_version"] != "TuxEditor-0.2.11":
			#data["background"] = "background.jpg"
			#data["tux_skin"] = "tux.jpg"

		if data["background"] != null:
			#print("user://beatmaps/" + file_name + "/background.jpg")
			map_background = data["background"]
			source_bg_path = chartfd_path + "/" + data["background"]
			custom_background.texture = ImageTexture.create_from_image(Image.load_from_file(source_bg_path))
			background_rect.texture = null
			custom_background.visible = true
			map_background = data["background"]

		if data["tux_skin"]:
			source_skin_path = chartfd_path + "/" + data["tux_skin"]
			map_tux_skin = data["tux_skin"]

		if "video" in data:
			#print("there is video!")
			if data["video"]:
				#print("loading video!")
				#print(chartfd_path)
				bg_video.visible = true
				bg_video.stream = load(chartfd_path + "/video.ogv")
				bg_video.play()
				bg_video.paused = true
				custom_background.visible = false
			else:
				bg_video.visible = false

		if "preview_point" in data:
			if data["preview_point"]:
				preview_point = data["preview_point"]

		if "kiai_indices" in data:
			if data["kiai_indices"]:
				kiai_indices.clear()
				var temp_indices = data["kiai_indices"]
				for index in temp_indices:
					kiai_indices.append(int(index))
					var new_marker = tempo_marker.instantiate()
					kiai_markers.append(new_marker)
					new_marker.color = Color(0,1,1)
					timeline_scroll.add_child(new_marker)
					new_marker.position.x = ((bpm_timestamps[int(index)]/1000)/duration)*timeline_width

		if "changed_indices" in data:
			if data["changed_indices"]:
				#print(data["changed_indices"])
				changed_indices.clear()
				var temp_indices = data["changed_indices"]
				for key in temp_indices.keys():
					changed_indices[int(key)] = float(temp_indices[key])
					var new_marker = tempo_marker.instantiate()
					timeline_scroll.add_child(new_marker)
					new_marker.position.x = ((bpm_timestamps[int(key)]/1000)/duration)*timeline_width

		if "video" in data:
			if data["video"]:
				source_video_path = chartfd_path + "/video.ogv"
				map_video = data["video"]

		creating_mapping_visualizer()
		create_log('Load Chart: '+ path, true)
		print(bpm_timestamps.size())
		print(mappings.size())
	else:
		pass
		#print("JSON Parse Error: ", json.get_error_message())

func _on_test_pressed() -> void:
	error_sound.play()

func _on_quit_n_button_pressed() -> void:
	back_sound.play()
	var tween = create_tween()
	tween.tween_property(quit_panel, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	quit_panel.visible = false
	quit_panel.scale = Vector2(1.0,1.0)

func _on_quit_y_button_pressed() -> void:
	var temp_files = DirAccess.get_files_at("user://tmp/")

	for file in temp_files:
		DirAccess.remove_absolute("user://tmp/" + file)

	fade.visible = true
	#scrubber.visible = false
	fade.modulate.a = 0.0
	button_sound.play()
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	Config.load_scene('res://scenes/beat/rhythmgame.tscn')

func create_log(text: String, check: bool):
	print(text)
	var label = self.get_node('Top/Control/Log/LogLabel')
	var log = self.get_node('Top/Control/Log')
	var panel = self.get_node('Top/Control/Log/LogLabel/Panel')
	log.modulate.a = 1.0
	log.visible = true
	label.set_text(text)
	var style := StyleBoxFlat.new()
	if check:
		style.bg_color = Color(0.0, 0.467, 0.373)
		style.set_border_width_all(2)
		style.border_color = Color(0.0, 0.345, 0.271)
	else:
		style.bg_color = Color(0.737, 0.067, 0.173)
		style.set_border_width_all(2)
		style.border_color = Color(0.561, 0.0, 0.043)

	panel.add_theme_stylebox_override("panel", style)
	await get_tree().create_timer(clamp(text.length()/10, 2, 4)).timeout
	var tween := create_tween()
	tween.parallel().tween_property(log, "modulate:a", 0, 1)
	await tween.finished
	self.get_node('Top/Control/Log').visible = false


func _on_bpm_text_submitted(new_text: String) -> void:
	if float(new_text) > 1000:
		new_text = '1000'
	if float(new_text) < 0:
		new_text = '0'
	bpm = float(new_text)
	bpm_entry.text = str(bpm)
	create_bpm_timestamps()
	if not offset:
		offset = float(0)/1000

func _on_offset_text_submitted(new_text: String) -> void:
	offset = (float(new_text)/1000)
	if not mappings:
		create_bpm_timestamps()
	else:
		shift_offset()
	offset_entry.text = str(int(offset*1000))

func _on_file_img_file_selected(path: String) -> void:
	var image = FileAccess.open(path, FileAccess.READ)
	var imagename = path.get_file()
	var validformat = true

	if path.ends_with('.png'):
		pass
	elif path.ends_with('.jpg'):
		pass
	else:
		validformat = false
		create_log('Error: Could not read file! (Wrong Format)', false)

	if validformat == true:
		create_log('Load Image: '+imagename, true)
		match imgloadaction:
			"skin":
				source_skin_path = path
				map_tux_skin = imagename
			"bg":
				source_bg_path = path
				map_background = imagename
				custom_background.texture = ImageTexture.create_from_image(Image.load_from_file(path))
				background_rect.texture = null
				custom_background.visible = true
		image.close()

func open_menu(menu):
	if not menu.visible:
		for button in menu.get_children():
			button.active = false
			#button.visible = true
			button.modulate.a = 0
			button.scale = Vector2(0.0,0.0)

		menu.visible = true
		await get_tree().create_timer(.125).timeout

		var last_tween
		var buttons = menu.get_children()
		for button in buttons:
			button.scale = Vector2(0.0,0.0)
			button.modulate.a = 1
			last_tween = create_tween()
			#button.scale = Vector2(0.0,0.0)
			last_tween.tween_property(button, "scale", Vector2(1, 1), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await get_tree().create_timer(.04).timeout
			button.active = true
	else:
		var last_tween
		var buttons = menu.get_children()
		buttons.reverse()
		for button in buttons:
			button.scale = Vector2(1.0,1.0)
			last_tween = create_tween()
			last_tween.tween_property(button, "scale", Vector2(0, 0.0), .25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			await get_tree().create_timer(.04).timeout
			#button.modulate.a = 0
			button.active = false
		await last_tween.finished
		menu.visible = false

# MENU BAR BEGIN
func _on_file_pressed() -> void:
	button_sound.play()
	open_menu(file_menu)

func _on_edit_pressed() -> void:
	button_sound.play()
	open_menu(edit_menu)

func _on_view_pressed() -> void:
	button_sound.play()
	open_menu(view_menu)

func _on_settings_pressed() -> void:
	button_sound.play()
	open_menu(settings_menu)

func _on_help_pressed() -> void:
	button_sound.play()
	OS.shell_open("https://www.siembra.lol/games/tuxtypingplus/help")
	#help_menu.visible = not help_menu.visible
# MENU BAR END

# FILE MENU BEGIN
func _on_new_pressed() -> void:
	var temp_files = DirAccess.get_files_at("user://tmp/")

	for file in temp_files:
		DirAccess.remove_absolute("user://tmp/" + file)

	fade.visible = true
	#scrubber.visible = false
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await button_sound.finished
	get_tree().reload_current_scene()

func _on_open_pressed() -> void:
	error_sound.play()

func _on_load_audio_pressed() -> void:
	button_sound.play()
	audioload.popup_centered()


func _on_load_tux_pressed() -> void:
	button_sound.play()
	imgloadaction = "skin"
	imgload.popup()


func _on_load_bg_pressed() -> void:
	button_sound.play()
	imgloadaction = "bg"
	imgload.popup()

func _on_load_chart_pressed() -> void:
	button_sound.play()
	chartload.current_dir = OS.get_user_data_dir() + "/beatmaps"
	chartload.popup()

func _on_load_video_pressed() -> void:
	button_sound.play()
	videoload.popup()

func _on_save_pressed() -> void:
	button_sound.play()
	if not map_info_popup.visible:
		map_info_popup.scale = Vector2(0.0,0.0)
		map_info_popup.visible = true
		var tween = create_tween()
		tween.tween_property(map_info_popup, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(map_info_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tween.finished
		map_info_popup.visible = false
		map_info_popup.scale = Vector2(1.0,1.0)


func _on_quit_pressed() -> void:
	button_sound.play()
	if not quit_panel.visible:
		quit_panel.scale = Vector2(0.0,0.0)
		quit_panel.visible = true
		var tween = create_tween()
		tween.tween_property(quit_panel, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(quit_panel, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tween.finished
		quit_panel.visible = false
		quit_panel.scale = Vector2(1.0,1.0)
# FILE MENU END

# EDIT MENU BEGIN
func _on_undo_pressed() -> void:
	error_sound.play()

func _on_redo_pressed() -> void:
	error_sound.play()
# EDIT MENU END

# SAVE MENU BEGIN
func _on_name_text_changed(new_text: String) -> void:
	map_name = new_text

func _on_artist_text_changed(new_text: String) -> void:
	map_artist = new_text

func _on_mapper_text_changed(new_text: String) -> void:
	map_mapper = new_text

func _on_difficulty_text_changed(new_text: String) -> void:
	map_difficulty = new_text

func _on_save_map_pressed() -> void:
	save_beatmap()

func _on_cancel_pressed() -> void:
	back_sound.play()
	var tween = create_tween()
	tween.tween_property(map_info_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	map_info_popup.visible = false
	map_info_popup.scale = Vector2(1.0,1.0)
# SAVE MENU END

func _on_speed_text_submitted(new_text: String) -> void:
	if float(new_text) > 1000:
		new_text = '1000'
	if float(new_text) < 0:
		new_text = '0'
	if new_text.is_valid_float():
		print("changing speed")
		var new_speed = float(new_text)
		print(new_speed)
		music.pitch_scale = float((new_speed/100))
		speed_entry.text = str(music.pitch_scale*100) + "%"


func _on_divisor_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		divider = int(new_text)
		metro_count = int(new_text)
		divider_entry.text = "1/" + str(divider)
		create_bpm_timestamps()


func _on_increase_divider_pressed() -> void:\
	if bpm_entry.text:
		divider += 1
		metro_count += 1
		divider_entry.text = "1/" + str(divider)
		create_bpm_timestamps()

func _on_decrease_divider_pressed() -> void:
	if bpm_entry.text:
		divider -= 1
		metro_count -= 1
		divider_entry.text = "1/" + str(divider)
		create_bpm_timestamps()

# VIEW MENU BEGIN
func _on_zoom_in_pressed() -> void:
	button_sound.play()
	zoom_in()


func _on_zoom_out_pressed() -> void:
	button_sound.play()
	zoom_out()


func _on_toggle_time_panel_toggled(toggled_on: bool) -> void:
	button_sound.play()
	if toggled_on:
		var tween = create_tween()
		tween.tween_property(time_label, "position", Vector2(0, 630), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(time_label, "position", Vector2(-time_label.size.x*1.15, 630), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	#time_label.visible = toggled_on


func _on_toggle_tempo_panel_toggled(toggled_on: bool) -> void:
	button_sound.play()
	if toggled_on:
		var tween = create_tween()
		tween.tween_property(bpm_ui, "position", Vector2(get_viewport_rect().size.x - bpm_ui.size.x, 65), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(bpm_ui, "position", Vector2(get_viewport_rect().size.x + bpm_ui.size.x*1.15, 65), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	#bpm_ui.visible = toggled_on
# VIEW MENU END

# SETTINGS MENU BEGIN
func _on_difficulty_pressed() -> void:
	button_sound.play()
	if not map_difficulty_popup.visible:
		map_difficulty_popup.scale = Vector2(0.0,0.0)
		map_difficulty_popup.visible = true
		var tween = create_tween()
		tween.tween_property(map_difficulty_popup, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(map_difficulty_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tween.finished
		map_difficulty_popup.visible = false
		map_difficulty_popup.scale = Vector2(1.0,1.0)

# SETTINGS MENU END

# DIFFICULTY SETTINGS POP UP BEGIN
func _on_od_spin_value_changed(value: float) -> void:
	OD = value


func _on_ar_spin_value_changed(value: float) -> void:
	AR = value


func _on_hp_spin_value_changed(value: float) -> void:
	HP = value

func _on_close_pressed() -> void:
	back_sound.play()
	var tween = create_tween()
	tween.tween_property(map_difficulty_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	map_difficulty_popup.visible = false
	map_difficulty_popup.scale = Vector2(1.0,1.0)
# DIFFICULTY SETTINGS POP UP END


func _on_toggle_drpc_toggled(toggled_on: bool) -> void:
	button_sound.play()
	if toggled_on and audio_file_name != null:
	#Discord RPC
		var platform = OS.get_name()
		if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
			var rpc = Engine.get_singleton("DiscordRPC")
			if rpc:
				rpc.details = "Editing - " + str(audio_file_name)
	else:
		var platform = OS.get_name()
		if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
			var rpc = Engine.get_singleton("DiscordRPC")
			if rpc:
				rpc.details = "♫ Editing a Chart ♫"
	if not OS.has_feature("web"):
	#Discord RPC
		var platform = OS.get_name()
		if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
			var rpc = Engine.get_singleton("DiscordRPC")
			if rpc:
				rpc.refresh()


func _on_file_video_file_selected(path: String) -> void:
	var video = FileAccess.open(path, FileAccess.READ)
	var videoname = path.get_file()
	var validformat = true

	if path.ends_with('.ogv'):
		pass
	else:
		validformat = false
		create_log('Error: Could not read file! (Wrong Format)', false)
	if validformat == true:
		create_log('Load Video: '+videoname, true)
		bg_video.stream = load(path)
		bg_video.play()
		bg_video.paused = true
		bg_video.visible = true
		source_video_path = path
		map_video = true
		video.close()



func _on_tempo_cancel_pressed() -> void:
	tempo_change_popup.visible = false

func _on_tempo_confirm_pressed() -> void:
	#print("trying to create partial timestamps")
	create_partial_bpm_timestamps()
	#print(changed_indices)

func _on_tempo_change_pressed() -> void:
	button_sound.play()
	tempo_change_popup.visible = not tempo_change_popup.visible


func _on_tempo_entry_value_changed(value: float) -> void:
	new_bpm = value


func _on_preview_point_pressed() -> void:
	button_sound.play()
	if bpm_timestamps and len(bpm_timestamps) >= active_beat:
		preview_point = bpm_timestamps[active_beat]/1000


func _on_kiai_point_pressed() -> void:
	if active_beat not in kiai_indices:
		kiai_indices.append(active_beat)
		var new_marker = tempo_marker.instantiate()
		new_marker.color = Color(0,1,1)
		kiai_markers.append(new_marker)
		timeline_scroll.add_child(new_marker)
		new_marker.position.x = ((bpm_timestamps[active_beat]/1000)/duration)*timeline_width
	else:
		kiai_indices.erase(active_beat)
		for marker in kiai_markers:
			marker.queue_free()

		kiai_markers.clear()
		for index in kiai_indices:
			var new_marker = tempo_marker.instantiate()
			new_marker.color = Color(0,1,1)
			kiai_markers.append(new_marker)
			timeline_scroll.add_child(new_marker)
			new_marker.position.x = ((bpm_timestamps[int(index)]/1000)/duration)*timeline_width
	creating_mapping_visualizer()


func _on_slli_pressed() -> void:
	if mappings:
		for i in mappings.size():
			if mappings[i] == 1:
				if (i-1) >= 0:
					mappings[i] = 0
					mappings[i-1] =1
		creating_mapping_visualizer()

func _on_srli_pressed() -> void:
	if mappings:
		var inverted_mappings = mappings.duplicate()
		inverted_mappings.reverse()
		for i in inverted_mappings.size():
			if inverted_mappings[i] == 1:
				if (i-1) >= 0:
					inverted_mappings[i] = 0
					inverted_mappings[i-1] =1
		inverted_mappings.reverse()
		mappings = inverted_mappings.duplicate()
		creating_mapping_visualizer()


func _on_clear_confirm_pressed() -> void:
	button_sound.play()
	if mappings:
		for i in mappings.size():
			mappings[i] = 0
		creating_mapping_visualizer()

func _on_clear_cancel_pressed() -> void:
	back_sound.play()
	var tween = create_tween()
	tween.tween_property(clear_warning_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	clear_warning_popup.visible = false
	clear_warning_popup.scale = Vector2(1.0,1.0)


func _on_clear_pressed() -> void:
	button_sound.play()
	if not clear_warning_popup.visible:
		clear_warning_popup.scale = Vector2(0.0,0.0)
		clear_warning_popup.visible = true
		var tween = create_tween()
		tween.tween_property(clear_warning_popup, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		var tween = create_tween()
		tween.tween_property(clear_warning_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tween.finished
		clear_warning_popup.visible = false
		clear_warning_popup.scale = Vector2(1.0,1.0)


func _on_quaver_pressed() -> void:
	button_sound.play()
	if mappings:
		for i in mappings.size():
			if (i % 2) == 0:
				mappings[i] = 1
		creating_mapping_visualizer()

func convert_osz_to_tux(diff_path):
	print("Loading " + str(diff_path))
	#source_audio_path = "user://tmp/audio.mp3"
	var osu_file = FileAccess.open(diff_path, FileAccess.READ)
	var text_content = osu_file.get_as_text()
	var file_info = text_content.split("\n", true)

	var stage = 0
	var offset_set = false
	var first_time_set = false

	for entry in file_info:
		entry = entry.strip_edges()

		if stage == 0:
			print("["+entry+"]")
			if entry.begins_with("AudioFilename:"):
				audio_file_name = entry.replace("AudioFilename: ","")
				source_audio_path = "user://tmp/" + entry.replace("AudioFilename: ","")
				print(source_audio_path)
				if source_audio_path.ends_with(".mp3"):
					if FileAccess.file_exists(source_audio_path):
						print("wwwge")
						var music_file = FileAccess.open(source_audio_path, FileAccess.READ)
						var buffer = music_file.get_buffer(music_file.get_length())

						var stream = AudioStreamMP3.new()
						stream.data = buffer
						music.stream = stream
						duration = music.stream.get_length()
				elif source_audio_path.ends_with(".ogg"):
					if FileAccess.file_exists(source_audio_path):
						var music_file = FileAccess.open(source_audio_path, FileAccess.READ)
						var buffer = music_file.get_buffer(music_file.get_length())

						var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
						music.stream = stream
						duration = music.stream.get_length()
			if entry.begins_with("PreviewTime"):
				preview_point = float(entry.replace("PreviewTime: ",""))/1000
			if entry.begins_with("BeatDivisor:"):
				pass
				#divider = int(entry.replace("BeatDivisor:",""))
			if entry.begins_with("Title:"):
				map_name = entry.replace("Title:","")
				name_entry.text = str(map_name)
			if entry.begins_with("Artist:"):
				map_artist = entry.replace("Artist:","")
				artist_entry.text = str(map_artist)
			if entry.begins_with("Creator:"):
				map_mapper = entry.replace("Creator:","")
				mapper_entry.text = str(map_mapper) + " ft. " + EDITOR_VERSION
			if entry.begins_with("Version:"):
				map_difficulty = entry.replace("Version:","")
				difficulty_entry.text = str(map_difficulty)
			if entry.begins_with("HPDrainRate:"):
				HP = float(entry.replace("HPDrainRate:",""))
				$Top/Control/DifficultyPopUp/MapInfo/HP/HPSpin.value = float(HP)
			if entry.begins_with("OverallDifficulty:"):
				OD = float(entry.replace("OverallDifficulty:",""))
				$Top/Control/DifficultyPopUp/MapInfo/OD/ODSpin.value = float(OD)
			if entry.begins_with("ApproachRate:"):
				AR = float(entry.replace("ApproachRate:",""))
				$Top/Control/DifficultyPopUp/MapInfo/AR/ARSpin.value = float(AR)
			if entry.begins_with("0,0,"):
				var background_info = entry.split(",", true)
				var background_filename = background_info[2]
				background_filename = background_filename.erase(0)
				background_filename = background_filename.erase(len(background_filename)-1)

				source_bg_path = "user://tmp/" + background_filename
				print(source_bg_path)
				map_background = background_filename
				custom_background.texture = ImageTexture.create_from_image(Image.load_from_file(source_bg_path))
				background_rect.texture = null
				custom_background.visible = true
			if entry.begins_with("[TimingPoints]"):
				print("scanning timing points")
				stage = 1
		elif stage == 1:
			if not entry == "":
				var timing_info = entry.split(",", true)
				var ms = float(timing_info[0])

				if not offset_set:
					offset_set = true
					offset = ms/1000
					offset_entry.text = str(int(ms))

				if float(timing_info[6]) == 1:
					if not first_time_set:
						print("["+entry+"]")
						first_time_set = true
						#print(timing_info[1])
						bpm = 60000.0/float(timing_info[1])
						bpm_entry.text = str(bpm)
						create_bpm_timestamps_from_osz()
					else:
						create_partial_bpm_timestamps_from_osz(ms,60000.0/float(timing_info[1]))
			else:
				print("no longer scanning timing points")
				stage = 2
		elif stage == 2:
			if entry.begins_with("[HitObjects]"):
				print("scanning hit points")
				stage = 3
		elif stage == 3:
			if not entry == "":
				var hit_info = entry.split(",", true)
				var ms = float(hit_info[2])

				var best_j = 0
				var best_diff = INF
				for j in bpm_timestamps.size():
					var diff = abs(float(bpm_timestamps[j]) - ms)
					if diff < best_diff:
						best_diff = diff
						best_j = j
					elif diff > best_diff:
						break

				if mappings:
					mappings[best_j] = 1

	print(bpm_timestamps.size())
	print(mappings.size())
	creating_mapping_visualizer()


	#custom_background.texture = ImageTexture.create_from_image(Image.load_from_file("user://tmp/" + diff_path + "/background.jpg"))


func load_osz_file(path: String):
	var temp_files = DirAccess.get_files_at("user://tmp/")

	for file in temp_files:
		DirAccess.remove_absolute("user://tmp/" + file)

	var reader = ZIPReader.new()
	reader.open(path)

	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open("user://tmp")

	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)

	var regex = RegEx.new()
	regex.compile("[^a-zA-Z]")

	#var file_name = regex.sub(map_name + map_difficulty, "", true).to_lower()

	for file in DirAccess.get_files_at("user://tmp/"):
		if file.ends_with(".osu"):
			var osu_file = FileAccess.open("user://tmp/" + file, FileAccess.READ)
			#print(file)
			var text_content = osu_file.get_as_text()
			var file_info = text_content.split("\n", true)

			for entry in file_info:
				if entry.begins_with("Version:"):
					osz_diff_select.add_item(entry.replace("Version:", ""))
					osu_file.close()
					DirAccess.rename_absolute("user://tmp/" + file, "user://tmp/" + regex.sub(entry.replace("Version:", ""), "", true).to_lower() + ".tsu")

	if not osz_import_popup.visible:
		osz_import_popup.scale = Vector2(0.0,0.0)
		osz_import_popup.visible = true
		var tween = create_tween()
		tween.tween_property(osz_import_popup, "scale", Vector2(1.0, 1.0), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_file_osz_file_selected(path: String) -> void:
	osz_diff_select.clear()
	#var osz_file = FileAccess.open(path, FileAccess.READ)
	var filename = path.get_file()
	var validformat = true

	if path.ends_with('.osz'):
		pass
	else:
		validformat = false
		create_log('Error: Could not read file! (Wrong Format)', false)

	if validformat == true:
		#DirAccess.copy_absolute(path, "user://tmp/oszimport.zip")
		load_osz_file(path)
		#read_osz_file("user://tmp/oszimport.zip")

func _on_import_osz_pressed() -> void:
	button_sound.play()
	print("opening osz")
	oszload.popup()

func _on_import_confirm_pressed() -> void:
	button_sound.play()
	print("importing osz for real")
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z]")

	var diff_path = "user://tmp/" + regex.sub(osz_diff_select.get_item_text(osz_diff_select.get_selected_id()),"",true).to_lower() + ".tsu"
	convert_osz_to_tux(diff_path)

	var tween = create_tween()
	tween.tween_property(osz_import_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	osz_import_popup.visible = false
	osz_import_popup.scale = Vector2(1.0,1.0)

func _on_import_cancel_pressed() -> void:
	back_sound.play()

	var temp_files = DirAccess.get_files_at("user://tmp/")

	for file in temp_files:
		DirAccess.remove_absolute("user://tmp/" + file)

	print("nvm")

	var tween = create_tween()
	tween.tween_property(osz_import_popup, "scale", Vector2(0.0, 0.0), .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	osz_import_popup.visible = false
	osz_import_popup.scale = Vector2(1.0,1.0)

func _on_files_dropped(files):
	for path in files:
		if path.ends_with('.osz'):
			_on_file_osz_file_selected(path)
		if path.ends_with('.mp3') or path.ends_with('.ogg'):
			_on_file_music_file_selected(path)
		if path.ends_with('.json'):
			_on_file_chart_file_selected(path)
		if path.ends_with('.png') or path.ends_with('.jpg'):
			imgloadaction = 'bg'
			_on_file_img_file_selected(path)
		if path.ends_with('.ogv'):
			_on_file_video_file_selected(path)
