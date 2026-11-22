extends CharacterBody3D
class_name DrivableCar

var speed := 0.0
var max_speed := 32.0
var acceleration := 20.0
var braking := 34.0
var steering := 1.7
var driving := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	_build_car()

func _build_car() -> void:
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.0, 0.75, 4.0)
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.position.y = 0.75
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.78, 0.12, 0.08)
	paint.metallic = 0.45
	paint.roughness = 0.28
	body.material_override = paint
	add_child(body)

	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.65, 0.7, 1.8)
	var cabin := MeshInstance3D.new()
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 1.42, -0.15)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.08, 0.16, 0.2, 0.78)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin.material_override = glass
	add_child(cabin)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.4, 4.0)
	collision.shape = shape
	collision.position.y = 0.8
	add_child(collision)

	for x in [-0.88, 0.88]:
		for z in [-1.35, 1.35]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.38
			wheel_mesh.bottom_radius = 0.38
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(x, 0.4, z)
			wheel.rotation.z = PI / 2
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color(0.035, 0.035, 0.04)
			wheel.material_override = rubber
			add_child(wheel)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	if driving:
		var throttle := Input.get_axis("move_back", "move_forward")
		if Input.is_action_pressed("brake"):
			speed = move_toward(speed, 0.0, braking * delta)
		else:
			speed = move_toward(speed, throttle * max_speed, acceleration * delta)
		var steer_input := Input.get_axis("move_left", "move_right")
		if abs(speed) > 0.4:
			rotation.y -= steer_input * steering * delta * clamp(abs(speed) / 8.0, 0.25, 1.0) * sign(speed)
		velocity.x = -global_basis.z.x * speed
		velocity.z = -global_basis.z.z * speed
	else:
		speed = move_toward(speed, 0.0, 8.0 * delta)
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
