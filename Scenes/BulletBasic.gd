extends KinematicBody2D

export (float) var Speed = 300
export (Vector2) var Direction = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var speed = Speed * Direction.normalized()
	move_and_slide(speed)
	
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
	
