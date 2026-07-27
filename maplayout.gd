class_name MapLayout
extends RefCounted

enum RoomType { NORMAL, ITEM, MONSTER }

class RoomNode:
	var room_id: int
	var room_type: RoomType
	var room_template_id: int = 1 # 👈 1~3번 템플릿 번호 저장 변수 추가
	var position: Vector2i = Vector2i.ZERO 
	var connected_doors: Dictionary = {
		"up": -1,
		"down": -1,
		"left": -1,
		"right": -1
	}
	var room_data: RoomData
var rooms: Dictionary = {}

func generate_layout(seed_value: int, total_rooms: int) -> void:
	rooms.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var start_node = RoomNode.new()
	start_node.room_id = 1
	start_node.room_type = RoomType.NORMAL
	start_node.room_template_id = 1 # 시작 방은 고정으로 1번 템플릿 사용
	start_node.position = Vector2i(0, 0)
	rooms[1] = start_node
	
	var occupied_positions: Dictionary = { Vector2i(0, 0): 1 }
	
	var directions = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}
	var opposites = { "up": "down", "down": "up", "left": "right", "right": "left" }
	
	var current_id = 2
	var max_attempts = 1000 
	var attempts = 0
	
	while current_id <= total_rooms and attempts < max_attempts:
		attempts += 1
		
		var existing_rooms = rooms.values()
		var base_room = existing_rooms[rng.randi_range(0, existing_rooms.size() - 1)]
		
		var dir_keys = directions.keys()
		var chosen_dir_key = dir_keys[rng.randi_range(0, dir_keys.size() - 1)]
		
		if base_room.connected_doors[chosen_dir_key] != -1:
			continue
			
		var target_pos = base_room.position + directions[chosen_dir_key]
		
		if occupied_positions.has(target_pos):
			continue
			
		var node = RoomNode.new()
		node.room_id = current_id
		
		# 방 타입 랜덤 지정
		var type_rand = rng.randf()
		if type_rand < 0.2: node.room_type = RoomType.ITEM
		elif type_rand < 0.6: node.room_type = RoomType.MONSTER
		else: node.room_type = RoomType.NORMAL
		
		# 🎯 3개의 .tres 파일(room_1, room_2, room_3) 중 하나를 무작위로 할당하여 고정
		node.room_template_id = rng.randi_range(1, 3)
		
		node.position = target_pos
		
		base_room.connected_doors[chosen_dir_key] = node.room_id
		node.connected_doors[opposites[chosen_dir_key]] = base_room.room_id
		
		rooms[current_id] = node
		occupied_positions[target_pos] = current_id
		current_id += 1
