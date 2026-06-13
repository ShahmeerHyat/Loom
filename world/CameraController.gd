extends Camera2D

## CameraController — pan and zoom for the top-down world view.
##
## Pure presentation: isolated, talks to no other component. Reads input
## directly (mouse + physical keys) so it needs no Input Map entries.
##
## Controls:
##   - Mouse wheel        : zoom in / out (clamped)
##   - Middle-mouse drag  : pan
##   - WASD / arrow keys  : pan

@export var zoom_min: float = 0.5
@export var zoom_max: float = 3.0
@export var zoom_step: float = 1.1
@export var keyboard_pan_speed: float = 600.0  # px/sec on screen at any zoom

var _dragging: bool = false


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0

	if dir != Vector2.ZERO:
		# Divide by zoom so the on-screen pan speed feels the same at any zoom.
		position += dir.normalized() * keyboard_pan_speed * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(1.0 / zoom_step)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		# Drag moves the world under the cursor; scale by zoom to track 1:1.
		position -= event.relative / zoom.x


func _apply_zoom(factor: float) -> void:
	var new_zoom: float = clampf(zoom.x * factor, zoom_min, zoom_max)
	zoom = Vector2(new_zoom, new_zoom)
