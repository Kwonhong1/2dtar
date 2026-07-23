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
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var start_node = RoomNode.new()
	start_node.room_id = 1
	start_node.room_type = RoomType.NORMAL
	start_node.position = Vector2i(0, 0)
	rooms[1] = start_node
	
	var directions = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}
	var opposites = { "up": "down", "down": "up", "left": "right", "right": "left" }
	
	for i in range(2, total_rooms + 1):
		var node = RoomNode.new()
		node.room_id = i
		
		# 방 타입 무작위 배정 (아이템 20%, 몬스터 40%, 일반 40%)
		var type_rand = rng.randf()
		if type_rand < 0.2: node.room_type = RoomType.ITEM
		elif type_rand < 0.6: node.room_type = RoomType.MONSTER
		else: node.room_type = RoomType.NORMAL
		
		# 이미 생성된 방 중 무작위로 하나 골라 그 주변에 붙이기
		var existing_rooms = rooms.values()
		var base_room = existing_rooms[rng.randi_range(0, existing_rooms.size() - 1)]
		
		var dir_keys = directions.keys()
		var chosen_dir_key = dir_keys[rng.randi_range(0, dir_keys.size() - 1)]
		
		node.position = base_room.position + directions[chosen_dir_key]
		
		# 양방향 문 연결 정보 갱신
		base_room.connected_doors[chosen_dir_key] = node.room_id
		node.connected_doors[opposites[chosen_dir_key]] = base_room.room_id
		
		rooms[i] = node
