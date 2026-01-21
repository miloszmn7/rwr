extends CharacterBody3D

@export var move_speed: float = 3.0
@export var deadzone: float = 0.2

# Ścieżki (zgodne z Twoim setupem)
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

func _physics_process(delta: float) -> void:
	# --- 1. AUTO-CENTROWANIE (NAPRAWA KOLIZJI W VR) ---
	# Sprawdzamy, czy głowa (kamera) nie uciekła od środka gracza
	_recenter_character()

	# --- 2. INPUT (VR + Klawiatura) ---
	var input_vector = Vector2.ZERO

	if left_controller:
		input_vector = left_controller.get_vector2("thumbstick")
		if input_vector.length() == 0:
			input_vector = left_controller.get_vector2("primary")

	# Input z klawiatury (jeśli VR nic nie nadaje)
	if input_vector.length() < deadzone:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector.length() < deadzone:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	# --- 3. OBLICZANIE KIERUNKU ---
	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x

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

	# --- 4. RUCH FIZYCZNY ---
	move_and_slide()

# --- NOWA FUNKCJA MAGICZNA ---
# Ta funkcja przesuwa Ciało (CharacterBody) w miejsce gdzie stoi głowa,
# a potem przesuwa Origin w przeciwną stronę, żebyś wizualnie tego nie poczuł.
func _recenter_character() -> void:
	# 1. Obliczamy pozycje w świecie (Global), ignorując wysokość (Y)
	var head_global_pos = xr_camera.global_position
	var body_global_pos = global_position
	
	# Spłaszczamy do 2D (podłoga)
	var diff = head_global_pos - body_global_pos
	diff.y = 0.0
	
	# 2. Jeśli przesunięcie jest minimalne, nic nie rób (zapobiega drganiu)
	if diff.length() < 0.05: # Tolerancja 5 cm
		return
		
	# 3. Przesuwamy Ciało (Kapsułę) pod Głowę
	global_position += diff
	
	# 4. Przesuwamy Origin w przeciwną stronę, żeby kamera optycznie została w miejscu
	xr_origin.global_position -= diff
