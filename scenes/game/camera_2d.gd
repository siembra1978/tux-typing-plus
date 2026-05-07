extends Camera2D

@export var randomStrength: float = 30.0
@export var shakeFade: float = 5.0
var scene

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0

func _ready() -> void:
	scene = get_tree().current_scene

func apply_shake():
		shake_strength = randomStrength


func _process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade * delta)
		
		offset = randomOffset()
		
func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength),rng.randf_range(-shake_strength,shake_strength))
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode != KEY_ESCAPE and scene.active:
			if scene.phase > 6:
				if not Config.min_effects:
					apply_shake()
