extends CharacterBody2D

@export var speed:int
var move_direction:Vector2=Vector2.ZERO
func _ready() -> void:
	RoomManager.room_changed.connect(_on_room_changed)

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


# when interact with doors
func _on_room_changed(active_room: Node2D, direction: String) -> void:
	var door_node_path = ""
	var offset_vec = Vector2.ZERO
	var door_offset = 130.0 # 문에 다시 닿지 않도록 여유 공간 부여
	
	# 들어온 방향의 반대쪽 문 앞으로 배치
	match direction:
		"up":
			door_node_path = "Doors/DoorDown"
			offset_vec = Vector2(0, -door_offset)
		"down":
			door_node_path = "Doors/DoorUp"
			offset_vec = Vector2(0, door_offset)
		"left":
			door_node_path = "Doors/DoorRight"
			offset_vec = Vector2(-door_offset, 0)
		"right":
			door_node_path = "Doors/DoorLeft"
			offset_vec = Vector2(door_offset, 0)
			
	var target_door = active_room.get_node_or_null(door_node_path)
	if target_door:
		global_position = target_door.global_position + offset_vec
		velocity = Vector2.ZERO
	
