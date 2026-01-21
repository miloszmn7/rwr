extends Node3D

var webxr_interface

func _ready() -> void:
	# Ukrywamy Canvas na start (opcjonalne, zależy od Twojej sceny)
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = false
		if $CanvasLayer.has_node("Button"):
			$CanvasLayer/Button.pressed.connect(self._on_button_pressed)

	webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		# Podłączamy sygnały stanu sesji WebXR
		webxr_interface.session_supported.connect(self._webxr_session_supported)
		webxr_interface.session_started.connect(self._webxr_session_started)
		webxr_interface.session_ended.connect(self._webxr_session_ended)
		webxr_interface.session_failed.connect(self._webxr_session_failed)

		# Sygnały inputu (chwytanie, ściskanie)
		webxr_interface.select.connect(self._webxr_on_select)
		webxr_interface.selectstart.connect(self._webxr_on_select_start)
		webxr_interface.selectend.connect(self._webxr_on_select_end)
		webxr_interface.squeeze.connect(self._webxr_on_squeeze)
		webxr_interface.squeezestart.connect(self._webxr_on_squeeze_start)
		webxr_interface.squeezeend.connect(self._webxr_on_squeeze_end)

		# Sprawdzamy wsparcie VR
		webxr_interface.is_session_supported("immersive-vr")

	# --- ZAKTUALIZOWANE ŚCIEŻKI DO KONTROLERÓW (TERAZ SĄ W PLAYERZE) ---
	# Upewnij się, że w drzewie sceny masz: Main -> Player -> XROrigin3D -> LeftController
	var left_controller = $Player/XROrigin3D/LeftController
	if left_controller:
		left_controller.button_pressed.connect(self._on_left_controller_button_pressed)
		left_controller.button_released.connect(self._on_left_controller_button_released)

func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == 'immersive-vr':
		if supported and has_node("CanvasLayer"):
			$CanvasLayer.visible = true
		elif not supported:
			OS.alert("Your browser doesn't support VR")

func _on_button_pressed() -> void:
	# Konfiguracja i start VR
	webxr_interface.session_mode = 'immersive-vr'
	webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	webxr_interface.required_features = 'local-floor'
	webxr_interface.optional_features = 'bounded-floor'

	if not webxr_interface.initialize():
		OS.alert("Failed to initialize WebXR")

func _webxr_session_started() -> void:
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = false
	get_viewport().use_xr = true
	print("Reference space type: " + webxr_interface.reference_space_type)

func _webxr_session_ended() -> void:
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = true
	get_viewport().use_xr = false

func _webxr_session_failed(message: String) -> void:
	OS.alert("Failed to initialize: " + message)

# --- Obsługa przycisków kontrolera ---
func _on_left_controller_button_pressed(button: String) -> void:
	print("Button pressed: " + button)

func _on_left_controller_button_released(button: String) -> void:
	print("Button release: " + button)

func _process(_delta: float) -> void:
	# Tutaj nie umieszczamy ruchu! Ruch jest w skrypcie movement.gd na Playerze.
	pass

# --- Pozostałe funkcje WebXR (wymagane przez sygnały) ---
func _webxr_on_select(input_source_id: int) -> void: print("Select: " + str(input_source_id))
func _webxr_on_select_start(input_source_id: int) -> void: print("Select Start: " + str(input_source_id))
func _webxr_on_select_end(input_source_id: int) -> void: print("Select End: " + str(input_source_id))
func _webxr_on_squeeze(input_source_id: int) -> void: print("Squeeze: " + str(input_source_id))
func _webxr_on_squeeze_start(input_source_id: int) -> void: print("Squeeze Start: " + str(input_source_id))
func _webxr_on_squeeze_end(input_source_id: int) -> void: print("Squeeze End: " + str(input_source_id))
