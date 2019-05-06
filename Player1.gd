extends KinematicBody2D

enum States {
	NONE,
	IDLE,
	IDLE_UP,
	GROUND,
	RUNNING,
	RUNNING_UP,
	RUNNING_DOWN,
	JUMPING
}

var speed = Vector2()
var can_jump = false
var on_the_ground = false
var state = States.IDLE

onready var anim = get_node("AnimationPlayer")

export (float) var Gravity = 5
export (float) var SpeedH = 100
export (float) var JumpSpeed = 210

func _ready():
	pass

func _physics_process(delta):
	speed.y += Gravity
	
	if (Input.is_action_pressed("left")):
		speed.x = -SpeedH
		get_node("Sprite").flip_h = false
		if (state != States.JUMPING):
			if (Input.is_action_pressed("up")):
				state = States.RUNNING_UP
			elif (Input.is_action_pressed("down")):
				state = States.RUNNING_DOWN
			else:
				state = States.RUNNING
	elif (Input.is_action_pressed("right")):
		speed.x = SpeedH
		get_node("Sprite").flip_h = true
		if (state != States.JUMPING):
			if (Input.is_action_pressed("up")):
				state = States.RUNNING_UP
			elif (Input.is_action_pressed("down")):
				state = States.RUNNING_DOWN
			else:
				state = States.RUNNING
	elif (on_the_ground and Input.is_action_pressed("up")):
		speed.x = 0
		if (state != States.JUMPING):
			state = States.IDLE_UP
	elif (on_the_ground and Input.is_action_pressed("down")):
		speed.x = 0
		if (state != States.JUMPING):
			state = States.GROUND
	else:
		speed.x = 0
		if (state != States.JUMPING):
			state = States.IDLE
		
	if (can_jump and Input.is_action_pressed("jump")):
		can_jump = false
		state = States.JUMPING
		speed.y -= JumpSpeed
	
	# No multiplico por delta ya que move_and_slite no lo requiere
	var movimiento = speed
	
	move_and_slide(movimiento)
	
	# Colisión
	var other = null
	if (get_slide_count() > 0):
		other = get_slide_collision(get_slide_count()-1).collider
		if (other.is_in_group("floor")):
			can_jump = true
			on_the_ground = true
			speed.y = 0
			if (state == States.JUMPING):
				# Parche para evitar glitches por cambio de collider
				# Debería pararse cuándo está por llegar a tierra (raycast?)
				global_position.y -= 10
				state = States.NONE
		else:
			on_the_ground = false
	
	# Animation
	match state:
		States.IDLE:
			anim.play("idle")
		States.IDLE_UP:
			anim.play("idle_up")
		States.GROUND:
			anim.play("ground")
		States.RUNNING:
			anim.play("run")
		States.RUNNING_UP:
			anim.play("fire_up")
		States.RUNNING_DOWN:
			anim.play("fire_down")
		States.JUMPING:
			anim.play("jump")
	
	
	