extends Node2D

@onready var fullScreenQuadTexture_1: Texture = $SubViewport_1.get_texture()
#@onready var bool_displayShaderUpdated: bool = false

func _ready():
	
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1) 


func _on_button_test_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_1.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_sdf_circle_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_2.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_grid_display_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_3.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)
