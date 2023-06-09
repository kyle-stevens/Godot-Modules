extends CharacterBody3D

# Movement Constants

const ACCEL = 4.5 #m/s^2
const DEACCEL = 16 #m/s^2
const MAX_SPEED = 8 #m/s
const JUMP_VELOCITY = 4.5 #m/s
const MAX_SPRINT_SPEED = 15 #m/s

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var animation_player : AnimationPlayer
var current_animation : Animation

var is_sprinting : bool
var vel : Vector3 = Vector3()
var dir : Vector3 = Vector3()
var sprint_energy : int = 100

var flashlight : SpotLight3D

@onready var camera = get_node("RotationHelper/Camera")
@export var x_range = 25

@onready var rotation_helper = get_node("RotationHelper")
@export var mouse_sensitivity = 0.05

@onready var player_model = get_node("PlayerModel")

func _ready():
	# Model Loading for Script Based Model Loading
	# var instance_model = load("res://*.tscn").instantiate()
	# instance_model.set_name("PLAYER_MODEL")
	# player_model.add_child(instance_model)
	
	# Get Flashlight 
	self.flashlight = get_node("RotationHelper/Flashlight")
	
	# Get Animation Player - When you have an animated model
	# self.animation_player = get_node("AnimationPlayer")
	
	# Start Idle Animation
	# self.animation_player.play("Library/Idle")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_inputs(delta)
	process_movement(delta)

func process_inputs(delta):
	# Handling Sprint Recharge Mechanic
	if not self.is_sprinting:
		self.sprint_energy += 1
	if sprint_energy > 100:
		sprint_energy = 100
	#Check if Jumping
	if is_on_floor(): #keeps motion while in jump
		dir = Vector3()

	#Camera Transform
	var cam_xform = camera.get_global_transform()

	#Set Input Movement
	var input_movement_vector = Vector2()

	#Booleans for Movement
	var forward = false
	var backward = false
	var left = false
	var right = false
	
	if is_on_floor():
		if Input.is_action_pressed("fps_forward"):
			input_movement_vector.y += 1
			forward = true
		elif Input.is_action_pressed("fps_backward"):
			input_movement_vector.y -= 1
			backward = true
		elif Input.is_action_pressed("fps_left"):
			input_movement_vector.x -= 1
			left = true
		elif Input.is_action_pressed("fps_right"):
			input_movement_vector.x += 1
			right = true
	input_movement_vector = input_movement_vector.normalized()

	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x

	#Jump Movement
	if is_on_floor():
		if Input.is_action_just_pressed("fps_jump"):
			vel.y = JUMP_VELOCITY

	#Cursor Freeing
	if Input.is_action_just_pressed("ui_cancel"):
		print("cursor freeing")
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	#Flashlight Toggle
	if Input.is_action_just_pressed("fps_flashlight"):
		if flashlight.visible == true:
			flashlight.visible = false
		else:
			flashlight.visible = true

	#Sprinting Movement
	if Input.is_action_pressed("fps_sprint") and backward == false:
		#is_sprinting = true
		self.is_sprinting = true
	else:
		self.is_sprinting = false

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	vel.y -= delta * gravity
	
	var hvel = vel
	hvel.y = 0
	var target = dir
	#target *= MAX_SPEED
	if is_sprinting:
		target *= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED
	var accel
	
	if dir.dot(hvel) > 0:
		if self.is_sprinting:
			accel = ACCEL * 1.5
		elif self.is_sprinting:
			self.is_sprinting = false
		else:
			accel = ACCEL
	else:
		accel = DEACCEL
	hvel = hvel.lerp(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	self.set_velocity(vel)
	move_and_slide()
	vel = self.get_velocity()

func _input(event):
	if event is InputEventMouseMotion and \
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(
				deg_to_rad(event.relative.y*mouse_sensitivity * 1))
				#change to 1 for inverted mouse up/dwn
		self.rotate_y(
				deg_to_rad(event.relative.x*mouse_sensitivity * -1))
				#change to 1 for inverted mouse left/right

		var camera_rot = rotation_helper.rotation
		#print(camera_rot)
		
		camera_rot.x = clamp(camera_rot.x, -deg_to_rad(x_range), deg_to_rad(x_range))

		rotation_helper.rotation = camera_rot
