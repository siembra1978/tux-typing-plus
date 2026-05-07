extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pivot_offset = Vector2(0, size.y)
	resized.connect(func(): pivot_offset = Vector2(0, size.y))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
