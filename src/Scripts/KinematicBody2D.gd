extends KinematicBody2D

signal main_player_moved(position)

export (int) var speed = 150

# Set by main.gd. Is the client's unique id for this player
var id
var velocity = Vector2(0,0)
# Only true when this is the player being controlled
var main_player = true
#anim margin controls how big the player velocity must be before animations are played
var x_anim_margin = 50
var y_anim_margin = 50

func _ready():
	if "--server" in OS.get_cmdline_args():
		main_player = false

# Only called when main_player is true
func get_input():
	var prev_velocity = velocity
	velocity = Vector2(0, 0)
	if Input.is_action_pressed('ui_right'):
		velocity.x = 1
	if Input.is_action_pressed('ui_left'):
		velocity.x = -1
	if Input.is_action_pressed('ui_down'):
		velocity.y = 1
	if Input.is_action_pressed('ui_up'):
		velocity.y = -1
	velocity = velocity.normalized() * speed

	#interpolate velocity:
	if velocity.x == 0:
		velocity.x = lerp(prev_velocity.x, 0, 0.17)
	if velocity.y == 0:
		velocity.y = lerp(prev_velocity.y, 0, 0.17)

func _physics_process(delta):
	if get_tree().is_network_server():
		velocity = move_and_slide(velocity)
	else:
		if main_player:
			$Camera2D.current = true
			get_input()
			emit_signal("main_player_moved", velocity)
		else:
			$Camera2D.current = false

		# We handle animations and stuff here
		if velocity.x > x_anim_margin:
			$Sprite.play("walk-h")
			$Sprite.flip_h = false
		elif velocity.x < -x_anim_margin:
			$Sprite.play("walk-h")
			$Sprite.flip_h = true
		elif velocity.y > y_anim_margin:
			$Sprite.play("walk-down")
		elif velocity.y < -y_anim_margin:
			#replace with walking up anim when done
			$Sprite.play("walk-down")
		else:
			$Sprite.play("idle")

func move_to(new_pos, new_velocity):
	position = new_pos
	velocity = new_velocity
