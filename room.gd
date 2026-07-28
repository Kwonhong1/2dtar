extends Node2D

@export var room_data_res: RoomData

var current_room_id: int = -1
var monster_count: int = 0
var is_cleared: bool = false

func _process(_delta: float) -> void:
	if current_room_id == -1:
		return
		
	# 🎯 방이 언로드되어 있거나 다른 곳에 있어도 데이터 속 마감 시간을 실시간 백그라운드 체크
	var room_data = RoomManager.current_layout.rooms.get(current_room_id)
	if room_data and not room_data.is_mutated and room_data.mutation_deadline > 0.0:
		if Time.get_ticks_msec() >= room_data.mutation_deadline:
			mutate_doors(room_data)

func setup_room(room_data: MapLayout.RoomNode) -> void:
	current_room_id = room_data.room_id
	
	print("=========================================")
	print("📍 현재 방 ID: ", current_room_id)
	print("📍 현재 방 타입(room_type): ", room_data.room_type)
	print("=========================================")
	
	is_cleared = room_data.is_cleared
	
	# 🎯 핵심: 방에 최초로 발을 들인 순간, 아직 마감 시간이 없다면 3초(3000ms) 뒤의 절대 시간 설정!
	if room_data.mutation_deadline == 0.0 and not room_data.is_mutated:
		room_data.mutation_deadline = Time.get_ticks_msec() + 3000.0
	
	# 1. 이전 방의 잔해 즉시 초기화
	clear_old_entities_instantly()
	
	# 2. 배경 색상 설정
	var bg = get_node_or_null("NavigationRegion2D/Background") as Sprite2D
	if bg and room_data_res:
		bg.modulate = room_data_res.background_color
		
	# 3. 몬스터 방인 경우 처리 및 스폰
	if room_data.room_type == RoomData.RoomType.MONSTER:
		if not is_cleared:
			spawn_and_count_monsters()
	else:
		is_cleared = true

	# 4. 아이템 및 상자 배치 실행
	spawn_items()

	# 5. 문 설정 (변이 여부에 따른 연결 상태 반영)
	update_doors(room_data)

# 🌀 3초 경과 시 문들을 무작위 다른 방으로 변이시키는 함수
func mutate_doors(room_data: MapLayout.RoomNode) -> void:
	room_data.is_mutated = true
	print("[Room ID: %d] 3초 경과! 문들이 새로운 시공간으로 변이됩니다." % room_data.room_id)
	
	var all_room_ids = RoomManager.current_layout.rooms.keys()
	for dir in room_data.connected_doors.keys():
		if room_data.connected_doors[dir] != -1:
			# 전체 방 목록 중 랜덤한 방 ID로 강제 교체
			room_data.connected_doors[dir] = all_room_ids[randi() % all_room_ids.size()]
	
	# 현재 활성화된 방인 경우 문 UI/충돌 즉시 갱신
	if current_room_id == room_data.room_id:
		update_doors(room_data)

# 🧹 이전 엔티티 즉시 청소 함수
func clear_old_entities_instantly() -> void:
	var monsters_node = get_node_or_null("Monsters")
	if monsters_node:
		for child in monsters_node.get_children():
			child.free()
			
	var items_node = get_node_or_null("Items")
	if items_node:
		for child in items_node.get_children():
			child.free()
			
	var chest_node = get_node_or_null("Chest")
	if chest_node:
		chest_node.visible = false

func spawn_items() -> void:
	if not room_data_res:
		return
		
	var items_node = get_node_or_null("Items")
	if not items_node:
		return

	var room_data = RoomManager.current_layout.rooms[current_room_id]
	if room_data.items_collected:
		var chest_node = get_node_or_null("Chest")
		if chest_node:
			chest_node.visible = false
		return

	if room_data_res.has_chest:
		var chest_node = get_node_or_null("Chest")
		if chest_node:
			chest_node.visible = true

	if room_data_res.item_scene_to_spawn:
		var item_instance = room_data_res.item_scene_to_spawn.instantiate() as Node2D
		
		if not room_data_res.item_datas_to_drop.is_empty():
			var assigned_data = room_data_res.item_datas_to_drop[0]
			if "item_data" in item_instance:
				item_instance.item_data = assigned_data

		items_node.add_child(item_instance)

		var item_marker = get_node_or_null("Spawns/ItemMarker") as Marker2D
		if item_marker:
			item_instance.global_position = item_marker.global_position
		else:
			item_instance.global_position = global_position
			
		if item_instance.has_signal("item_collected"):
			item_instance.item_collected.connect(func():
				room_data.items_collected = true
				print("[Room] 아이템 획득 완료! 다음부터는 스폰되지 않습니다.")
			)

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
			
			if room_data.room_type == RoomData.RoomType.MONSTER and not is_cleared:
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
					monsters_node.add_child(enemy)
					enemy.global_position = marker.global_position
								
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
		room_data.is_cleared = true
		update_doors(room_data)

func _on_door_body_entered(body: Node2D, direction: String) -> void:
	if (body.is_in_group("player") or body.name == "Player") and is_cleared:
		var room_data = RoomManager.current_layout.rooms[current_room_id]
		var next_id = room_data.connected_doors[direction]
		if next_id != -1:
			RoomManager.call_deferred("move_to_room", next_id, direction)
