extends AnimatedSprite2D

var speed = 500
var right = true

@onready var menu = self.get_parent()

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    if right:
        position.x += speed*delta
    else:
        position.x -= speed*delta

    if position.x >= menu.size.x:
        right = false
        flip_h = true
    elif position.x <= 0:
        right = true
        flip_h = false
