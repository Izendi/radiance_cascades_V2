extends Node2D

@onready var fullScreenQuadTexture_1: Texture = $SubViewport_5.get_texture()
#@onready var bool_displayShaderUpdated: bool = false

@onready var mouseTex_A: Texture2D
@onready var mouseTex_B: Texture2D

@onready var bool_mouseClickIsHeld: bool = false
@onready var bool_mouseClickIsReleased: bool = true
@onready var bool_needToGenerateNewLineSDFfromInputs = false
@onready var mousePosition_click: Vector2 = Vector2(0.0, 0.0)
@onready var mousePositionPlaceholder_release: Vector2 = Vector2(0.0, 0.0)
@onready var mousePosition_release: Vector2 = Vector2(0.0, 0.0)
@onready var currentSelectedColor: Vector4 = Vector4(0.8, 0.1, 0.1, 1.0)

@onready var currentArrayInex: int = 0

@onready var segmentThickness: float = 5.0

var time_passed: float = 0.0

var ping_is_A := true

@onready var sdfSSLocation: Image
@onready var sdfSSColor: Image
@onready var storageTextureWidth: int = 500
@onready var sdfSSLocation_tex : ImageTexture
@onready var sdfSSColor_tex : ImageTexture

func addValueToTextureArray(arrayIndex: int, startLocation: Vector2, endLocation: Vector2, chosenColor: Vector4, thickness: float):
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
		Color(chosenColor.x, chosenColor.y, chosenColor.z, thickness) #we don't care about the w value so this can be used to store the thickness
	)
	
	sdfSSLocation_tex.set_image(sdfSSLocation)
	sdfSSColor_tex.set_image(sdfSSColor)
	
	
	

func _ready():
	
	$MeshInstance2D_512.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1) 
	
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentThickness", segmentThickness)
	%Label_thickness.text = str(segmentThickness)
	
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
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		mousePositionPlaceholder_release = get_viewport().get_mouse_position()
		$SubViewport_5/MeshInstance2D.material.set_shader_parameter("currentClickPosition", mousePosition_click)
		$SubViewport_5/MeshInstance2D.material.set_shader_parameter("currentMousePosition", mousePositionPlaceholder_release)
		$SubViewport_5/MeshInstance2D.material.set_shader_parameter("isMouseHeld", 1)
		$SubViewport_5/MeshInstance2D.material.set_shader_parameter("currentSelectedColor", currentSelectedColor)
		#print(mousePositionPlaceholder_release)
	else:
		$SubViewport_5/MeshInstance2D.material.set_shader_parameter("isMouseHeld", 0)
	
	if Input.is_action_just_released("click"):
		bool_mouseClickIsReleased = false
		mousePosition_release = get_viewport().get_mouse_position()
		bool_needToGenerateNewLineSDFfromInputs = true
		print(mousePosition_release)
		print ("\n --- \n")
	
	if bool_needToGenerateNewLineSDFfromInputs == true:
		addValueToTextureArray(currentArrayInex, mousePosition_click, mousePosition_release, currentSelectedColor, segmentThickness)
		currentArrayInex = currentArrayInex + 1
		bool_needToGenerateNewLineSDFfromInputs = false
	
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentLocationCoords_tex", sdfSSLocation_tex)
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentColors_tex", sdfSSColor_tex)
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("arrayLargestIndex", currentArrayInex)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
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

func activateRenderQuadWithResolution(res: int, tex: Texture):
	if res == 512:
		$MeshInstance2D_512.visible = true
		$MeshInstance2D_1024.visible = false
		$MeshInstance2D_512.material.set_shader_parameter("src_tex", tex)
	elif res == 1024:
		$MeshInstance2D_512.visible = false
		$MeshInstance2D_1024.visible = true
		$MeshInstance2D_1024.material.set_shader_parameter("src_tex", tex)
	else: 
		#assume 512 res is the default
		$MeshInstance2D_512.visible = true
		$MeshInstance2D_1024.visible = false
		$MeshInstance2D_512.material.set_shader_parameter("src_tex", tex)

func _on_option_button_item_selected(index):
	if index == 0: #test shader
		fullScreenQuadTexture_1 = $SubViewport_1.get_texture()
		#$MeshInstance2D_512.material.set_shader_parameter("src_tex", fullScreenQuadTexture_1)
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 1: #circle RT
		fullScreenQuadTexture_1 = $SubViewport_2.get_texture()
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 2: #Grid Display
		fullScreenQuadTexture_1 = $SubViewport_3.get_texture()
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 3: #SDF
		fullScreenQuadTexture_1 = $SubViewport_4.get_texture()
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 4: #Drawing with SDFs
		fullScreenQuadTexture_1 = $PingPongRoot/SubViewport_A.get_texture()
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 5: #Drawing Segments
		fullScreenQuadTexture_1 = $SubViewport_5.get_texture()
		activateRenderQuadWithResolution(512, fullScreenQuadTexture_1)
	elif index == 6: #cascade level 5
		fullScreenQuadTexture_1 = $SubViewport_CL_4.get_texture()
		activateRenderQuadWithResolution(1024, fullScreenQuadTexture_1)


func _on_h_slider_segment_thickness_value_changed(value):
	%Label_thickness.text = str(value)
	segmentThickness = value
	$SubViewport_5/MeshInstance2D.material.set_shader_parameter("segmentThickness", segmentThickness)


func _on_color_picker_button_color_changed(color):
	currentSelectedColor = Vector4(color.r, color.g, color.b, segmentThickness)
