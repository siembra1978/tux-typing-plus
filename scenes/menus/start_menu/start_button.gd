extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	self.get_parent().get_node("ButtonPress").play()
	var tween := create_tween()
	tween.parallel().tween_property(self.get_parent().get_node("Fade"), "modulate:a", 1, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame
	Config.load_scene('res://scenes/menus/select_mode/select_mode.tscn')
