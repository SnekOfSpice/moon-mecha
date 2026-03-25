extends Node3D




func set_viewport(vp : SubViewport):
	var material = $MainScreen_001.get_surface_override_material(0)
	var vptex := vp.get_texture()
	#vptex.viewport_path = vp.get_path_to(self)
	material.albedo_texture = vptex
	$MainScreen_001.set_surface_override_material(0, material)
