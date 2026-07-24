extends Node2D

signal room_changed(active_room: Node2D, direction: String)


@export var room_scene_path: String = "res://maps/room.tscn"
var room_scene: PackedScene
var pool_size: int = 5
var room_pool: Array[Node2D] = []
var is_transitioning: bool=false
var current_layout: MapLayout
var active_room_id: int = 1
var active_room_instance: Node2D = null

func _ready() -> void:
	room_scene = load(room_scene_path)
	initialize_pool()
	start_new_run(randi())


# pooling func
func initialize_pool() -> void:
	for i in range(pool_size):
		var room = room_scene.instantiate()
		set_room_active(room, false)
		get_tree().current_scene.add_child.call_deferred(room)
		room_pool.append(room)
		
		
func get_available_room_from_pool() -> Node2D:
	for room in room_pool:
		if room.process_mode == Node.PROCESS_MODE_DISABLED:
			return room
	
	#not in pool
	var new_room = room_scene.instantiate()
	set_room_active(new_room, false)
	get_tree().current_scene.add_child(new_room)
	room_pool.append(new_room)

	return new_room

#start map design
func start_new_run(map_seed: int) -> void:
	current_layout = MapLayout.new()
	current_layout.generate_layout(map_seed, 20)
	active_room_id = 1
	
	spawn_room(active_room_id, Vector2.ZERO)


func spawn_room(room_id: int, world_pos: Vector2) -> void:
	if active_room_instance:
		set_room_active(active_room_instance, false)
		
	var room_data = current_layout.rooms[room_id]
	var room_node = get_available_room_from_pool()
	
	room_node.global_position = world_pos
	set_room_active(room_node, true)
	room_node.setup_room(room_data)
	
	active_room_instance = room_node


func set_room_active(room: Node2D, is_active: bool) -> void:
	room.visible = is_active
	if is_active:
		room.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		room.process_mode = Node.PROCESS_MODE_DISABLED

# 문 통과 시 호출되는 핵심 메커니즘
func move_to_room(target_id: int, direction: String) -> void:
	if is_transitioning:
		return
	is_transitioning=true
	active_room_id = target_id
	
	var offset = Vector2.ZERO
	match direction:
		"up": offset = Vector2(0, -1500)
		"down": offset = Vector2(0, 1500)
		"left": offset = Vector2(-1500, 0)
		"right": offset = Vector2(1500, 0)
		
	var next_pos = active_room_instance.global_position + offset
	spawn_room(target_id, next_pos)
	
	# 플레이어를 반대편 문 앞으로 텔레포트
	room_changed.emit(active_room_instance, direction)
	print("[RoomManager] 방 이동 성공: ID -> ", target_id)
	await get_tree().create_timer(0.3).timeout
	is_transitioning=false
