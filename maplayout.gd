class_name MapLayout
extends RefCounted

enum RoomType { NORMAL, ITEM, MONSTER }

class RoomNode:
	var room_id: int
	var room_type: RoomType
	var position: Vector2i = Vector2i.ZERO 
	var connected_doors: Dictionary = {
		"up": -1,
		"down": -1,
		"left": -1,
		"right": -1
	}

var rooms: Dictionary = {}

func generate_layout(seed_value: int, total_rooms: int) -> void:
	rooms.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var start_node = RoomNode.new()
	start_node.room_id = 1
	start_node.room_type = RoomType.NORMAL
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
	var max_attempts = 1000 # 무한 루프 방지용
	var attempts = 0
	
	while current_id <= total_rooms and attempts < max_attempts:
		attempts += 1
		
		var existing_rooms = rooms.values()
		var base_room = existing_rooms[rng.randi_range(0, existing_rooms.size() - 1)]
		
		var dir_keys = directions.keys()
		var chosen_dir_key = dir_keys[rng.randi_range(0, dir_keys.size() - 1)]
		
		# 이미 문이 연결되어 있다면 스킵
		if base_room.connected_doors[chosen_dir_key] != -1:
			continue
			
		var target_pos = base_room.position + directions[chosen_dir_key]
		
		# 이미 해당 위치에 다른 방이 있다면 스킵 (방 겹침 방지)
		if occupied_positions.has(target_pos):
			continue
			
		# 새 방 생성 및 데이터 설정
		var node = RoomNode.new()
		node.room_id = current_id
		
		var type_rand = rng.randf()
		if type_rand < 0.2: node.room_type = RoomType.ITEM
		elif type_rand < 0.6: node.room_type = RoomType.MONSTER
		else: node.room_type = RoomType.NORMAL
		
		node.position = target_pos
		
		# 양방향 문 연결
		base_room.connected_doors[chosen_dir_key] = node.room_id
		node.connected_doors[opposites[chosen_dir_key]] = base_room.room_id
		
		rooms[current_id] = node
		occupied_positions[target_pos] = current_id
		current_id += 1
