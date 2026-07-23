extends CharacterBody2D

@export var speed:int
var move_direction:Vector2=Vector2.ZERO


func _physics_process(delta: float) -> void:
	movement_loop()

func movement_loop() ->void:
	#by wasd, decide direction x and y
	move_direction.x=int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))
	move_direction.y=int(Input.is_action_pressed("Down")) - int(Input.is_action_pressed("Up"))
	#normalized for smoothness
	var motion: Vector2=move_direction.normalized() *speed
	velocity=motion
	move_and_slide()
	
	
