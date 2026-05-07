extends Control

var fade

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Discord RPC
	DiscordRPC.details = "Title Screen"
	DiscordRPC.large_image = "icon"
	DiscordRPC.small_image = 'None'

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
	
	DiscordRPC.refresh()
	
	fade = $Fade
	fade.visible = true

	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			$TitleMusic.stop()
			$Bye.play()
			var tween := create_tween()
			tween.parallel().tween_property(fade, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(1.5).timeout
			get_tree().quit()
