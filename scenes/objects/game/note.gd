extends Node2D

var scene
var active = true
var self_active = true
var in_play = true
var damage = 10
var leniency

var ap
var OD
var AR
var hit_window
var ap_hit_window

var timestamp

var smoothed_time: float = 0.0

@onready var sprite = get_node("Sprite")
@onready var readbox = sprite.get_node("ReadabilityBox")
@onready var hitcircle = sprite.get_node("HitCircle")
@onready var label = sprite.get_node("Label")

var dyslexic_font = preload("res://assets/visual/fonts/dyslexic.otf")

func _ready() -> void:
	scene = self.get_parent()
	leniency = scene.leniency
	
	if Config.min_effects:
		sprite.self_modulate = Color(0,0,0,0)
		hitcircle.visible = false
		
	if Config.improve_readability:
		readbox.visible = true
		
	if Config.dyslexic_mode:
		label.label_settings.font = dyslexic_font
		#label.add_theme_font_size_override("font_size", 128)
		
	ap = scene.mods["AP"]
	OD = scene.OD
	AR = scene.AR
	
	ap_hit_window = 80 - (6 * OD)
	hit_window = 200 - (10 * OD)
	
func _process(delta: float) -> void:
	active = scene.active

	var hit_point = scene.hit_point
	var start_pos = (hit_point - scene.dur_in_pos) + (scene.dur_in_pos * (1 - ((timestamp/1000)/scene.duration)))

	var audio_time = scene.playback_position

	if audio_time != smoothed_time:
		smoothed_time = lerp(smoothed_time + (delta*scene.music.pitch_scale), audio_time, 0.1)
	else:
		smoothed_time += (delta*scene.music.pitch_scale)

	#self.position.y = start_pos + (scene.playback_position/scene.duration)*scene.dur_in_pos

	if in_play:
		self.position.y = start_pos + (smoothed_time/scene.duration)*scene.dur_in_pos
		
		var hd_point = hit_point/3
		
		if scene.mods["HD"]:
			if not (start_pos >= (hd_point)):
				if self.position.y > (hd_point):
					var tween := create_tween()
					tween.parallel().tween_property(self, "modulate:a", 0, .1875).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if ap:
			if scene.playback_position >= (timestamp/1000):
				scene.hit(self, (audio_time*1000) - (timestamp))

		if ((audio_time*1000) - (timestamp)) >= hit_window:
			in_play = false
			scene.miss(self)
