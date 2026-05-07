extends BoxContainer

var active = false
var og_y
var dist

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().current_scene.name == "RhythmGame":
		dist = 5
	else:
		dist = 10

func up():
	if not og_y:
		og_y = position.y
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, og_y-dist), 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	down()

func down():
	if not og_y:
		og_y = position.y
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, og_y+dist), 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	up()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
