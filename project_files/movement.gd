extends CharacterBody3D

@export var move_speed: float = 3.0
@export var deadzone: float = 0.2

# Ścieżki do dzieci (zgodne z Twoim obrazkiem)
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO

	# --- 1. PRÓBA ODCZYTU Z VR (Dla gogli) ---
	if left_controller:
		input_vector = left_controller.get_vector2("thumbstick")
		if input_vector.length() == 0:
			input_vector = left_controller.get_vector2("primary")

	# --- 2. PRÓBA ODCZYTU Z KLAWIATURY (Dla PC/Debugowania) ---
	# Jeśli VR nic nie nadaje (bo testujesz na F5), użyj strzałek/WASD
	if input_vector.length() < deadzone:
		# "ui_up", "ui_down" itd. to wbudowane mapy klawiszy w Godot (Strzałki)
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Martwa strefa (dotyczy też klawiatury, żeby nie drgało)
	if input_vector.length() < deadzone:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	# --- 3. LOGIKA KIERUNKU (Ta sama co wcześniej) ---
	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x

	# Blokada latania
	forward_dir.y = 0.0
	right_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	right_dir = right_dir.normalized()

	var direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)

	if direction.length() > 0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0
		velocity.z = 0

	# --- 4. RUCH I KOLIZJA ---
	move_and_slide()
