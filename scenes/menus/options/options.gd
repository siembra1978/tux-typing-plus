extends Control

var scene
var fade
var config = ConfigFile.new()


# Nodes
@onready var box = get_node("BoxContainer")
@onready var volume_slider = box.get_node('Volume')
@onready var wumba_button = get_node('Wumba')
@onready var hidden_button = get_node('HiddenButton')
@onready var res_button = box.get_node('RES')
@onready var fs_button = box.get_node('FS')
@onready var fps_button = box.get_node('FPS')
@onready var fps_tog_button = box.get_node('FPSTog')
@onready var vsync_tog_button = box.get_node('VsyncTog')
@onready var effects = box.get_node("Effects")
@onready var readability = box.get_node("Readability")
@onready var dyslexia = box.get_node("Dyslexia")
@onready var giggle = get_node("Giggle")
@onready var button_sound = get_node("ButtonPress")
@onready var back = get_node("Back")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	scene = get_tree().current_scene
	#if wumbabutton:
		#wumbabutton.set_pressed_no_signal(Config.wumba)
		
	var err = config.load("user://config.cfg")
	
	if err != OK:
		return
	
	var platform = OS.get_name()

	if platform == "Web":
		box.get_node("ResLabel").queue_free()
		box.get_node("RES").queue_free()
		box.get_node("FSLabel").queue_free()
		box.get_node("FS").queue_free()
		box.get_node("FPSLabel").queue_free()
		box.get_node("FPS").queue_free()
		box.get_node("FPSTog").queue_free()
		box.get_node("VsyncTog").queue_free()

		
	if res_button:
		match config.get_value('Tux Typing Config', 'Resolution'):
			Vector2i(1280, 720):
				res_button.select(0)
			Vector2i(1920, 1080):
				res_button.select(1)
			Vector2i(2560, 1440):
				res_button.select(2)
			Vector2i(3840, 2160):
				res_button.select(3)
	if fs_button:
		match config.get_value('Tux Typing Config', 'Fullscreen'):
			0:
				res_button.disabled = false
				fs_button.select(2)
			3:
				res_button.disabled = true
				fs_button.select(0)
			4:
				res_button.disabled = true
				fs_button.select(1)
	if fps_button:
		match config.get_value('Tux Typing Config', 'FPS'):
			30:
				fps_button.select(0)
			60:
				fps_button.select(1)
			120:
				fps_button.select(2)
			144:
				fps_button.select(3)
			240:
				fps_button.select(4)
			0:
				fps_button.select(5)
	if volume_slider:
		volume_slider.value = db_to_linear(config.get_value('Tux Typing Config', 'Volume'))
		
	var fpstog = config.get_value('Tux Typing Config', 'ShowFPS')
	FpsCounter.visible = fpstog
	if fps_tog_button:
			fps_tog_button.set_pressed_no_signal(fpstog)
	
	var vsynctog = config.get_value('Tux Typing Config', 'Vsync')
	if vsync_tog_button:
		vsync_tog_button.set_pressed_no_signal(vsynctog)
	
	Config.min_effects = config.get_value('Tux Typing Config', 'MinEffects')
	#print("wtf min?: " + str(Config.min_effects))
	if effects:
		effects.set_pressed_no_signal(Config.min_effects)
	Config.improve_readability = config.get_value('Tux Typing Config', 'ImproveRead')
	#print("wtf read?: " + str(Config.improve_readability))
	if readability:
		readability.set_pressed_no_signal(Config.improve_readability)
	Config.dyslexic_mode = config.get_value('Tux Typing Config', 'Dyslexia')
	#print("wtf dys?: " + str(Config.dyslexic_mode))
	if dyslexia:
		dyslexia.set_pressed_no_signal(Config.dyslexic_mode)
		
	if wumba_button:
		wumba_button.set_pressed_no_signal(Config.wumba)
		
		
	var time = Time.get_datetime_dict_from_system()
	if time['month'] == 4 and time['day'] == 1:
		Config.wumba = true
		if wumba_button:
			wumba_button.disabled = true
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_res_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1280,720))
		1:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		2:
			DisplayServer.window_set_size(Vector2i(2560,1440))
		3:
			DisplayServer.window_set_size(Vector2i(3840,2160))
			
	config.set_value("Tux Typing Config", "Resolution", DisplayServer.window_get_size())
	config.save("user://config.cfg")
	

