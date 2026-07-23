extends Node2D

var current_room_id: int = -1

func setup_room(room_data: MapLayout.RoomNode) -> void:
	current_room_id = room_data.room_id
	
	# 1. 배경 색상 설정 (get_node_or_null로 안전하게 탐색)
	var bg = get_node_or_null("Background") as Sprite2D
	if bg:
		match room_data.room_type:
			MapLayout.RoomType.NORMAL:
				bg.modulate = Color(1.0, 0.9, 0.4) # 일반 방: 노란빛
			MapLayout.RoomType.ITEM:
				bg.modulate = Color(0.2, 0.2, 0.2) # 아이템 방: 어두운색
			MapLayout.RoomType.MONSTER:
				bg.modulate = Color(0.3, 0.5, 1.0) # 몬스터 방: 파란빛
	else:
		print("[Room] 경고: 'Background' 노드를 찾지 못했습니다!")
			
	# 2. 문(Area2D) 및 내부 충돌체 활성화/비활성화 처리
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
			door.monitoring = is_connected
			
			# 문 안의 충돌체까지 완전히 꺼주어 시작 시 밀림 현상 방지
			var col_shape = door.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col_shape:
				col_shape.disabled = not is_connected

# 문에 닿았을 때 RoomManager에 이동 요청
func _on_door_triggered(direction: String) -> void:
	var room_data = RoomManager.current_layout.rooms[current_room_id]
	var next_id = room_data.connected_doors[direction]
	if next_id != -1:
		RoomManager.move_to_room(next_id, direction)
