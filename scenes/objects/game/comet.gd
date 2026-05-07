extends Node2D

var speed = 100
var scene
var active = true
var self_active = true
var damage = 1

@onready var sprite = get_node("Sprite")
@onready var readbox = sprite.get_node("ReadabilityBox")
@onready var label = sprite.get_node("Label")

var dyslexic_font = preload("res://assets/visual/fonts/dyslexic.otf")

func _ready() -> void:
	scene = self.get_parent()
	
	if Config.min_effects:
		sprite.self_modulate = Color(0,0,0,0)
		
	if Config.improve_readability:
		readbox.visible = true
		
	if Config.dyslexic_mode:
		label.label_settings.font = dyslexic_font
		#label.add_theme_font_size_override("font_size", 32)
	
func _process(delta: float) -> void:
	active = scene.active
	
	if active and self_active:
		self.position.y += speed*delta
		
		if self.position.y >= get_viewport_rect().size.y:
			scene.miss(self)
