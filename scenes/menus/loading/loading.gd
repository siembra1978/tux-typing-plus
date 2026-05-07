extends Control

var progress = []
var loading_status

var tips = [
	"Wiggle your fingers and jam the keys!",
	"A quick snap of the finger, and with practice, that's all there is to it.",
	"You should be sitting up straight, but without stiffness, and should feel comfortable.",
	"Don't ever let yourself become tense.",
	"Are you relaxed? You should be, you know.",
	"Curve your fingers naturally and rest their tips lightly on the homerow keys.",
	"Speed and skill will of course come with practice.",
	"Don't ever let yourself get discouraged!",
	"Try not to look at the keyboard!",
	"Use the ridges on the F and J keys to return to the homerow keys.",
	"With practice you'll find that it is easier than you have ever thought possible.",
	"Start slow, and build your way up.",
	"The key is to emphasize precision over raw speed. Speed comes with practice.",
	"Make sure to take breaks to prevent carpal tunnel and RSI!",
	"I cooka da pizza, can you?",
	"I hit the tuxport 1 trillion$"
]

@onready var tip_label = get_node("Tip")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	tip_label.text = "[wave][color=yellow]Tip:[/color] " + tips.pick_random()
	var animations = Array($Control/sprite.sprite_frames.get_animation_names()).pick_random()
	$Control/sprite.play(animations)
	ResourceLoader.load_threaded_request(Config.next_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	loading_status = ResourceLoader.load_threaded_get_status(Config.next_scene, progress)
	$Control/sprite.speed_scale = max(0.1, progress[0])
	
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene = ResourceLoader.load_threaded_get(Config.next_scene)
		get_tree().change_scene_to_packed(packed_scene)
		
