extends Control

var scene
var button_sound
var fade
var optionsmenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene = get_tree().current_scene
	optionsmenu = get_node('Options')
	button_sound = $ButtonPress

	var platform = OS.get_name()

	if platform == "Web" or platform == "Android":
		self.get_node("BoxContainer/Quit").queue_free()
	
	if get_tree().current_scene.name == "Beat":
		get_node("BoxContainer/SelectExit").text = "Beatmap Select"
		
	if get_tree().current_scene.name == "Lessons":
		get_node("BoxContainer/Restart").visible = false
	
	$Logo.up()
	
	fade = self.get_parent().get_node("Fade")
	fade.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func resume():
	button_sound.play()
	scene.active = true
	#optionsmenu.visible = false
	#get_node('BoxContainer').visible = true
	
	if get_tree().current_scene.name == "Beat":
		scene.get_node("BackgroundMusic").play(scene.playback_position)
		if scene.video.stream:
			scene.video.paused = false
			scene.video.stream_position = scene.playback_position
		
	if get_tree().current_scene.name == "FishCascade":
		scene.get_node("BackgroundMusic").volume_db = -15.0
		
	if get_tree().current_scene.name == "CometZap":
		scene.get_node("BackgroundMusic").volume_db = 5
		
	if get_tree().current_scene.name == "Lessons":
		scene.get_node("BackgroundMusic").volume_db = -15.0
		
	#position = Vector2(0, get_viewport_rect().size.y)
	#await close_menu(optionsmenu.get_node("BoxContainer"))
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(scene.options_dim, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2(0, get_viewport_rect().size.y), .5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	self.visible = false

func open_menu(menu):
	print("opening")
	for button in menu.get_children():
		#button.active = false
		button.visible = true
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
	return
			
func close_menu(menu):
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
	return	

func _on_back_pressed() -> void:
	resume()

func _on_options_pressed() -> void:
	button_sound.play()
	optionsmenu.visible = true
	#get_node('BoxContainer').visible = false
	await close_menu(get_node('BoxContainer'))
	open_menu(optionsmenu.get_node("BoxContainer"))

func _on_select_exit_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	if get_tree().current_scene.name == "Beat":
		get_tree().change_scene_to_file("res://scenes/beat/rhythmgame.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menus/select_mode/select_mode.tscn")
	
func _on_exit_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/menus/start_menu/title.tscn")


func _on_quit_pressed() -> void:
	$Bye.play()
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()
