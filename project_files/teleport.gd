extends XRController3D

@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var is_aiming := false  # Flaga: czy aktualnie celujemy?

# Ustawienia czułości
const DEADZONE = 0.5  # Jak mocno trzeba wychylić gałkę (0.0 - 1.0), żeby włączyć laser

func _ready() -> void:
	xr_origin = get_parent() as XROrigin3D
	xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
	
	# Na starcie ukrywamy i wyłączamy wszystko
	marker.visible = false
	ray.enabled = false 

func _process(_delta: float) -> void:
	# Pobieramy wektor wychylenia gałki (x, y)
	var input_vector = get_vector2("thumbstick")
	
	# Sprawdzamy, czy gałka jest wychylona do przodu (oś Y ujemna to góra w Godot VR)
	# Używamy długości wektora, żeby działało też lekko na boki
	if input_vector.length() > DEADZONE:
		# --- STAN CELOWANIA ---
		is_aiming = true
		ray.enabled = true # Włączamy laser tylko gdy celujesz (oszczędność mocy)
		
		if ray.is_colliding():
			marker.visible = true
			marker.global_transform.origin = ray.get_collision_point()
		else:
			marker.visible = false
			
	elif is_aiming:
		# --- MOMENT PUSZCZENIA GAŁKI (TELEPORTACJA) ---
		is_aiming = false
		marker.visible = false
		ray.enabled = false
		
		# Wykonaj teleport tylko jeśli laser w coś trafiał w momencie puszczenia
		if ray.is_colliding():
			teleport_now()
	else:
		# --- STAN SPOCZYNKU ---
		marker.visible = false
		ray.enabled = false

func teleport_now() -> void:
	var target = ray.get_collision_point()
	var origin_tf := xr_origin.global_transform
	var cam_tf := xr_camera.global_transform
	var cam_offset := cam_tf.origin - origin_tf.origin
	
	# Stabilizacja wysokości (Twój kod z 4.2.B)
	cam_offset.y = 0.0
	origin_tf.origin = Vector3(target.x - cam_offset.x, target.y, target.z - cam_offset.z)
	
	xr_origin.global_transform = origin_tf
