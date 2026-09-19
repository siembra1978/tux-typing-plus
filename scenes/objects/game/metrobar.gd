extends Control

var scene
var active = true
var self_active = true
var in_play = true
var color_rect 

var direction = 1

var timestamp

var smoothed_time: float = 0.0

func _ready() -> void:
	scene = get_tree().current_scene
	color_rect = self.get_node("ColorRect")

	if scene.mods["UP"]:
		direction = -1
	
func _process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	self.position.x = .125*viewport_size.x
	color_rect.size.x = .75*viewport_size.x

	active = scene.active

	var hit_point = scene.hit_point
	var start_pos = (hit_point - direction*scene.dur_in_pos) + direction*(scene.dur_in_pos * (1 - ((timestamp/1000)/scene.duration)))
	
	if active and self_active:

		var audio_time = scene.playback_position

		if audio_time != smoothed_time:
			smoothed_time = lerp(smoothed_time + (delta*scene.music.pitch_scale), audio_time, 0.1)
		else:
			smoothed_time += (delta*scene.music.pitch_scale)

		self.position.y = start_pos + direction*((smoothed_time/scene.duration)*scene.dur_in_pos)
		
		if direction == 1:
			if self.position.y >= viewport_size.y:
				self.queue_free()
		elif direction == -1:
			if self.position.y <= 0:
				self.queue_free()

