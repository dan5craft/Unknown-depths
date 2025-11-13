extends Camera3D

@export var speed : float = 0.1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Up"):
		position.y += speed
	if Input.is_action_pressed("Down"):
		position.y -= speed
	if Input.is_action_pressed("Forward"):
		global_position += Vector3.FORWARD*global_transform.basis.inverse()*speed;
	if Input.is_action_pressed("Back"):
		global_position -= Vector3.FORWARD*global_transform.basis.inverse()*speed;
	if Input.is_action_pressed("Left"):
		global_position += Vector3.LEFT*global_transform.basis.inverse()*speed;
	if Input.is_action_pressed("Right"):
		global_position -= Vector3.LEFT*global_transform.basis.inverse()*speed;
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate(Vector3.UP, -event.relative.x*0.001)
		rotate(Vector3.LEFT*transform.basis.inverse(), event.relative.y*0.001)
