extends CharacterBody3D
class_name PlayerController

@export var walk_speed := 6.0
@export var run_speed := 10.5
@export var mouse_sensitivity := 0.0025
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var active := true
var camera_pivot: Node3D

func _ready() -> void:
	_build_character()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_character() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = capsule
	visual.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.28, 0.72)
	visual.material_override = material
	add_child(visual)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.55
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.0, 6.0)
	camera.rotation.x = deg_to_rad(-14.0)
	camera.current = true
	camera_pivot.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-55), deg_to_rad(35))
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (camera_pivot.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	direction = direction.normalized()
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed
	if direction.length() > 0.01:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
		visual_face(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 8.0 * delta)
	move_and_slide()

func visual_face(direction: Vector3) -> void:
	var visual := get_node_or_null("Visual")
	if visual:
		visual.rotation.y = atan2(direction.x, direction.z)
