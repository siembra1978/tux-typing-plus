shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range(0.0, 1.0) = 0.4;
uniform float speed : hint_range(0.0, 2.0) = 0.333;
// screen_resolution is usually not needed for canvas_item unless handling aspect ratio strictly
uniform vec2 screen_resolution = vec2(1280.0, 720.0);

void fragment() {
    float t = TIME * speed;
    
    // Use local UV for ColorRect, not screen space
    vec2 pos = UV * 2.0 - 1.0; 
    
    // Optional: Keep aspect ratio based on rect size if needed
    pos.x *= (screen_resolution.x / screen_resolution.y);
    pos *= 4.0; 

    for (float k = 1.0; k < 7.0; k += 1.0) {
        pos.x += strength * sin(2.0 * t + k * 1.5 * pos.y) + t * 0.5;
        pos.y += strength * cos(2.0 * t + k * 1.5 * pos.x);
    }

    vec3 col = 0.5 + 0.5 * cos(TIME + pos.xyx + vec3(0.0, 2.0, 4.0));
    
    // Gamma correction
    col = pow(col, vec3(0.4545));
    
    // Set color, multiplying by COLOR.a allows modulate.a to fade it
    COLOR.rgb = col;
    COLOR.a = 1.0 * COLOR.a; // Keeps base alpha but allows modulation
}