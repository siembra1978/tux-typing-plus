extends Button

var button_sound
var fade
var new_click
var active = true

func _ready() -> void:
	button_sound = get_tree().current_scene.get_node("ButtonPress")
	fade = get_tree().current_scene.get_node("OnTop").get_node("Fade")
	pivot_offset = size / 2
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(func(): pivot_offset = size / 2)

func _on_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	if get_tree().current_scene.name == "Beat":
		get_tree().change_scene_to_file("res://scenes/beat/rhythmgame.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menus/select_mode/select_mode.tscn")
		
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
