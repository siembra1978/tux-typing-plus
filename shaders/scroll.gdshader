shader_type canvas_item;

uniform float speed = .1;

void vertex() {
	UV.x += TIME * speed;
	UV.y += TIME * speed;
}


