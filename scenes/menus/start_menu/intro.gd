extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("000000ff"))
	var fade = $Fade
	await get_tree().process_frame
	fade.visible = true
	
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2).timeout
	
	var tween2 := create_tween()
	tween2.parallel().tween_property($Notice, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween2.finished
	
	var tween3 := create_tween()
	tween3.parallel().tween_property($VBoxContainer, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	$harp.play()
	await $harp.finished
	
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/menus/select_mode/select_mode.tscn")
