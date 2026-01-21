extends XRController3D

@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D

func _ready() -> void:

	xr_origin = get_parent() as XROrigin3D
	xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
	marker.visible = false
	
	# TEGO BRAKOWAŁO W INSTRUKCJI: Musimy nasłuchiwać kliknięcia!
	# Podpinamy sygnał wciśnięcia przycisku na tym kontrolerze
	#button_pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:

	if ray.is_colliding():
		marker.global_transform.origin = ray.get_collision_point()
		marker.visible = true
	else:
		marker.visible = false


func _on_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click": # Reagujemy na spust
		teleport_now()

func teleport_now() -> void:

	if not ray.is_colliding():
		return
		
	var target = ray.get_collision_point()
	var origin_tf := xr_origin.global_transform
	var cam_tf := xr_camera.global_transform
	
	var cam_offset := cam_tf.origin - origin_tf.origin
	
	cam_offset.y = 0.0
	
	origin_tf.origin = Vector3(target.x - cam_offset.x, target.y, target.z - cam_offset.z)
	
	xr_origin.global_transform = origin_tf
