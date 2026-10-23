shader_type spatial;
// Suelo con cuadrícula brillante (estética de "mundo digital").
// La cuadrícula se calcula con la posición en el mundo, así el jugador ve las líneas
// pasar bajo sus pies y percibe que se mueve (un suelo liso no da esa referencia).

uniform vec4 background_color : source_color = vec4(0.03, 0.03, 0.09, 1.0);
uniform vec4 line_color : source_color = vec4(0.08, 0.3, 0.6, 1.0);
uniform float cell_size = 3.0;
uniform float line_width = 0.035;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Distancia (en unidades del mundo) a la línea más cercana en X y en Z.
	vec2 cell = abs(fract(world_position.xz / cell_size - 0.5) - 0.5) * cell_size;
	float line = 1.0 - step(line_width, min(cell.x, cell.y));
	ALBEDO = mix(background_color.rgb, line_color.rgb, line);
	EMISSION = line_color.rgb * line * 0.3;
	ROUGHNESS = 0.9;
}
