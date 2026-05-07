extends Button

var current_scene
var next_scene
var given_filename
var legacy
var official

var active = true
var new_click

func _on_pressed() -> void:
	if active:
		current_scene = get_tree().current_scene
		$ButtonPress.play()
		current_scene.select_file(self, given_filename, official, legacy)

# Called when the node enters the scene tree for the first time.
func _ready():
	pivot_offset = Vector2(size.x, size.y/2)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(func(): pivot_offset = Vector2(size.x, size.y/2))
	
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
