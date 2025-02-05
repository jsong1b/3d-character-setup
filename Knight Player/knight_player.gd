extends CharacterBody3D
class_name Knight


@export var speed = 5.0
@export var acceleration = 4.0
@export var jump_speed = 8.0


@onready var spring_arm = $SpringArm3D
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")


@export var mouse_sensitivity = 0.0015
@export var rotation_speed = 12.0


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false
var last_floor = true


var attacks = [
	"1H_Melee_Attack_Stab",
	"1H_Melee_Attack_Chop",
	"1H_Melee_Attack_Slice_Horizontal",
	"1H_Melee_Attack_Slice_Diagonal"
]


func _physics_process(delta):
	velocity.y += -gravity * delta
	get_move_input(delta)
	move_and_slide()

	# gradually rotate instead of instantly snapping to angle
	if velocity.length() > 1.0:
		model.rotation.y = lerp_angle(model.rotation.y, spring_arm.rotation.y, rotation_speed * delta)

	if not is_on_floor() and not jumping:
		anim_state.travel("Jump_Idle")
		anim_tree.set("parameters/conditions/grounded", false)


func _unhandled_input(event):
	if event.is_action_pressed("attack"):
		anim_state.travel(attacks.pick_random())

	if is_on_floor() and not last_floor:
		jumping = false
		anim_tree.set("parameters/conditions/grounded", true)
	last_floor = is_on_floor()

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
		jumping = true
		anim_tree.set("parameters/conditions/grounded", false)
	anim_tree.set("parameters/conditions/jumping", jumping)

	if event is InputEventMouseMotion:
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity


func get_move_input(delta):
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("left", "right", "forward", "back")

	# makes it such that the input is based on the camera
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)

	# gradually increase velocity rather than immediately
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	velocity.y = vy

	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(vl.x, -vl.z) / speed)
