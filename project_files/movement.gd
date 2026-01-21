extends CharacterBody3D

@export var move_speed: float = 3.0
@export var deadzone: float = 0.3 

# Ścieżki do wnętrza gracza
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
# Ruch zazwyczaj jest na Lewym Kontrolerze
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

# Referencje do kolizji (do centrowania)
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
# Jeśli dodałeś czerwony walec, wpisz tu jego nazwę (np. MeshInstance3D)
@onready var body_mesh: MeshInstance3D = $MeshInstance3D 

func _physics_process(_delta: float) -> void:
	# 1. INPUT (VR + Klawiatura)
	var input_vector = Vector2.ZERO
	if left_controller:
		input_vector = left_controller.get_vector2("thumbstick")
		# Obsługa alternatywnej nazwy osi (dla pewności)
		if input_vector.length() == 0:
			input_vector = left_controller.get_vector2("primary")

	# Obsługa klawiatury (jeśli nie masz gogli na głowie)
	if input_vector.length() < deadzone:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. RUCH I HAMOWANIE
	if input_vector.length() < deadzone:
		# Hamowanie (tarcie)
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		# Obliczanie kierunku wg patrzenia kamery
		var forward_dir = -xr_camera.global_transform.basis.z
		var right_dir = xr_camera.global_transform.basis.x
		
		# Spłaszczanie (blokada latania)
		forward_dir.y = 0.0
		right_dir.y = 0.0
		forward_dir = forward_dir.normalized()
		right_dir = right_dir.normalized()
		
		var direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)
		
		if direction.length() > 0:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed

	# 3. FIZYKA (Przesuwa CharacterBody3D)
	move_and_slide()
	
	# 4. AUTO-CENTROWANIE (Najważniejsza poprawka)
	# Przesuwamy kapsułę pod głowę, ale NIE ruszamy Origina
	_recenter_collider_only()

func _recenter_collider_only() -> void:
	# Gdzie jest głowa w przestrzeni lokalnej gracza?
	var head_local_pos = to_local(xr_camera.global_position)
	
	# Ignorujemy wysokość głowy, interesuje nas podłoga (X, Z)
	# 0.9 to środek wysokości kapsuły (dla kapsuły 1.8m)
	var target_pos = Vector3(head_local_pos.x, 0.9, head_local_pos.z)
	
	# Przesuwamy elementy fizyczne i graficzne
	if collision_shape:
		collision_shape.position = target_pos
	if body_mesh:
		body_mesh.position = target_pos
