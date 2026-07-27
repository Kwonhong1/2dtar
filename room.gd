extends Node2D

@export var room_data_res: RoomData

var current_room_id: int = -1
var monster_count: int = 0
var is_cleared: bool = false

func setup_room(room_data: MapLayout.RoomNode) -> void:
	current_room_id = room_data.room_id
	
	# 1. 이전 방의 잔해 즉시 초기화 (.free() 사용)
	clear_old_entities_instantly()
	
	# 2. 배경 색상 설정
	var bg = get_node_or_null("NavigationRegion2D/Background") as Sprite2D
	if bg and room_data_res:
		bg.modulate = room_data_res.background_color
	print("--- [Room 스크립트 노드 검증] ---")
	print("Background 노드 존재 여부: ", get_node_or_null("NavigationRegion2D/Background") != null)
	print("Spawns 노드 존재 여부: ", get_node_or_null("Spawns") != null)
	print("Monsters 노드 존재 여부: ", get_node_or_null("Monsters") != null)
	print("Items 노드 존재 여부: ", get_node_or_null("Items") != null)
	print("현재 적용된 방 데이터 색상: ", room_data_res.background_color if room_data_res else "데이터 없음")
	
	# 3. 몬스터 방인 경우 처리 및 스폰
	if room_data.room_type == MapLayout.RoomType.MONSTER:
		is_cleared = false
		spawn_and_count_monsters()
	else:
		is_cleared = true

	# 4. 아이템 및 상자 배치 실행
	spawn_items()

	# 5. 문 설정
	update_doors(room_data)

# 🧹 이전 엔티티 즉시 청소 함수 (queue_free -> free로 변경하여 풀링 충돌 방지)
func clear_old_entities_instantly() -> void:
	var monsters_node = get_node_or_null("Monsters")
	if monsters_node:
		for child in monsters_node.get_children():
			child.free()
			
	var items_node = get_node_or_null("Items")
	if items_node:
		for child in items_node.get_children():
			child.free()
			
	# 상자 상태 초기화 (이전 방의 상자 잔상 제거)
	var chest_node = get_node_or_null("Chest")
	if chest_node:
		chest_node.visible = false

# 🎁 리소스 기반 아이템 및 상자 배치 함수
# 🎁 리소스 기반 아이템 및 상자 배치 함수
func spawn_items() -> void:
	if not room_data_res:
		return
		
	var items_node = get_node_or_null("Items")
	if not items_node:
		return

	# 1. 상자 존재 여부 처리
	if room_data_res.has_chest:
		var chest_node = get_node_or_null("Chest")
		if chest_node:
			chest_node.visible = true

	# 2. 지정된 아이템 씬 소환 및 데이터 주입
	if room_data_res.item_scene_to_spawn:
		var item_instance = room_data_res.item_scene_to_spawn.instantiate() as Node2D
		
		# 🎯 핵심: RoomData의 item_datas_to_drop 목록에서 데이터를 꺼내 아이템에 전달합니다!
		if not room_data_res.item_datas_to_drop.is_empty():
			var assigned_data = room_data_res.item_datas_to_drop[0] # 첫 번째 아이템 데이터 선택
			if "item_data" in item_instance:
				item_instance.item_data = assigned_data

		var item_marker = get_node_or_null("Spawns/ItemMarker") as Marker2D
		if item_marker:
			item_instance.global_position = item_marker.global_position
		else:
			item_instance.global_position = global_position
			
		items_node.add_child(item_instance)

func update_doors(room_data: MapLayout.RoomNode) -> void:
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
			
			if room_data.room_type == MapLayout.RoomType.MONSTER and not is_cleared:
				door.visible = false
				door.set_deferred("monitoring", false)
				var col_shape = door.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if col_shape:
					col_shape.set_deferred("disabled", true)
			else:
				door.visible = is_connected
				door.set_deferred("monitoring", is_connected)
				var col_shape = door.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if col_shape:
					col_shape.set_deferred("disabled", not is_connected)
					
			if door.body_entered.is_connected(_on_door_body_entered):
				door.body_entered.disconnect(_on_door_body_entered)
			
			if is_connected and is_cleared:
				door.body_entered.connect(_on_door_body_entered.bind(dir))

func spawn_and_count_monsters() -> void:
	var spawns_node = get_node_or_null("Spawns")
	var monsters_node = get_node_or_null("Monsters")
	
	if spawns_node and monsters_node:
		if room_data_res and not room_data_res.enemies_to_spawn.is_empty():
			var markers = spawns_node.get_children()
			
			for i in range(min(markers.size(), room_data_res.enemies_to_spawn.size())):
				var marker = markers[i] as Marker2D
				var enemy_scene = room_data_res.enemies_to_spawn[i]
				
				if marker and enemy_scene:
					var enemy = enemy_scene.instantiate() as Node2D
					enemy.global_position = marker.global_position
					monsters_node.add_child(enemy)
					
	if monsters_node:
		var enemies = monsters_node.get_children()
		monster_count = enemies.size()
		
		if monster_count == 0:
			is_cleared = true
			return
		
		for enemy in enemies:
			if enemy.has_signal("enemy_died"):
				if not enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	monster_count -= 1
	print("[Room] 남은 몬스터 수: ", monster_count)
	
	if monster_count <= 0:
		is_cleared = true
		print("[Room] 몬스터 방 클리어! 문이 열립니다.")
		var room_data = RoomManager.current_layout.rooms[current_room_id]
		update_doors(room_data)

func _on_door_body_entered(body: Node2D, direction: String) -> void:
	if (body.is_in_group("player") or body.name == "Player") and is_cleared:
		var room_data = RoomManager.current_layout.rooms[current_room_id]
		var next_id = room_data.connected_doors[direction]
		if next_id != -1:
			RoomManager.call_deferred("move_to_room", next_id, direction)
