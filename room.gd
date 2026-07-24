extends Node2D

var current_room_id: int = -1

func setup_room(room_data: MapLayout.RoomNode) -> void:
	current_room_id = room_data.room_id
	
	# 1. 배경 색상 설정
	var bg = get_node_or_null("Background") as Sprite2D
	if bg:
		match room_data.room_type:
			MapLayout.RoomType.NORMAL:
				bg.modulate = Color(1.0, 0.9, 0.4) # 일반 방
			MapLayout.RoomType.ITEM:
				bg.modulate = Color(0.2, 0.2, 0.2) # 아이템 방
			MapLayout.RoomType.MONSTER:
				bg.modulate = Color(0.3, 0.5, 1.0) # 몬스터 방
	else:
		print("[Room] 경고: 'Background' 노드를 찾지 못했습니다!")
			
	# 2. 문(Area2D) 활성화 및 시그널 자동 연결
	var doors = {
		"up": get_node_or_null("Doors/DoorUp") as Area2D,
		"down": get_node_or_null("Doors/DoorDown") as Area2D,
		"left": get_node_or_null("Doors/DoorLeft") as Area2D,
		"right": get_node_or_null("Doors/DoorRight") as Area2D
	}
	
	for dir in doors.keys():
		var door = doors[dir]
		if door:
			var is_connected = (room_data.connected_doors[dir] != -1)
			
			door.visible = is_connected
			door.set_deferred("monitoring", is_connected)
			
			
			var col_shape = door.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col_shape:
				col_shape.set_deferred("disabld", not is_connected)
				
			# body_entered 시그널 바인딩 및 중복 연결 방지
			if door.body_entered.is_connected(_on_door_body_entered):
				door.body_entered.disconnect(_on_door_body_entered)
			
			if is_connected:
				door.body_entered.connect(_on_door_body_entered.bind(dir))

# 플레이어가 문 영역에 진입했을 때 실행
func _on_door_body_entered(body: Node2D, direction: String) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		var room_data = RoomManager.current_layout.rooms[current_room_id]
		var next_id = room_data.connected_doors[direction]
		if next_id != -1:
			RoomManager.call_deferred("move_to_room", next_id, direction)
