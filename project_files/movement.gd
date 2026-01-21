extends CharacterBody3D

# Ustawienia prędkości
@export var move_speed: float = 3.0
@export var deadzone: float = 0.2

# UWAGA: Te ścieżki zakładają, że XROrigin3D jest dzieckiem Playera (tak jak ustaliliśmy)
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

func _physics_process(_delta: float) -> void:
	# 1. Sprawdzamy czy kontroler istnieje
	if not left_controller:
		return

	# 2. Pobieramy input z gałki (obsługa thumbstick i primary)
	var input_vector = left_controller.get_vector2("thumbstick")
	if input_vector.length() == 0:
		input_vector = left_controller.get_vector2("primary")
	
	# 3. Martwa strefa (jeśli nie ruszasz gałką - zatrzymaj się)
	if input_vector.length() < deadzone:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	# 4. Obliczamy kierunki względem kamery
	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x

	# Blokada latania (ignorujemy oś Y)
	forward_dir.y = 0.0
	right_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	right_dir = right_dir.normalized()

	# 5. Obliczamy wektor ruchu
	var direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)

	# 6. Aplikujemy prędkość do fizycznego ciała
	if direction.length() > 0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0
		velocity.z = 0

	# 7. Wykonujemy ruch (TO TA FUNKCJA BLOKUJE PRZECHODZENIE PRZEZ ŚCIANY)
	#move_and_slide()
	# ... (reszta kodu bez zmian) ...
	
	# 7. Wykonujemy ruch
	var collision_happened = move_and_slide()
	
	# DEBUG KOLIZJI
	if collision_happened:
		print("KOLIZJA! Uderzyłem w ścianę!")
