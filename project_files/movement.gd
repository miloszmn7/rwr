extends XROrigin3D

@export var move_speed: float = 2.5
@export var deadzone: float = 0.2

# Upewnij się, że te nazwy pasują do drzewa sceny!
@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController 

func _ready() -> void:
	print("--- LOCOMOTION SCRIPT READY ---")
	if left_controller:
		print("Lewy kontroler znaleziony!")
	else:
		print("BŁĄD: Nie widzę LeftController!")

func _physics_process(delta: float) -> void:
	if not left_controller:
		return
		
	# Sprawdzamy surowe dane z gałki
	var input_vector = left_controller.get_vector2("thumbstick")
	
	# DEBUG: Pokaż w konsoli, jeśli gałka cokolwiek nadaje
	if input_vector.length() > 0.1:
		print("Gałka nadaje: ", input_vector)
	
	if input_vector.length() < deadzone:
		return

	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x
	
	# Spłaszczanie (blokada latania)
	forward_dir.y = 0.0
	right_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	right_dir = right_dir.normalized()
	
	var move_direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)
	
	if move_direction.length() > 0:
		# DEBUG: Pokaż, że próbujemy przesunąć gracza
		# print("Przesuwam gracza!") 
		global_translate(move_direction * move_speed * delta)
