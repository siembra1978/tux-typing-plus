extends TextureRect

var base_position
var parallax_strength: float = 0.02
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pivot_offset = size / 2
	base_position = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var viewport_center = get_viewport_rect().size / 2
	var mouse_offset = get_global_mouse_position() - viewport_center
	position = base_position + mouse_offset * parallax_strength
