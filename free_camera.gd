extends Camera3D
class_name FreeCamera

@export var radial_blur: ColorRect

@export var mouse_sensitivity: float = 0.025

@export var base_speed: float = 7.5
@export var slow_speed: float = 2.5
@export var fast_speed: float = 20.0

@export var speed_gain: float = 5.0

var horizontal_input: Vector2
var vertical_input: float
var direction: Vector3

var speed: float
var speed_multiplier: float = 1.0

var velocity: Vector3

var forward_move_lerped: float

func _input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotation_degrees.x -= event.relative.y * mouse_sensitivity
			rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
			rotation_degrees.y -= event.relative.x * mouse_sensitivity
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_released():
			speed_multiplier += 0.1 * speed_multiplier
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_released():
			speed_multiplier -= 0.1 * speed_multiplier

func _process(delta: float) -> void:
	horizontal_input = Input.get_vector("left", "right", "forward", "backward")
	vertical_input = Input.get_axis("down", "up")
	direction = get_direction()
	
	speed = base_speed
	if Input.is_action_pressed("slow"):
		speed = slow_speed
	if Input.is_action_pressed("fast"):
		speed = fast_speed
	if Input.is_action_pressed("slow") and Input.is_action_pressed("fast"):
		speed = base_speed
	
	speed_multiplier = clamp(speed_multiplier, 0.25, 10.0)
	speed *= speed_multiplier
	
	velocity.x = lerp(velocity.x, direction.x * speed, speed_gain * delta)
	velocity.y = lerp(velocity.y, vertical_input * speed, speed_gain * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, speed_gain * delta)
	
	position += velocity * delta
	
	set_radial_blur_parameters()

func get_direction() -> Vector3:
	var forward = transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var right = transform.basis.x
	right.y = 0
	right = right.normalized()
	
	return (right * horizontal_input.x + forward * horizontal_input.y).normalized()

func set_radial_blur_parameters():
	var intensity: float
	var falloff: float
	var center: Vector2
	
	var velocity_speed: float = velocity.length() / speed_multiplier
	
	if velocity_speed <= 2.5:
		intensity = lerp(0.0, 0.25, velocity_speed / 2.5)
	elif velocity_speed <= 7.5:
		intensity = lerp(0.25, 0.5, (velocity_speed - 2.5) / (7.5 - 2.5))
	elif velocity_speed <= 20.0:
		intensity = lerp(0.5, 1.5, (velocity_speed - 7.5) / (20.0 - 7.5))
	else:
		intensity = 1.5
	
	var local_velocity_direction = to_local(global_position + velocity.normalized()) - to_local(global_position)
	
	forward_move_lerped = lerp(forward_move_lerped, -sign(local_velocity_direction.z -0.0001), 10.0 * get_process_delta_time())
	
	var intensity_falloff: float = lerp(0.25, 1.0, abs(local_velocity_direction.z))
	
	intensity *= forward_move_lerped * intensity_falloff
	
	falloff = min(
		abs(abs(local_velocity_direction.x) - 1.0),
		abs(abs(local_velocity_direction.y) - 1.0)
	)
	
	falloff *= clamp(-local_velocity_direction.z, 0.0, 1.0) * 0.5
	
	center = Vector2(local_velocity_direction.x * 0.5 + 0.5, -local_velocity_direction.y * 0.5 + 0.5)
	
	#print("Intensity: ", intensity)
	#print("Falloff: ", falloff)
	#print("Center: ", center * 2.0)
	
	#radial_blur.material.set_shader_parameter("intensity", intensity)
	#radial_blur.material.set_shader_parameter("falloff", falloff)
	radial_blur.material.set_shader_parameter("center", center)
