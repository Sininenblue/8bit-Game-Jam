extends KinematicBody2D

onready var DEATHFX = preload("res://Player/particles/DeathParticles.tscn")
onready var DUSTFX = preload("res://Player/particles/Dust.tscn")

export (float) var gravity = 350
export (float) var speed = 60
export (float) var jump = 135

var x_input = 0
var prev_input = 1
var wall_direction
var on_ground

var velocity = Vector2.ZERO
var previous_velocity = Vector2.ZERO

onready var left1 = $LeftRaycasts/Left1
onready var left2 = $LeftRaycasts/Left2
onready var right1 = $RightRaycasts/Right1
onready var right2 = $RightRaycasts/Right2
var on_wall = false
var right = false
var left = false

var hit_the_ground = false

var do_once = false

onready var anim = $AnimationPlayer

var state = MOVE
enum{
	MOVE,
	WALLSLIDE,
	WIN,
	DEAD
}


onready var jumpsfx = $SFX/Jump
onready var deathsfx = $SFX/Death
onready var groundhitsfx = $SFX/GroundHit
onready var spawnfx = $SFX/Spawn


func _ready():
	spawnfx.play()
	
	_death_particles()
	
	left1.add_exception($".")
	left2.add_exception($".")
	right1.add_exception($".")
	right2.add_exception($".")


func _process(delta):
	_squish(delta)
	
	_handle_animations()
	state_transitions()
	_raycast_collisions()
	
	
	match state:
		MOVE:
			_move_state(delta)
		WALLSLIDE:
			_move_state(delta)
			_wallslide_state()
		WIN:
			_win_state()
		DEAD:
			_dead_state()
	
	previous_velocity = velocity
	velocity = move_and_slide(velocity, Vector2.UP)


func state_transitions():
	match state:
		MOVE:
			if on_wall == true and !is_on_floor():
				state = WALLSLIDE
		WALLSLIDE:
			if on_wall == false:
				state = MOVE
			if is_on_floor():
				state = MOVE


func _handle_animations():
	if x_input != 0:
		$Sprite.flip_h = x_input < 0
		if prev_input != x_input:
			prev_input = x_input
			if is_on_floor():
				_dust_particles(-x_input)
	
	if is_on_floor():
		if x_input !=  0:
			anim.play("run")
		else:
			anim.play("idle")
	else:
		if state == WALLSLIDE:
			if left1.is_colliding() and left2.is_colliding():
				anim.play("wallslide")
			if right1.is_colliding() and right2.is_colliding():
				anim.play("wallslide")
		else:
			if velocity.y < 0:
				anim.play("jump")
			else:
				anim.play("fall")


func _move_state(delta):
	$Wallslideparticles.emitting = false
	
	velocity.y += gravity * delta
	
	x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if x_input != 0:
		if is_on_floor():
			velocity.x = lerp(velocity.x, x_input * speed, .75)
		else:
			velocity.x = lerp(velocity.x, x_input * speed, .1)
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0, .4)
		else:
			velocity.x = lerp(velocity.x, 0, .05)
	
	#Jump Logic
	if is_on_floor():
		$Timers/CoyoteTimer.start(.2)
	
	if $Timers/CoyoteTimer.time_left != 0:
		on_ground = true
	else:
		on_ground = false
	
	if Input.is_action_just_pressed("ui_up"):
		$Timers/JumpBuffer.start(.1)
	
	if on_ground == true and $Timers/JumpBuffer.time_left != 0:
		jumpsfx.play()
		_dust_particles(rand_range(-1,1))
		
		$Timers/CoyoteTimer.stop()
		velocity.y = -jump
	
	if Input.is_action_just_released("ui_up") and velocity.y < -jump/2:
		velocity.y = -jump/2


func _wallslide_state():
	if on_wall == true and !is_on_floor() and Input.is_action_just_pressed("ui_up"):
		_dust_particles(wall_direction)
		
		jumpsfx.play()
		
		velocity = Vector2(wall_direction * 100, -jump)
	
	if on_wall == true:
		$Wallslideparticles.emitting = true
		$Wallslideparticles.position.x = -wall_direction * 2
		velocity.y = lerp(velocity.y, 0, .1)


func _dead_state():
	velocity.x = 0
	
	if do_once == false:
		deathsfx.play()
		
		$Timers/DeathTimer.start(.7)
		do_once = true


func _win_state():
	velocity.x = lerp(velocity.x, 0 , .7)


func _squish(delta):
	if !is_on_floor():
		hit_the_ground = false
		$Sprite.scale.y = range_lerp(abs(velocity.y), 0, abs(jump), 0.75, 1.75)
		$Sprite.scale.x = range_lerp(abs(velocity.y), 0, abs(jump), 1.25, 0.75)
	
	if not hit_the_ground and is_on_floor():
		hit_the_ground = true
		if previous_velocity.y > 160:
			groundhitsfx.play()
			$Camera2D.shake(.2, 40, 2)
			
			_dust_particles(-1)
			_dust_particles(1)
			
		
		$Sprite.scale.x = range_lerp(abs(previous_velocity.y), 0, abs(jump * 2), 1.2, 2.0)
		$Sprite.scale.y = range_lerp(abs(previous_velocity.y), 0, abs(jump * 2), 0.8, 0.5)
	
	$Sprite.scale.x = lerp($Sprite.scale.x, 1, 1 - pow(0.01, delta))
	$Sprite.scale.y = lerp($Sprite.scale.y, 1, 1 - pow(0.01, delta))


func _raycast_collisions():
	if left == true:
		wall_direction = 1
	else:
		wall_direction = -1
	if left == true or right == true:
		on_wall = true
	else:
		on_wall = false
	
	if left1.is_colliding() or left2.is_colliding():
		left = true
	else:
		left = false
	
	if right1.is_colliding() or right2.is_colliding():
		right = true
	else:
		right = false


func _kill():
	state = DEAD
	
	$CollisionShape2D.call_deferred("set","disabled", true)
	$Sprite.call_deferred("set","visible", false)
	
	$Camera2D.shake(.3, 20, 5)
	
	_death_particles()


func _on_DeathTimer_timeout():
	get_tree().reload_current_scene()


func _on_VisibilityNotifier2D_screen_exited():
	_kill()


func _death_particles():
	var deathfx = DEATHFX.instance()
	deathfx.emitting = true
	call_deferred("add_child", deathfx)


func _dust_particles(dir):
	var dustfx = DUSTFX.instance()
	dustfx.emitting = true
	dustfx.direction.x = dir
	call_deferred("add_child", dustfx)


func _done():
	state = WIN


func _reppel(direction):
	$Camera2D.shake(.1, 50, 1)
	velocity = direction * 180
