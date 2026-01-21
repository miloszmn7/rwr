extends XROrigin3D

# Ustawienia prędkości (zalecam małe wartości na start)
@export var move_speed: float = 2.5
@export var deadzone: float = 0.2

# Referencje do dzieci XROrigin (upewnij się, że nazwy w drzewie są takie same!)
@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController 

func _physics_process(delta: float) -> void:
	# 1. Pobieramy wychylenie lewej gałki
	# "thumbstick" zwraca wektor Vector2 (x, y), gdzie y to przód/tył
	var input_vector = left_controller.get_vector2("thumbstick")
	
	# Martwa strefa - jeśli drgania są zbyt małe, ignorujemy je
	if input_vector.length() < deadzone:
		input_vector = Vector2.ZERO
		return # Szkoda mocy obliczeniowej, przerywamy

	# 2. Pobieramy kierunki, w które patrzy gracz
	# basis.z to przód, basis.x to prawo
	var forward_dir = -xr_camera.global_transform.basis.z
	var right_dir = xr_camera.global_transform.basis.x
	
	# --- KLUCZOWE ZABEZPIECZENIE (z Twojej instrukcji 5.2) ---
	# Spłaszczamy wektory, żeby ignorowały góra/dół. 
	# Dzięki temu jak patrzysz w niebo i idziesz do przodu, nie wylecisz w powietrze.
	forward_dir.y = 0.0
	right_dir.y = 0.0
	
	# Normalizujemy, żeby ruch po skosie nie był szybszy
	forward_dir = forward_dir.normalized()
	right_dir = right_dir.normalized()
	
	# 3. Obliczamy finalny wektor przesunięcia
	# input_vector.y odpowiada za przód/tył (dlatego mnożymy z forward_dir)
	# input_vector.x odpowiada za boki (dlatego mnożymy z right_dir)
	var move_direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)
	
	# 4. Przesuwamy XROrigin
	if move_direction.length() > 0:
		global_translate(move_direction * move_speed * delta)
