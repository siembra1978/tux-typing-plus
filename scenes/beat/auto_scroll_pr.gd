extends Control

var timer = 0
var scrolling = false
var final_pos

@onready var content = get_node("SongArtist")

func _ready() -> void:
	pass
	
func reset():
	print("resetting!")
	scrolling = false
	content.position.x = 0
	print(content.position.x)
	
	print(str(content.get_combined_minimum_size().x ) + " and " + str(self.size.x))
	if content.get_combined_minimum_size().x > self.size.x:
		print("scrolling!")
		scrolling = true
		final_pos = -content.get_combined_minimum_size().x
	else:
		content.size.x = self.size.x

func _process(delta: float) -> void:
	if content.get_combined_minimum_size().x > self.size.x:
		scrolling = true
	else:
		scrolling = false
	
	final_pos = -content.get_combined_minimum_size().x
	
	if scrolling:
		if content.position.x > final_pos:
			content.position.x -= 100 * delta
		else:
			content.position.x = self.size.x
