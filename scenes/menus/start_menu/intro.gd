extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("000000ff"))
	$harp.play()
	var fade = $Fade
	await get_tree().process_frame
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await $harp.finished
	await get_tree().create_timer(1	).timeout
	get_tree().change_scene_to_file("res://scenes/menus/select_mode/select_mode.tscn")
