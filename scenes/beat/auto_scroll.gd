extends Control

var timer = 0
var scrolling = false
var final_pos

@onready var content = get_child(0)

func _ready() -> void:
	await get_tree().process_frame
	
	
	if content.get_combined_minimum_size().x > self.size.x:
		scrolling = true
	
	final_pos = -content.get_combined_minimum_size().x
	
func reset():
	scrolling = false
	content.position.x = 0
	
	if content.get_combined_minimum_size().x > self.size.x:
		scrolling = true
	
	final_pos = -content.get_combined_minimum_size().x

func _process(delta: float) -> void:

	if content.get_combined_minimum_size().x > self.size.x:
		scrolling = true
	
	if not scrolling:
		#print("not scrolling")
		return

	if content.position.x > final_pos:
		content.position.x -= 100 * delta
	else:
		content.position.x = self.size.x
		
		
	if get_tree().current_scene.name == "RhythmGame":
		if content.get_combined_minimum_size().x > self.size.x:
			scrolling = true
		else:
			scrolling = false
		
		final_pos = -content.get_combined_minimum_size().x

		if not scrolling:
			content.position.x = 0
			return
