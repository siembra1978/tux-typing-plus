extends CharacterBody2D


var speed = 400.0
const JUMP_VELOCITY = -400.0

var start_position
var bound_x = 63
var bound_y = 63

var health = 1000
var invincible = false

func _ready() -> void:
	start_position = global_position
	
func game_over() -> void:
	print("game over")
	for node in get_tree().get_nodes_in_group("Pellet"):
			node.queue_free()
	$GrazeAnimation.visible = false
	
	await get_tree().create_timer(1).timeout
	
	$Break.play()

func iframes():
	invincible = true
	await get_tree().create_timer(.75).timeout
	invincible = false

func _process(delta: float) -> void:
	var directionX := Input.get_axis("ui_left", "ui_right")
	var directionY := Input.get_axis("ui_up","ui_down")
	
	var direction := Vector2(directionX, directionY).normalized()
	
	global_position += direction * speed * delta
	
	'''
	if global_position.x > start_position.x + bound_x:
		global_position.x = start_position.x + bound_x
	elif global_position.x < start_position.x - bound_x:
		global_position.x = start_position.x - bound_x
		
	if global_position.y > start_position.y + bound_y:
		global_position.y = start_position.y + bound_y
	elif global_position.y < start_position.y - bound_y:
		global_position.y = start_position.y - bound_y
	'''
	
	if health <= 0:
		game_over()

func _input(event):
	if event is InputEventKey and event.pressed:
		var shifting = Input.is_key_pressed(KEY_SHIFT)
		var input_char = event.as_text().to_lower()
		
		if shifting:
			speed = 600
		else:
			speed = 400
			
		if event.keycode == KEY_ESCAPE:
			pass
