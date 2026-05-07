extends HSlider

var active = true
var new_click

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
