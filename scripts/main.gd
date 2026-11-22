extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const CarScript = preload("res://scripts/car.gd")
var player: PlayerController
var car: DrivableCar
var active_car: DrivableCar
var cash := 0
var wanted := 0
var mission_done := false
var mission_position := Vector3(18, 0, -18)
var hud_label: Label
var help_label: Label
var mission_marker: MeshInstance3D

func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_city()
	_build_mission()
	_spawn_player_and_car()
	_build_hud()

func _setup_input() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("run", KEY_SHIFT)
	_add_key("interact", KEY_E)
	_add_key("brake", KEY_SPACE)
	_add_key("wanted", KEY_F)

func _add_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.28, 0.48)
	sky_material.sky_horizon_color = Color(0.72, 0.78, 0.82)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.8
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

func _build_city() -> void:
	_add_static_box(Vector3(0, -0.35, 0), Vector3(220, 0.5, 220), Color(0.18, 0.34, 0.19))
	# Grid of asphalt streets and city blocks.
	for i in range(-3, 4):
		var road_x := float(i) * 30.0
		_add_visual_box(Vector3(road_x, -0.04, 0), Vector3(11, 0.12, 220), Color(0.105, 0.115, 0.13))
		var road_z := float(i) * 30.0
		_add_visual_box(Vector3(0, -0.035, road_z), Vector3(220, 0.12, 11), Color(0.105, 0.115, 0.13))
		_add_visual_box(Vector3(road_x + 6.3, 0.02, 0), Vector3(1.2, 0.18, 220), Color(0.48, 0.46, 0.39))
		_add_visual_box(Vector3(0, 0.02, road_z + 6.3), Vector3(220, 0.18, 1.2), Color(0.48, 0.46, 0.39))

	var colors := [Color(0.55,0.48,0.39), Color(0.38,0.47,0.55), Color(0.62,0.57,0.48), Color(0.34,0.39,0.43), Color(0.58,0.42,0.34)]
	for x in range(-3, 3):
		for z in range(-3, 3):
			var center := Vector3(x * 30.0 + 15.0, 0, z * 30.0 + 15.0)
			var h := float(9 + ((x * 7 + z * 11 + 30) % 5) * 4)
			var w := 9.0 + float((x + z + 8) % 3) * 2.0
			var d := 9.0 + float((x * 2 - z + 12) % 3) * 2.0
			_add_static_box(center + Vector3(0, h * 0.5, 0), Vector3(w, h, d), colors[abs(x * 3 + z * 5) % colors.size()])
			# A rooftop block gives the skyline a little variation.
			if (x + z) % 3 == 0:
				_add_static_box(center + Vector3(0, h + 1.2, 0), Vector3(w * 0.42, 2.4, d * 0.42), Color(0.24, 0.27, 0.3))

func _add_visual_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _add_static_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_mission() -> void:
	mission_marker = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.5
	mesh.bottom_radius = 1.5
	mesh.height = 0.18
	mission_marker.mesh = mesh
	mission_marker.position = mission_position + Vector3(0, 0.18, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.9, 0.65)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.8, 0.45)
	mission_marker.material_override = material
	add_child(mission_marker)

func _spawn_player_and_car() -> void:
	player = PlayerScript.new()
	player.position = Vector3(0, 1, 4)
	add_child(player)
	car = CarScript.new()
	car.position = Vector3(5, 0.8, 4)
	car.rotation.y = PI / 2
	add_child(car)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.015, 0.025, 0.04, 0.72)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(420, 118)
	layer.add_child(panel)
	hud_label = Label.new()
	hud_label.position = Vector2(32, 27)
	hud_label.add_theme_font_size_override("font_size", 19)
	panel.add_child(hud_label)
	help_label = Label.new()
	help_label.position = Vector2(20, 650)
	help_label.text = "WASD mover  |  SHIFT correr  |  E entrar/sair do carro  |  ESPACO frear  |  F nivel de procurado  |  ESC liberar mouse"
	help_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(help_label)
	var signature := Label.new()
	signature.text = "CIDADE LIVRE 3D  •  Um projeto original de Victor, com código e assinatura de ChatGPT (GPT-6)"
	signature.position = Vector2(20, 128)
	signature.add_theme_font_size_override("font_size", 12)
	signature.add_theme_color_override("font_color", Color(0.8, 0.86, 0.9))
	layer.add_child(signature)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_toggle_vehicle()
	if Input.is_action_just_pressed("wanted"):
		wanted = mini(wanted + 1, 5)
	if not mission_done:
		var target := active_car.global_position if active_car else player.global_position
		if target.distance_to(mission_position) < 3.2:
			mission_done = true
			cash += 500
			mission_marker.visible = false
	var stars := "★".repeat(wanted) + "☆".repeat(5 - wanted)
	hud_label.text = "DINHEIRO  $%d\nPROCURADO  %s\nOBJETIVO  %s" % [cash, stars, "Concluido (+$500)" if mission_done else "Encontre o marcador verde"]
	if active_car:
		player.global_position = active_car.global_position + Vector3(0, 0.1, 0)

func _toggle_vehicle() -> void:
	if active_car:
		player.global_position = active_car.global_position + active_car.global_basis.x * 2.4 + Vector3(0, 0.3, 0)
		player.visible = true
		player.active = true
		active_car.driving = false
		active_car = null
		return
	if player.global_position.distance_to(car.global_position) <= 4.0:
		active_car = car
		player.active = false
		player.visible = false
		car.driving = true
