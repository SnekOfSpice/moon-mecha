extends ColorRect

@export var gradient_width := 16

var _gradient_tween : Tween


func set_gradient_map(map : GradientTexture1D, mix_steps := 32, blend_time := 6.4):
	var gradient_map_material : Material = get_material()
	
	var current_gradient : Gradient = (gradient_map_material.get_shader_parameter("gradient") as GradientTexture1D).gradient
	
	if _gradient_tween:
		_gradient_tween.kill()
	_gradient_tween = create_tween()
	for blend_step in mix_steps:
		var blended_map := GradientTexture1D.new()
		var blended_gradient := Gradient.new()
		blended_map.gradient = blended_gradient
		blended_map.width = gradient_width
		for i in gradient_width:
			var offset := (float(i) / float(gradient_width))
			offset *= float(gradient_width)/float(gradient_width - 1)
			var base_color : Color = current_gradient.sample(offset)
			var goal_color : Color = map.gradient.sample(offset)
			var next_color : Color = lerp(base_color, goal_color, float(blend_step) / float(mix_steps))
			
			if i < 2: # gradients start out with 2 points by deffault so as to not fuck up the sampling and get false colors we do this
				blended_gradient.set_offset(i, offset)
			else:
				blended_gradient.add_point(offset, i)
			
			blended_gradient.set_color(i, next_color)
			
		#gradient_map_material.set_shader_parameter("gradient", blended_map)
		
		_gradient_tween.tween_method(_set_gradient, blended_map, blended_map, 0).set_delay(blend_time / float(mix_steps))
		#await get_tree().create_timer(blend_time / float(mix_steps)).timeout
	_gradient_tween.tween_method(_set_gradient, map, map, 0).set_delay(blend_time)


func _set_gradient(map : GradientTexture1D):
	get_material().set_shader_parameter("gradient", map)
