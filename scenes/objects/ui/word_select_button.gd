extends Button

var current_scene
var next_scene

var penguin = false

var phrase_set = ""

var new_click
var active = true

func _ready():
	pivot_offset = size / 2
	resized.connect(func(): pivot_offset = size / 2)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
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
	current_scene = self.get_parent().get_parent().get_parent()
	
	var tween := create_tween()
	tween.parallel().tween_property(current_scene.get_node("Fade"), "modulate:a", 1, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	self.get_parent().get_parent().visible = false
	
	if current_scene.game_mode == "cascade":
		$ButtonPress.play()
		await $ButtonPress.finished
		await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
		next_scene = load("res://scenes/game/fish_cascade.tscn").instantiate()
		next_scene.word_set = self.text.to_lower().replace(" ", "")
		next_scene.difficulty = current_scene.difficulty
		get_tree().change_scene_to_node(next_scene)
	elif current_scene.game_mode == "comet":
		$ButtonPress.play()
		await $ButtonPress.finished
		await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
		next_scene = load("res://scenes/game/comet_zap.tscn").instantiate()
		next_scene.word_set = self.text.to_lower().replace(" ", "")
		next_scene.difficulty = current_scene.difficulty
		get_tree().change_scene_to_node(next_scene)
	elif current_scene.game_mode == "rhythm":
		$ButtonPress.play()
		await $ButtonPress.finished
		await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
		next_scene = load("res://scenes/beat/beat.tscn").instantiate()
		next_scene.word_set = self.text.to_lower().replace(" ", "")
		next_scene.difficulty = current_scene.difficulty
		get_tree().change_scene_to_node(next_scene)
	elif current_scene.game_mode == "phrase":
		if penguin:
			$ButtonPress.play()
			await $ButtonPress.finished
			await get_tree().create_timer(0.5).timeout
			await get_tree().process_frame
			next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
			next_scene.penguin = true
			next_scene.word_set = "penguintype100"
			get_tree().change_scene_to_node(next_scene)
		else:
			$ButtonPress.play()
			await $ButtonPress.finished
			await get_tree().create_timer(0.5).timeout
			await get_tree().process_frame
			next_scene = load("res://scenes/game/phrase_typing.tscn").instantiate()
			next_scene.word_set = phrase_set
			get_tree().change_scene_to_node(next_scene)
		