func _on_fs_item_selected(index: int) -> void:
	match index:
		0:
			res_button.disabled = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			res_button.disabled = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		2:
			res_button.disabled = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	config.set_value("Tux Typing Config", "Fullscreen", DisplayServer.window_get_mode())
	config.save("user://config.cfg")
			

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Config.music, linear_to_db(value))
	
	config.set_value("Tux Typing Config", "Volume", AudioServer.get_bus_volume_db(Config.music))
	config.save("user://config.cfg")
	

func _on_wumba_toggled(toggled_on: bool) -> void:
	Config.wumba = toggled_on
	if Config.wumba ==  true:
		giggle.play()
		
func open_menu(menu):
	print("h")
	menu.visible = true
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
	#await last_tween.finished
			
func close_menu(menu):
	#scene.get_node('OnTop/Pause').get_node('BoxContainer').visible = true
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
	self.visible = false
	return true

func _on_exit_pressed() -> void:
	button_sound.play()
	if get_tree().current_scene.name == "ModeSelect":
		if scene.stage == 2:
			await close_menu(get_node('BoxContainer'))
			scene.header.text = ""
			scene.stage = 0
			scene.game_mode = null
			scene.menu.visible = true
			scene.options.visible = false
			var tween = create_tween().set_parallel(true)
			tween.tween_property(scene.menu, "position", Vector2(scene.menu.position.x, 150.219), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await tween.finished
	else:
		#scene.get_node('OnTop/Pause').optionsmenu.visible = false
		#scene.get_node('OnTop/Pause').get_node('BoxContainer').visible = true
		await close_menu(get_node('BoxContainer'))
		open_menu(scene.get_node('OnTop/Pause').get_node('BoxContainer'))


func _on_fps_item_selected(index: int) -> void:
	match index:
		0:
			Engine.max_fps = 30
		1:
			Engine.max_fps = 60
		2:
			Engine.max_fps = 120
		3:
			Engine.max_fps = 144
		4:
			Engine.max_fps = 240
		5:
			Engine.max_fps = 0
	config.set_value('Tux Typing Config', 'FPS',Engine.get_max_fps())
	config.save("user://config.cfg")

func _on_fps_tog_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FpsCounter.get_node('CanvasLayer').visible = true
	else:
		FpsCounter.get_node('CanvasLayer').visible = false
	config.set_value('Tux Typing Config', 'ShowFPS',toggled_on)
	config.save("user://config.cfg")
		
func _on_vsync_tog_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	config.set_value('Tux Typing Config', 'Vsync',toggled_on)
	config.save("user://config.cfg")


func _on_hidden_button_pressed() -> void:
	hidden_button.visible = false
	wumba_button.visible = true

func _on_effects_toggled(toggled_on: bool) -> void:
	#print("Setting min effects to: " + str(toggled_on))
	Config.min_effects = toggled_on
	config.set_value('Tux Typing Config', 'MinEffects', toggled_on)
	config.save("user://config.cfg")


func _on_readability_toggled(toggled_on: bool) -> void:
	#print("Setting improve read to: " + str(toggled_on))
	Config.improve_readability = toggled_on
	config.set_value('Tux Typing Config', 'ImproveRead', toggled_on)
	config.save("user://config.cfg")


func _on_dyslexia_toggled(toggled_on: bool) -> void:
	#print("Setting dyslexia to: " + str(toggled_on))
	Config.dyslexic_mode = toggled_on
	config.set_value('Tux Typing Config', 'Dyslexia', toggled_on)
	config.save("user://config.cfg")
	
