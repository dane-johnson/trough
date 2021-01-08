shader_type spatial;

render_mode diffuse_burley, skip_vertex_transform;

uniform sampler2D albedo_texture : hint_albedo;

void vertex() {
	vec4 world = (WORLD_MATRIX * vec4(VERTEX, 1.0));
	vec4 camera = (INV_CAMERA_MATRIX * world);
	float dist = clamp(length(camera), 50.0, 200.0);
	VERTEX.xyz *= mix(1.0, 2.0, (dist - 50.0) / 200.00);
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV.xy);
	ALBEDO = tex.rgb;
	
}
