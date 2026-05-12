extends Button

var button_sound
var fade
var current_scene
var new_click
var active = true

func _ready() -> void:
	current_scene = get_tree().current_scene
	button_sound = current_scene.get_node("ButtonPress")
	fade = current_scene.get_node("OnTop").get_node("Fade")
	pivot_offset = size / 2
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(func(): pivot_offset = size / 2)
	
	new_click = get_tree().current_scene.get_node("NewClick")

func _on_mouse_entered():
	if active:
		if new_click:
			new_click.play()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if active:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame

	if get_tree().current_scene.name == "CometZap":
		var next_scene = load("res://scenes/game/comet_zap.tscn").instantiate()
		next_scene.word_set = get_tree().current_scene.word_set
		next_scene.custom = get_tree().current_scene.custom
		next_scene.difficulty = get_tree().current_scene.difficulty
		get_tree().change_scene_to_node(next_scene)
	elif get_tree().current_scene.name == "FishCascade":
		var next_scene = load("res://scenes/game/fish_cascade.tscn").instantiate()
		next_scene.word_set = get_tree().current_scene.word_set
		next_scene.custom = get_tree().current_scene.custom
		next_scene.difficulty = get_tree().current_scene.difficulty
		get_tree().change_scene_to_node(next_scene)
	elif get_tree().current_scene.name == "Beat":
		var next_scene = load("res://scenes/beat/beat.tscn").instantiate()
		next_scene.word_set = current_scene.word_set
		next_scene.custom = get_tree().current_scene.custom
		next_scene.mods = current_scene.mods
		next_scene.legacy = current_scene.legacy
		next_scene.official = current_scene.official
		next_scene.beatmap_filename = current_scene.beatmap_filename
		get_tree().change_scene_to_node(next_scene)
	elif get_tree().current_scene.name == "PhraseTyping":
		if current_scene.penguin:
			var next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
			next_scene.word_set = current_scene.word_set
			next_scene.penguin = true
			next_scene.selected_sound_index = current_scene.selected_sound_index
			get_tree().change_scene_to_node(next_scene)
		else:
			var next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
			next_scene.word_set = current_scene.word_set
			next_scene.custom = get_tree().current_scene.custom
			next_scene.selected_sound_index = current_scene.selected_sound_index
			get_tree().change_scene_to_node(next_scene)
	else:
		var next_scene = load("res://scenes/menus/select_mode/select_mode.tscn").instantiate()
		get_tree().change_scene_to_node(next_scene)
