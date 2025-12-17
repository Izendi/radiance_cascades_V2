extends Node2D

@onready var fullScreenQuadTexture_1: Texture = $SubViewport_4.get_texture()
#@onready var bool_displayShaderUpdated: bool = false

@onready var mouseTex_A: Texture2D
@onready var mouseTex_B: Texture2D

@onready var bool_mouseClickIsHeld: bool = false
@onready var bool_mouseClickIsReleased: bool = true
@onready var bool_needToGenerateNewLineSDFfromInputs = false
@onready var mousePosition_click: Vector2 = Vector2(0.0, 0.0)
@onready var mousePosition_release: Vector2 = Vector2(0.0, 0.0)
@onready var currentSelectedColor: Vector4 = Vector4(0.8, 0.1, 0.1, 1.0)

@onready var currentArrayInex: int = 0

var time_passed: float = 0.0

var ping_is_A := true

@onready var sdfSSLocation: Image
@onready var sdfSSColor: Image
@onready var storageTextureWidth: int = 500
@onready var sdfSSLocation_tex : ImageTexture
@onready var sdfSSColor_tex : ImageTexture

func addValueToTextureArray(arrayIndex: int, startLocation: Vector2, endLocation: Vector2, chosenColor: Vector4):
	if arrayIndex >= storageTextureWidth || arrayIndex < 0:
		return
	
	var startAndEndLocation := Vector4(startLocation.x, startLocation.y, endLocation.x, endLocation.y)
	
	sdfSSLocation.set_pixel(
		arrayIndex,
		0,
		Color(startAndEndLocation.x, startAndEndLocation.y, startAndEndLocation.z, startAndEndLocation.w)
	)
	
	sdfSSColor.set_pixel(
		arrayIndex,
		0,
		Color(chosenColor.x, chosenColor.y, chosenColor.z, chosenColor.w)
	)
	
	sdfSSLocation_tex.set_image(sdfSSLocation)
	sdfSSColor_tex.set_image(sdfSSColor)

func _ready():
	
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1) 
	
	#Create ping pong texture:
	var texImage := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	texImage.fill(Color(0.0, 0.0, 0.0, 0.0))
	mouseTex_A = ImageTexture.create_from_image(texImage)
	mouseTex_B = ImageTexture.create_from_image(texImage)
	
	var height: int = 1
	sdfSSLocation = Image.create(storageTextureWidth, height, false, Image.FORMAT_RGBAF)
	sdfSSColor = Image.create(storageTextureWidth, height, false, Image.FORMAT_RGBAF)
	
	sdfSSLocation_tex = ImageTexture.create_from_image(sdfSSLocation)
	sdfSSColor_tex = ImageTexture.create_from_image(sdfSSColor)
	
	$PingPongRoot/SubViewport_A/MeshInstance2D_A.material.set_shader_parameter("input_tex", mouseTex_A)
	$PingPongRoot/SubViewport_B/MeshInstance2D_B.material.set_shader_parameter("input_tex", mouseTex_B)
	

func _physics_process(delta):
	pass
	

func _process(delta):
	
	var vp = $PingPongRoot/SubViewport_A
	$PingPongRoot/SubViewport_A/MeshInstance2D_A.material.set_shader_parameter("viewport_size", vp.size)
	$PingPongRoot/SubViewport_B/MeshInstance2D_B.material.set_shader_parameter("viewport_size", vp.size)
	
	var isMousePressed: int = 0
	
	if Input.is_action_just_pressed("click"):
		bool_mouseClickIsHeld = true
		mousePosition_click = get_viewport().get_mouse_position()
		print(mousePosition_click)
	
	if Input.is_action_just_released("click"):
		bool_mouseClickIsReleased = false
		mousePosition_release = get_viewport().get_mouse_position()
		bool_needToGenerateNewLineSDFfromInputs = true
		print(mousePosition_release)
		print ("\n --- \n")
	
	if bool_needToGenerateNewLineSDFfromInputs == true:
		addValueToTextureArray(currentArrayInex, mousePosition_click, mousePosition_release, currentSelectedColor)
		currentArrayInex = currentArrayInex + 1
		bool_needToGenerateNewLineSDFfromInputs = false
	
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentLocationCoords_tex", sdfSSLocation_tex)
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentColors_tex", sdfSSColor_tex)
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("arrayLargestIndex", currentArrayInex)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		isMousePressed = 1
	else:
		isMousePressed = 0
	
	if ping_is_A:
		# PASS 1 for mouse tex:
		$PingPongRoot/SubViewport_A/MeshInstance2D_A.material.set_shader_parameter("mousePos", get_viewport().get_mouse_position())
		$PingPongRoot/SubViewport_A/MeshInstance2D_A.material.set_shader_parameter("mouseClick", isMousePressed)
		$PingPongRoot/SubViewport_A/MeshInstance2D_A.material.set_shader_parameter("input_tex", mouseTex_A)
		$PingPongRoot/SubViewport_A.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		await get_tree().process_frame
		
		mouseTex_B = $PingPongRoot/SubViewport_A.get_texture()
		
		ping_is_A = false
	else:
		
		# PASS 2 for mouse tex:
		$PingPongRoot/SubViewport_B/MeshInstance2D_B.material.set_shader_parameter("mousePos", get_viewport().get_mouse_position())
		$PingPongRoot/SubViewport_B/MeshInstance2D_B.material.set_shader_parameter("mouseClick", isMousePressed)
		$PingPongRoot/SubViewport_B/MeshInstance2D_B.material.set_shader_parameter("input_tex", mouseTex_B)
		$PingPongRoot/SubViewport_B.render_target_update_mode = SubViewport.UPDATE_ONCE
	
		await get_tree().process_frame
	
		mouseTex_A = $PingPongRoot/SubViewport_B.get_texture()
		
		ping_is_A = true
	
	#time_passed = time_passed + float(delta)
	
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


func _on_button_draw_with_sdfs_pressed():
	
	fullScreenQuadTexture_1 = $PingPongRoot/SubViewport_A.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)


func _on_button_segment_draw_pressed():
	fullScreenQuadTexture_1 = $SubViewport_5.get_texture()
	$MeshInstance2D.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)
