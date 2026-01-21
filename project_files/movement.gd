extends CharacterBody3D

@export var move_speed: float = 3.0
@export var deadzone: float = 0.2

# Teraz XROrigin jest dzieckiem, więc ścieżki się zmieniają!
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

func _physics_process(_delta: float) -> void:
	# 1. Sprawdzamy kontroler
	if not left_controller:
		return
		
	var input_vector = left_controller.get_vector2("thumbstick")
	if input_vector.length() == 0:
		input_vector = left_controller.get_vector2("primary")
		
	# Martwa strefa
	if input_vector.length() < deadzone:
		velocity = Vector3.ZERO
		move_and_slide() # Zatrzymuje nas (tarcie)
		return

	# 2. Obliczamy kierunki wg kamery
	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x

	# Blokada latania (Y=0)
	forward_dir.y = 0.0
	right_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	right_dir = right_dir.normalized()

	# 3. Obliczamy kierunek ruchu
	var direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)

	# 4. Aplikujemy prędkość (Velocity)
	if direction.length() > 0:
		# W CharacterBody3D używamy velocity (metry/sekundę) bezpośrednio
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		# velocity.y zostawiamy 0 (lub dodamy grawitację w przyszłości)
	else:
		velocity.x = 0
		velocity.z = 0

	# 5. KLUCZOWA FUNKCJA FIZYCZNA
	# To ona odpowiada za przesuwanie i "ślizganie się" po ścianach
	move_and_slide()
