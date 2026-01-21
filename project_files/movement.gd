extends CharacterBody3D

@export var move_speed: float = 3.0
@export var deadzone: float = 0.3 # Zwiększone dla bezpieczeństwa

# Ścieżki
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController

# Referencje do Twojego ciała (Kapsuła + Czerwony Walec)
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
# Jeśli nazwałeś czerwony walec "MeshInstance3D", zostaw tak. Jeśli inaczej, popraw nazwę!
@onready var body_mesh: MeshInstance3D = $MeshInstance3D 

func _physics_process(_delta: float) -> void:
	# 1. Input z kontrolerów
	var input_vector = Vector2.ZERO
	if left_controller:
		input_vector = left_controller.get_vector2("thumbstick")
		if input_vector.length() == 0:
			input_vector = left_controller.get_vector2("primary")

	# Input z klawiatury (PC Debug)
	if input_vector.length() < deadzone:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. Ruch i Hamowanie
	if input_vector.length() < deadzone:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		# Obliczanie kierunku ruchu
		var forward_dir = -xr_camera.global_transform.basis.z
		var right_dir = xr_camera.global_transform.basis.x
		
		# Spłaszczanie (żeby nie latać)
		forward_dir.y = 0.0
		right_dir.y = 0.0
		forward_dir = forward_dir.normalized()
		right_dir = right_dir.normalized()
		
		var direction = (forward_dir * input_vector.y) + (right_dir * input_vector.x)
		
		if direction.length() > 0:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed

	# 3. FIZYKA (To przesuwa gracza)
	move_and_slide()
	
	# 4. NOWE CENTROWANIE (Wywoływane PO ruchu fizyki)
	_recenter_collider_only()

# --- NOWA FUNKCJA (BEZ PĘTLI SPRZĘŻENIA) ---
func _recenter_collider_only() -> void:
	# Pobieramy pozycję kamery w przestrzeni lokalnej gracza
	# To nam mówi: "Gdzie jest głowa względem środka pokoju (0,0)?"
	var head_local_pos = to_local(xr_camera.global_position)
	
	# Interesuje nas tylko X i Z (podłoga)
	var target_pos = Vector3(head_local_pos.x, 0.9, head_local_pos.z) # 0.9 to wysokość środka kapsuły
	
	# Przesuwamy samą kapsułę kolizyjną w to miejsce
	if collision_shape:
		collision_shape.position = target_pos
		
	# Przesuwamy też czerwony walec, żebyś widział, gdzie jest ciało
	if body_mesh:
		body_mesh.position = target_pos
