extends Node2D

var speed = 100
var scene
var active = true
var self_active = true
var cooldown = false
var my_index

@onready var sprite = get_node("Sprite")
@onready var readbox = sprite.get_node("ReadabilityBox")
@onready var label = sprite.get_node("Label")

var dyslexic_font = preload("res://assets/visual/fonts/dyslexic.otf")

func _ready() -> void:
	scene = self.get_parent()
	
	if Config.min_effects:
		#sprite.self_modulate = Color(0,0,0,0)
		sprite.stop()
		
	if Config.improve_readability:
		readbox.visible = true
		label.add_theme_font_size_override("font_size", 30)
	else:
		readbox.visible = false
		
	if Config.dyslexic_mode:
		label.add_theme_font_override("font", dyslexic_font)
		#label.label_settings.font = dyslexic_font
		#label.add_theme_font_size_override("font_size", 24)
	
func _process(delta: float) -> void:
	active = scene.active
	
	if active and self_active:
		self.position.y += speed*delta
		if len(scene.fishs) > 0:
			scene.pointer.position.y = scene.fishs[0].position.y - 30
		
		if self.position.y >= get_viewport_rect().size.y - 40:
			#var tween = create_tween()
			#scene.fishs.play('splat')
			#await tween.tween_property($Sprite, "modulate:a", 0.0, 1.0) # Fades over 1 second
			fade_out()
			#scene.fishs.erase(self)
			#self.queue_free()
			if not self.get_node("Sprite").get_node("Label").text == '':
				scene.streak = 0
			else:
				scene.health -= 1
				self.get_node('splat').play()
			
func fade_out():
	if not self.get_node("Sprite").get_node("Label").text == '':
		#scene.fishs.remove_at(0)
		scene.fishs.erase(self)
		
		if my_index == 0:	
			scene.letter_bank.clear()
			scene.active_words.remove_at(0)
			scene.word_loc.remove_at(0)
			scene.current_index = 0
			scene.health -= 1
			self.get_node('splat').play()
	else:
		scene.get_node("Tux").queue.pop_front()
			
	self_active = false
	self.get_node('Sprite').play('splat')
	self.readbox.visible = false
	await get_tree().create_timer(1).timeout
	
	var tween := create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0, .50).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if self.get_node("Sprite").get_node("Label").text == '':
		if self.active:
			if self.get_node("Sprite").animation != "splat":
				scene.fishs.erase(self)
				self.queue_free()
				scene.fish_count -= 1
				print("fish caught!")
				if not scene.tux.eating:
					print("lets eat!")
					scene.tux.eat()
