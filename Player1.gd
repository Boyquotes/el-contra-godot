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
var can_shoot = true
var dir = 1	# Arranca right
var on_the_ground = false
var on_solid_floor = false
var on_the_water = false
var state = States.IDLE
var main
var bullet_point
var bullet_direction = Vector2()

onready var anim = get_node("AnimationPlayer")
onready var sprite = get_node("Sprite")
onready var bullet_point_mid = get_node("bullet_point")
onready var bullet_point_wdown = get_node("bullet_point2")
onready var bullet_point_wup = get_node("bullet_point3")
onready var bullet_point_ground = get_node("bullet_point4")
onready var bullet_point_up = get_node("bullet_point5")

export (float) var Gravity = 5
export (float) var SpeedH = 100
export (float) var JumpSpeed = 210
export (PackedScene) var Bullet

func _ready():
	main = get_tree().get_nodes_in_group("main")[0]
	_change_state()
	
func _physics_process(delta):
	speed.y += Gravity
	
	if (state != States.GROUND and state != States.WATER_DOWN and Input.is_action_pressed("left")):
		speed.x = -SpeedH
		dir = -1
		_turn()
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
		dir = 1
		_turn()
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
			dir = -1
			_turn()
		elif Input.is_action_pressed("right"):
			dir = 1
			_turn()
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
	
	# Shooting
	if Input.is_action_pressed("shoot"):
		_shoot()
	
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
	
	_change_state()
	print(bullet_direction)

func _turn():
	var right = false
	if dir > 0:
		right = true
	sprite.flip_h = right
	if right:
		bullet_point_mid.position.x = abs(bullet_point_mid.position.x)
		bullet_point_wdown.position.x = abs(bullet_point_wdown.position.x)
		bullet_point_wup.position.x = abs(bullet_point_wup.position.x)
		bullet_point_ground.position.x = abs(bullet_point_ground.position.x)
		bullet_point_up.position.x = abs(bullet_point_up.position.x)
	else:
		bullet_point_mid.position.x = abs(bullet_point_mid.position.x) * -1
		bullet_point_wdown.position.x = abs(bullet_point_wdown.position.x) * -1
		bullet_point_wup.position.x = abs(bullet_point_wup.position.x) * -1
		bullet_point_ground.position.x = abs(bullet_point_ground.position.x) * -1
		bullet_point_up.position.x = abs(bullet_point_up.position.x) * -1
		
func _change_state():
	match state:
		States.IDLE:
			anim.play("idle")
			bullet_point = bullet_point_mid
			bullet_direction = Vector2(dir, 0)
		States.IDLE_UP:
			anim.play("idle_up")
			bullet_point = bullet_point_up
			bullet_direction = Vector2(0, -1)
		States.GROUND:
			anim.play("ground")
			bullet_point = bullet_point_ground
			bullet_direction = Vector2(dir, 0)
		States.RUNNING:
			anim.play("run")
			bullet_point = bullet_point_mid
			bullet_direction = Vector2(dir, 0)
		States.RUNNING_UP:
			anim.play("fire_up")
			bullet_point = bullet_point_wup
			bullet_direction = Vector2(dir, -1)
		States.RUNNING_DOWN:
			anim.play("fire_down")
			bullet_point = bullet_point_wdown
			bullet_direction = Vector2(dir, 1)
		States.JUMPING:
			anim.play("jump")
		States.WATER_RUNNING:
			anim.play("water_walk")
		States.WATER_DOWN:
			anim.play("under_water")
		States.WATER_IDLE:
			anim.play("water_idle")

func _shoot():
	if can_shoot and state != States.JUMPING:
		var bullet = Bullet.instance()
		bullet.global_position = bullet_point.global_position
		bullet.Direction = bullet_direction
		main.add_child(bullet)
		can_shoot = false
		get_node("Cooldown").start()

func _on_Cooldown_timeout():
	can_shoot = true
