extends Node2D

@onready var fullScreenQuadTexture_1: Texture = $SubViewport_1.get_texture()
#@onready var bool_displayShaderUpdated: bool = false

var time_passed: float = 0.0

func _ready():
	
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1) 

func _physics_process(delta):
	pass
	

func _process(delta):
	time_passed = time_passed + float(delta)
	
	#$SubViewport_2/MeshInstance2D.material.set_shader_parameter("total_elapsed_time", time_passed)
	#$SubViewport_4/MeshInstance2D.material.set_shader_parameter("total_elapsed_time", time_passed)

func _on_button_test_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_1.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_sdf_circle_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_2.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_grid_display_shader_pressed():
	fullScreenQuadTexture_1 = $SubViewport_3.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_SDF_pressed():
	fullScreenQuadTexture_1 = $SubViewport_4.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)
