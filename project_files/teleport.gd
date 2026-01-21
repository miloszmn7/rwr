extends XRController3D

@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var is_aiming := false
const DEADZONE = 0.2

func _ready() -> void:
    xr_origin = get_parent() as XROrigin3D
    xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
    
    marker.visible = false
    ray.enabled = false 
    
    # --- WYMUSZENIE USTAWIEŃ (NUCLEAR OPTION) ---
    # To naprawia błąd ludzki w inspektorze.
    # Ustawiamy maskę kolizji na 1 (binarnie: 0001). 
    # To oznacza: "Widzę TYLKO obiekty z Layer 1".
    ray.collision_mask = 1 
    # Jeśli Twoja podłoga jest na Layer 1, a obiekty na Layer 2, 
    # to laser fizycznie PRZELECI przez obiekty.

func _process(_delta: float) -> void:
    var input_vector = get_vector2("thumbstick")
    
    # --- CELOWANIE ---
    if input_vector.length() > DEADZONE:
        if not is_aiming:
            is_aiming = true
            ray.enabled = true 
        
        if ray.is_colliding():
            var collider = ray.get_collider()
            var normal = ray.get_collision_normal()
            
            # DEBUGGER PRAWDY
            # Jeśli celujesz w skrzynię i widzisz znacznik, 
            # spójrz w konsolę ("Output"). Jeśli wypisze nazwę skrzyni,
            # to znaczy, że skrzynia MA włączony Layer 1.
            # print("Celuję w: ", collider.name) 
            
            # Sprawdzamy kąt (dla pewności, żeby nie wchodzić na ściany granic)
            if normal.dot(Vector3.UP) > 0.85:
                marker.visible = true
                marker.global_position = ray.get_collision_point()
                marker.global_rotation = Vector3.ZERO
            else:
                marker.visible = false
        else:
            marker.visible = false
            
    # --- SKOK ---
    elif is_aiming:
        is_aiming = false
        marker.visible = false
        
        if ray.is_colliding():
            var normal = ray.get_collision_normal()
            # Pozwól na skok TYLKO na płaskie
            if normal.dot(Vector3.UP) > 0.85:
                teleport_now()
        
        ray.enabled = false

func teleport_now() -> void:
    var target = ray.get_collision_point()
    var origin_tf := xr_origin.global_transform
    var cam_tf := xr_camera.global_transform
    
    var cam_offset := cam_tf.origin - origin_tf.origin
    cam_offset.y = 0.0
    
    origin_tf.origin = Vector3(target.x - cam_offset.x, target.y, target.z - cam_offset.z)
    xr_origin.global_transform = origin_tf
