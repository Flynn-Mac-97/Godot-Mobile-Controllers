extends Control

var joystick_origin = Vector2()
@onready var joystick = $Backdrop/Joystick
var dragging = false
var movement_vector = Vector2()
var max_drag_distance = 50  # Maximum radius from the origin the joystick can move.

signal moving_joystick_position_as_int(x: int, y: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	joystick_origin = joystick.position
	TickManager.tick.connect(emit_joystick_signal)

func _gui_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
			move_joystick_to(event.position)
		else:
			dragging = false
			reset_joystick_position()
	elif dragging and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		move_joystick_to(event.position)
		update_movement_vector(joystick.position - joystick_origin)  # Update using the actual joystick position.

func move_joystick_to(position):
	var offset_position = position - joystick_origin - joystick.size * 0.5
	var displacement = offset_position - joystick_origin
	if displacement.length() > max_drag_distance:
		displacement = displacement.normalized() * max_drag_distance
	joystick.position = joystick_origin + displacement  # Adjust this line to set the joystick's position within the drag zone.

func reset_joystick_position():
	joystick.position = joystick_origin
	movement_vector = Vector2()  # Reset movement vector when joystick is released.
	
func update_movement_vector(displacement):
	movement_vector = displacement.normalized()
	#print(movement_vector)

func emit_joystick_signal():
	#for networking use the integer representation
	if(dragging):
		moving_joystick_position_as_int.emit(quantize(movement_vector.x), quantize(movement_vector.y))	
	
func quantize(value: float) -> int:
	return int(clamp(value * 100, -100, 100))
