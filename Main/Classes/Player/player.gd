class_name Player
extends CharacterBody2D

@onready var sprite_2d_icon: Sprite2D = $Sprite2D_Icon
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 变量定义 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
const RUN_SPEED = 160.0
const FLOOR_ACCELERATION = RUN_SPEED / 0.2
const AIR_ACCELERATION = RUN_SPEED / 0.02
const JUMP_VELOCITY = -329

var default_gravity = ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick = false

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 函数 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
func move(gravity: float, _delta: float) -> void:
	var direction = Input.get_axis("Left", "Right")
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * _delta)
	velocity.y += gravity * _delta
	
	if not is_zero_approx(direction):
		sprite_2d_icon.flip_h = direction < 0

	move_and_slide()
	
func stand(_delta: float) -> void:
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * _delta)
	velocity.y += default_gravity * _delta

	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Up"):
		jump_request_timer.start()

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 状态机 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	LAND,
}
const GROUND_STATES = [State.IDLE, State.RUN]

func tick(_state: State, _delta: float) -> void:
	match _state:
		State.IDLE:
			move(default_gravity, _delta)
			
		State.RUN:
			move(default_gravity, _delta)
			
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, _delta)
			
		State.FALL:
			move(default_gravity, _delta)
			
		State.LAND:
			stand(_delta)
			
	is_first_tick = false

func get_next_state(_state: State) -> int:
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
	
	var direction := Input.get_axis("Left", "Right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match _state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUN
				
		State.RUN:
			if is_still:
				return State.IDLE
				
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				return State.LAND if is_still else State.RUN
				
		State.LAND:
			if not animation_player.is_playing():
				return State.IDLE
			
	return StateMachine.KEEP_CURRENT
	
func transition_state(_from: State, _to: State) -> void:
	# print("[%s] %s => %s" % [Engine.get_physics_frames(),State.keys()[_from] if _from != -1 else "<START>",State.keys()[_to],]) 
	
	if _from not in GROUND_STATES and _to in GROUND_STATES:
		coyote_timer.stop()
	
	match _to:
		State.IDLE:
			animation_player.play("idle_right")
			
		State.RUN:
			animation_player.play("run_right")
			
		State.JUMP:
			animation_player.play("jump_right")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
			
		State.FALL:
			animation_player.play("fall_right")
			if _from in GROUND_STATES:
				coyote_timer.start()

		State.LAND:
			animation_player.play("land_right")
				
	is_first_tick = true
