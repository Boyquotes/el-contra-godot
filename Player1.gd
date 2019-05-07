extends KinematicBody2D

enum States {
	NONE,
	IDLE,
	IDLE_UP,
	GROUND,
	RUNNING,
	RUNNING_UP,
	RUNNING_DOWN,
	JUMPING,
	WATER_RUNNING,
	WATER_DOWN,
	WATER_IDLE
}

var speed = Vector2()
var can_jump = false
var on_the_ground = false
var on_solid_floor = false
var on_the_water = false
var state = States.IDLE
var main

onready var anim = get_node("AnimationPlayer")

export (float) var Gravity = 5
export (float) var SpeedH = 100
export (float) var JumpSpeed = 210
export (PackedScene) var Bullet

func _ready():
	main = get_tree().get_nodes_in_group("main")[0]

func _physics_process(delta):
	speed.y += Gravity
	
	if (state != States.GROUND and state != States.WATER_DOWN and Input.is_action_pressed("left")):
		speed.x = -SpeedH
		get_node("Sprite").flip_h = false
		if (state != States.JUMPING):
			if on_the_water:
				state = States.WATER_RUNNING
			else:
				if (Input.is_action_pressed("up")):
					state = States.RUNNING_UP
				elif (Input.is_action_pressed("down")):
					state = States.RUNNING_DOWN
				else:
					state = States.RUNNING
	elif (state != States.GROUND and state != States.WATER_DOWN and Input.is_action_pressed("right")):
		speed.x = SpeedH
		get_node("Sprite").flip_h = true
		if (state != States.JUMPING):
			if on_the_water:
				state = States.WATER_RUNNING
			else:
				if (Input.is_action_pressed("up")):
					state = States.RUNNING_UP
				elif (Input.is_action_pressed("down")):
					state = States.RUNNING_DOWN
				else:
					state = States.RUNNING
	elif (on_the_ground and Input.is_action_pressed("down")):
		speed.x = 0
		if Input.is_action_pressed("left"):
			get_node("Sprite").flip_h = false
		elif Input.is_action_pressed("right"):
			get_node("Sprite").flip_h = true
		if (state != States.JUMPING):
			if on_the_water:
				state = States.WATER_DOWN
			else:
				state = States.GROUND
	elif (!on_the_water and on_the_ground and Input.is_action_pressed("up")):
		speed.x = 0
		if (state != States.JUMPING):
			state = States.IDLE_UP
	else:
		speed.x = 0
		if (state != States.JUMPING):
			if on_the_water:
				state = States.WATER_IDLE
			else:
				state = States.IDLE
	
	if Input.is_action_pressed("shoot"):
		var bullet = Bullet.instance()
		bullet.global_position = get_node("bullet_point").global_position
		main.add_child(bullet)
	
	if (state == States.GROUND and !on_solid_floor and Input.is_action_pressed("jump")):
		position.y += 2
		state = States.IDLE
	elif (can_jump and (on_the_ground or on_the_water) and Input.is_action_pressed("jump")):
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
		if (other.is_in_group("water")):
			can_jump = true
			on_the_ground = true
			on_the_water = true
			speed.y = 0
			if (state == States.JUMPING):
				state = States.NONE
		elif (other.is_in_group("floor")):
			can_jump = true
			on_the_ground = true
			on_the_water = false
			if (other.is_in_group("solid")):
				on_solid_floor = true
			else:
				on_solid_floor = false
			speed.y = 0
			if (state == States.JUMPING):
				state = States.NONE
	else:
		on_the_ground = false
		on_the_water = false
		can_jump = false
		
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
		States.WATER_RUNNING:
			anim.play("water_walk")
		States.WATER_DOWN:
			anim.play("under_water")
		States.WATER_IDLE:
			anim.play("water_idle")
