extends Node
@export var room_scene_path: String = "res://maps/room.tscn"
var room_scene: PackedScene
var pool_size: int = 5
var room_pool: Array[Node2D] = []

var current_layout: MapLayout
var active_room_id: int = 1
var active_room_instance: Node2D = null

func _ready() -> void:
	room_scene = load(room_scene_path)
	initialize_pool()
	start_new_run(randi())

# 1. 방 오브젝트 풀 미리 생성 (최적화)
func initialize_pool() -> void:
	for i in range(pool_size):
		var room = room_scene.instantiate()
		set_room_active(room, false) # 처음에 생성할 때는 완전히 비활성화
		get_tree().current_scene.add_child(room)
		room_pool.append(room)

func start_new_run(map_seed: int) -> void:
	current_layout = MapLayout.new()
	current_layout.generate_layout(map_seed, 20)
	active_room_id = 1
	
	# 시작 방 스폰
	spawn_room(active_room_id, Vector2.ZERO)

# 2. 풀에서 방을 하나 꺼내거나 재사용하여 배치
func spawn_room(room_id: int, world_pos: Vector2) -> void:
	if active_room_instance:
		# 이전 방은 완전히 비활성화 (보이지도 않고 물리/프로세스도 정지)
		set_room_active(active_room_instance, false)
		
	var room_data = current_layout.rooms[room_id]
	
	# 유휴 상태인 방을 가져오거나 새로 할당
	var room_node = get_available_room_from_pool()
	room_node.global_position = world_pos
	
	# 새 방 활성화 (보이게 하고 물리/프로세스 켜기)
	set_room_active(room_node, true)
	
	# 방 내부 데이터(색상, 문, 콘텐츠) 주입
	room_node.setup_room(room_data)
	active_room_instance = room_node

func get_available_room_from_pool() -> Node2D:
	for room in room_pool:
		# visible 대신 process_mode나 커스텀 체크로 유휴 상태 판별
		if room.process_mode == Node.PROCESS_MODE_DISABLED:
			return room
			
	# 풀이 부족하면 추가 생성
	var new_room = room_scene.instantiate()
	set_room_active(new_room, false)
	get_tree().current_scene.add_child(new_room)
	room_pool.append(new_room)
	return new_room

# 방의 활성/비활성 상태를 시각적 + 물리적으로 완벽하게 제어하는 헬퍼 함수
func set_room_active(room: Node2D, is_active: bool) -> void:
	room.visible = is_active
	if is_active:
		room.process_mode = Node.PROCESS_MODE_INHERIT # 연산 재개
	else:
		room.process_mode = Node.PROCESS_MODE_DISABLED # 물리, 스크립트 연산 완전 정지 (유령 방 방지)

# 플레이어가 문을 통과했을 때 호출
func move_to_room(target_id: int, direction: String) -> void:
	active_room_id = target_id
	
	# 방 크기(1500x1500px)에 맞춰 오프셋 수정
	var offset = Vector2.ZERO
	match direction:
		"up": offset = Vector2(0, -1500)
		"down": offset = Vector2(0, 1500)
		"left": offset = Vector2(-1500, 0)
		"right": offset = Vector2(1500, 0)
		
	var next_pos = active_room_instance.global_position + offset
	spawn_room(target_id, next_pos)
	print("[RoomManager] 방 이동 성공: ID -> ", target_id)
