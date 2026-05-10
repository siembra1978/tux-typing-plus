extends Node2D

#ui elements
var fade
var text
var keyboard
var keys
var lsd
var se
var pause_menu
var active = true

#other vars
var phase = 0
var size = 32
var music
var alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N",
"O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var time
var clocktype = true

@onready var on_top = get_node("OnTop")
@onready var options_dim = on_top.get_node("OptionsDim")

#Cosm0s note: this is pretty much just a sandbox cause actual lessons would've taken a bit so yeah.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Discord RPC
	#Discord RPC

	var platform = OS.get_name()
	if platform != "Web" and platform != "Android" and ClassDB.class_exists("DiscordRPC"):
		var rpc = Engine.get_singleton("DiscordRPC")
		if rpc:
			rpc.details = "Typing..."
			rpc.large_image = "icon" # Image key from "Art Assets"
			rpc.small_image = 'lesson'
			rpc.small_image_text = 'Sandbox'

			rpc.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
			# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
			
			rpc.refresh()
	
	RenderingServer.set_default_clear_color(Color("000000ff"))
	fade = self.get_node("OnTop").get_node("Fade")
	text = self.get_node("UI/Text")
	keyboard = self.get_node("UI/Keyboard")
	keys = self.get_node("UI/Keys")
	lsd = self.get_node("UI/LSD")
	se = get_node("ButtonPress")
	music = get_node("BackgroundMusic")
	pause_menu = self.get_node("OnTop").get_node("Pause")
	fade.visible = true
	text.visible = true
	lsd.visible = true
	self.get_node("UI/FontSize").modulate.a = 0.0
	self.get_node("UI/Controls").modulate.a = 0.0
	self.get_node("UI/Time").modulate.a = 0.0
	lsd.modulate.a = 0.0
	keyboard.modulate.a = 0.0

	if Config.min_effects:
		lsd.visible = false

	keys.play('General')
	keys.stop()
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if Config.wumba:
		text.set_text('Hello There. Welcome to Tux Typing[color=yellow]+[/color]. Now with added \n[font_size=100][wave]WUMBA![/wave][/font_size][pulse] _[/pulse]\n(Press any key to continue)')
	else:
		text.set_text('Hello There. Welcome to [wave]Tux Typing[color=yellow]+[/color][/wave].[pulse] _[/pulse]\n(Press any key to continue)')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Why is there a clock system? Idk. End key to switch between 12h/24h
	time = Time.get_time_dict_from_system()
	var time12h = time.hour%12
	var meridiem = "AM" if time.hour < 12 else "PM"
	if time12h == 0:
		time12h = 12
	if clocktype:
		self.get_node("UI/Time").set_text(str(time12h)+':'+"%02d" % [time.minute]+' '+str(meridiem))
	else:
		self.get_node("UI/Time").set_text(str(time.hour)+':'+"%02d" % [time.minute])
		
	$UI/Background.size = get_viewport().size

#Spaghetti Code begins now! Everything here is essentially hardcoded cause idk how to make a proper dialog system (oops)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.as_text() in alphabet:
			if active:
				if phase < 5:
					se.play()
				if not phase == 0 and not phase == 2 and not phase == 4:
					if phase == 5:
						await get_tree().create_timer(1).timeout
					phase += 1
				if phase == 0:
					text.set_text('First, press the [wave]A[/wave] key.[pulse] _[/pulse]')
					keyboard.visible = true
					keys.visible = true
					keys.set_frame(29)
					create_tween().parallel().tween_property(keyboard, "modulate:a", 1, 1)
					if event.keycode == KEY_A:
						phase += 1
				if phase == 1:
					keys.visible = false
					text.set_text('Good.[pulse] _[/pulse]')
				if phase == 2:
					keys.visible = true
					keys.set_frame(24)
					text.set_text('Now, press the [wave]P[/wave] key.[pulse] _[/pulse]')
					if event.keycode == KEY_P:
						phase += 1
				if phase == 3:
					keys.visible = false
					text.set_text('Alright.[pulse] _[/pulse]')
				if phase == 4:
					keys.visible = true
					keys.set_frame(19)
					text.set_text('Once more, press the [wave]T[/wave] key.[pulse] _[/pulse]')
					if event.keycode == KEY_T:
						phase += 1
						keys.visible = false
						text.set_text("Ok. Let's get into it.[pulse] _[/pulse]")
						music.play()
						await get_tree().create_timer(1).timeout
						text.set_text("")
						phase += 1
						if Config.wumba:
							$UI/Wumba.visible = true
				if phase > 6:
					if not Config.min_effects:
						lsd.visible = true
					self.get_node("UI/Controls").visible = true
					self.get_node("UI/FontSize").visible = true
					self.get_node("UI/Time").visible = true
					keys.visible = true
					#var player = get_node(event.as_text())
					#$A.stream = load('res://assets/audio/sfx/letter voiceclips/' + str(player)[0].to_lower() + '.wav')
					se.play()
					text.visible = true
					text.append_text('[wave][font_size=' + str(size) + ']'+event.as_text()+'[/font_size][/wave]')
					keys.play(event.as_text())
				if phase > 5:
					#await get_tree().create_timer(11.4).timeout
					create_tween().tween_property(lsd, "modulate:a", 1, 4)
					create_tween().tween_property(get_node("UI/Controls"), "modulate:a", 1, 2)
					create_tween().tween_property(get_node("UI/FontSize"), "modulate:a", 1, 2)
					create_tween().tween_property(get_node("UI/Time"), "modulate:a", 1, 2)
		elif event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.resume()
				$BackgroundMusic.volume_db = -15
			else:
				$Back.play()
				active = false
				pause_menu.visible = true
				pause_menu.position = Vector2(0, get_viewport_rect().size.y)
				var tween = create_tween().set_parallel(true)
				tween.tween_property(options_dim, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(pause_menu, "position", Vector2(0, 0), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				$BackgroundMusic.volume_db = -30
		elif event.keycode == KEY_SPACE:
			if phase > 6:
				text.append_text('[wave] [/wave]')
				keys.play('Space')
		elif event.keycode == KEY_ENTER:
			if phase > 6:
				text.append_text('[wave]\n [/wave]')
		elif event.keycode == KEY_DELETE:
			if phase > 6:
				text.set_text('')
				$Back.play()
		elif event.keycode == KEY_PAGEUP:
			size += 1
			self.get_node("UI/FontSize").set_text('Font Size: '+str(size))
		elif event.keycode == KEY_PAGEDOWN:
			if size > 1:
				size -= 1
			self.get_node("UI/FontSize").set_text('Font Size: '+str(size))
		elif event.keycode == KEY_END:
			clocktype = not clocktype
	else:
		if phase > 6:
			await get_tree().create_timer(0.05).timeout
			keys.play('None')
