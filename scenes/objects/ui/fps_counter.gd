extends Control

@onready var counter_label = get_node("CanvasLayer/CounterLabel")

var max_fps = 0
var min_fps = INF

var timer = 0

var sum_fps = 0
var fps_count = 0
var avg_fps = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer >= 5:
		max_fps = 0
		min_fps = INF
		sum_fps = 0
		fps_count = 0
		timer = 0
	
	var current_fps = Engine.get_frames_per_second()
	
	sum_fps += current_fps
	fps_count += 1
	
	if current_fps > max_fps:
		max_fps = current_fps
	if current_fps < min_fps:
		min_fps = current_fps
	
	if fps_count > 0:
		avg_fps = sum_fps/fps_count
	
	counter_label.text = str(current_fps) + " FPS (min " + str(min_fps) + " / avg " + str(round(avg_fps)) + " / max " + str(max_fps) + ")"
