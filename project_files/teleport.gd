extends XRController3D

# Upewnij się, że masz te węzły jako dzieci kontrolera!
@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var is_aiming := false
const DEADZONE = 0.2

func _ready() -> void:
    xr_origin = get_parent() as XROrigin3D
    xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
    
    # Start: ukryte
    marker.visible = false
    ray.enabled = false 

func _process(_delta: float) -> void:
    var input_vector = get_vector2("thumbstick")
    
    # --- STAN 1: CELOWANIE ---
    if input_vector.length() > DEADZONE:
        if not is_aiming:
            is_aiming = true
            ray.enabled = true 
        
        if ray.is_colliding():
            var normal = ray.get_collision_normal()
            
            # ZABEZPIECZENIE: Czy celujemy w płaską podłogę?
            # Kąt > 0.85 oznacza powierzchnię poziomą. Ściany mają ok. 0.0.
            if normal.dot(Vector3.UP) > 0.85:
                marker.visible = true
                marker.global_position = ray.get_collision_point()
                # Znacznik zawsze płasko na ziemi
                marker.global_rotation = Vector3.ZERO
            else:
                # Trafiliśmy w ścianę -> Nie pokazuj znacznika
                marker.visible = false
        else:
            marker.visible = false
            
    # --- STAN 2: SKOK (PUSZCZENIE GAŁKI) ---
    elif is_aiming:
        is_aiming = false
        marker.visible = false
        
        # Wykonaj skok tylko jeśli laser widzi PŁASKĄ PODŁOGĘ
        if ray.is_colliding():
            var normal = ray.get_collision_normal()
            if normal.dot(Vector3.UP) > 0.85:
                teleport_now()
        
        ray.enabled = false

func teleport_now() -> void:
    var target = ray.get_collision_point()
    var origin_tf := xr_origin.global_transform
    var cam_tf := xr_camera.global_transform
    
    # Obliczamy przesunięcie, żeby wylądować stopami w celu, a nie środkiem pokoju
    var cam_offset := cam_tf.origin - origin_tf.origin
    cam_offset.y = 0.0
    
    origin_tf.origin = Vector3(target.x - cam_offset.x, target.y, target.z - cam_offset.z)
    xr_origin.global_transform = origin_tf
