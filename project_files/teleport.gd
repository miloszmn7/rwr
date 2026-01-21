extends XRController3D

# Referencje do węzłów (upewnij się, że nazwy w drzewie są identyczne: TeleportRay, TeleportMarker)
@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var is_aiming := false  # Flaga: czy aktualnie celujemy?

# Ustawienie czułości gałki
const DEADZONE = 0.2

func _ready() -> void:
	# Pobieramy XROrigin (rodzica kontrolera) i Kamerę
	xr_origin = get_parent() as XROrigin3D
	xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
	
	# Na starcie ukrywamy znacznik i wyłączamy laser (oszczędność wydajności)
	marker.visible = false
	ray.enabled = false 

func _process(_delta: float) -> void:
	# Pobieramy wychylenie gałki
	var input_vector = get_vector2("thumbstick")
	
	# --- 1. STAN CELOWANIA (Gdy wychylasz gałkę) ---
	if input_vector.length() > DEADZONE:
		if not is_aiming:
			print("Start celowania")
			is_aiming = true
			ray.enabled = true # Włączamy fizykę lasera
		
		# Aktualizacja pozycji znacznika
		if ray.is_colliding():
			marker.visible = true
			marker.global_transform.origin = ray.get_collision_point()
		else:
			marker.visible = false
			
	# --- 2. MOMENT PUSZCZENIA GAŁKI (Próba teleportacji) ---
	elif is_aiming:
		print("Puszczono gałkę - sprawdzam czy można skoczyć...")
		is_aiming = false
		marker.visible = false
		
		# NAJWAŻNIEJSZA ZMIANA: Sprawdzamy kolizję ZANIM wyłączymy laser
		if ray.is_colliding():
			print("Cel widoczny -> SKOK!")
			teleport_now()
		else:
			print("Brak celu -> Anulowanie skoku.")
		
		# Dopiero teraz wyłączamy laser
		ray.enabled = false

func teleport_now() -> void:
	var target = ray.get_collision_point()
	var origin_tf := xr_origin.global_transform
	var cam_tf := xr_camera.global_transform
	
	# Obliczamy przesunięcie gracza względem środka (XROrigin)
	var cam_offset := cam_tf.origin - origin_tf.origin
	
	# Stabilizacja wysokości (resetujemy Y, żeby nie zapadać się w podłogę)
	cam_offset.y = 0.0
	
	# Przesuwamy cały świat gracza w nowe miejsce
	origin_tf.origin = Vector3(target.x - cam_offset.x, target.y, target.z - cam_offset.z)
	
	xr_origin.global_transform = origin_tf
