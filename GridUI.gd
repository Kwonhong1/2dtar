extends Control
class_name GridUI

@export var grid_width: int = 10
@export var grid_height: int = 5
@export var cell_size: int = 64

var grid_matrix: Array = []

# Variables for drawing the hover highlight
var hovered_grid_pos: Vector2i = Vector2i(-1, -1)
var hovered_item_size: Vector2i = Vector2i.ZERO
var is_hover_valid: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(grid_width * cell_size, grid_height * cell_size)
	
	# Initialize the 2D array with nulls
	grid_matrix.clear()
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			row.append(null)
		grid_matrix.append(row)

# Receives the drag data dynamically as the mouse moves over the grid
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# 🔒 [안전장치 1] 데이터 검증 및 필수 키 유효성 확인
	if typeof(data) != TYPE_DICTIONARY or not data.has("item_resource"):
		clear_hover()
		return false
		
	var item_resource = data["item_resource"]
	if item_resource == null or not item_resource.has_method("get") or not "grid_size" in item_resource:
		clear_hover()
		return false
		
	var grid_pos = get_grid_pos(at_position)
	var size: Vector2i = item_resource.grid_size
	var is_rotated: bool = data.get("is_rotated", false)
	
	if is_rotated:
		size = Vector2i(size.y, size.x) # Swap dimensions
		
	var source_ui = data.get("source_ui", null)
	is_hover_valid = is_space_free(grid_pos, size, source_ui)
	hovered_grid_pos = grid_pos
	hovered_item_size = size
	
	queue_redraw() # Trigger _draw() to show green/red highlight
	return is_hover_valid

# Called when the left mouse button is released over a valid space
func _drop_data(at_position: Vector2, data: Variant) -> void:
	clear_hover()
	
	# 🔒 [안전장치 2] drop_data 시작 시 데이터 재검증
	if typeof(data) != TYPE_DICTIONARY or not data.has("item_resource"):
		return
		
	var item_resource = data["item_resource"]
	var grid_pos = get_grid_pos(at_position)
	var size: Vector2i = item_resource.grid_size
	var is_rotated: bool = data.get("is_rotated", false)
	
	if is_rotated:
		size = Vector2i(size.y, size.x)
		
	# 1. Update Matrix (배열 범위 초과 방지)
	for y in range(size.y):
		for x in range(size.x):
			var target_y = grid_pos.y + y
			var target_x = grid_pos.x + x
			if target_y >= 0 and target_y < grid_height and target_x >= 0 and target_x < grid_width:
				grid_matrix[target_y][target_x] = item_resource
			
	# 2. Handle the visual UI node (노드 안전 조작)
	var item_ui = data.get("source_ui", null)
	
	# 🔒 [안전장치 3] UI 노드가 메모리에 유효하게 남아있는지 엄격히 검사
	if is_instance_valid(item_ui) and not item_ui.is_queued_for_deletion():
		var old_parent = item_ui.get_parent()
		if is_instance_valid(old_parent):
			old_parent.remove_child(item_ui) # 이전 부모(NearbyList 등)에서 안전하게 제거
			
		add_child(item_ui) # GridUI의 자식으로 추가
		
		# Setup the node for Grid Mode
		if item_ui.has_method("setup"):
			item_ui.setup(item_resource, true, grid_pos, is_rotated, cell_size)
			
		item_ui.show() # Unhide
		
	# 3. Cleanup world item (바닥에 떨어진 월드 아이템이 있다면 안전하게 삭제)
	if data.has("world_item"):
		var world_item = data["world_item"]
		if is_instance_valid(world_item) and not world_item.is_queued_for_deletion():
			world_item.queue_free()

# Utility: Convert local pixel position to grid coordinates
func get_grid_pos(local_pos: Vector2) -> Vector2i:
	return Vector2i(int(local_pos.x / cell_size), int(local_pos.y / cell_size))

# Utility: Check if slots are empty and within bounds
func is_space_free(start_pos: Vector2i, size: Vector2i, _ignore_ui: Control = null) -> bool:
	if start_pos.x < 0 or start_pos.y < 0: return false
	if start_pos.x + size.x > grid_width or start_pos.y + size.y > grid_height: return false
	
	for y in range(size.y):
		for x in range(size.x):
			var target_y = start_pos.y + y
			var target_x = start_pos.x + x
			if target_y >= 0 and target_y < grid_height and target_x >= 0 and target_x < grid_width:
				var occupant = grid_matrix[target_y][target_x]
				if occupant != null:
					return false 
	return true

# Drawing the Green/Red Tarkov highlight
func _draw() -> void:
	# 1. 바둑판(그리드 선) 배경 그리기
	var line_color = Color(1, 1, 1, 0.2)
	var line_width = 1.0
	
	# 가로선 긋기
	for y in range(grid_height + 1):
		var start_point = Vector2(0, y * cell_size)
		var end_point = Vector2(grid_width * cell_size, y * cell_size)
		draw_line(start_point, end_point, line_color, line_width)
		
	# 세로선 긋기
	for x in range(grid_width + 1):
		var start_point = Vector2(x * cell_size, 0)
		var end_point = Vector2(x * cell_size, grid_height * cell_size)
		draw_line(start_point, end_point, line_color, line_width)

	# 2. 마우스 드래그 중일 때 초록색/빨간색 영역 그리기
	if hovered_grid_pos.x >= 0:
		var rect = Rect2(Vector2(hovered_grid_pos) * cell_size, Vector2(hovered_item_size) * cell_size)
		var color = Color(0, 1, 0, 0.4) if is_hover_valid else Color(1, 0, 0, 0.4)
		draw_rect(rect, color)

func clear_hover() -> void:
	hovered_grid_pos = Vector2i(-1, -1)
	queue_redraw()

# Clear hover when drag leaves the grid entirely
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		clear_hover()
		# 🔒 [안전장치 4] 드래그 취소 시 source_ui를 .show() 하기 전 이미 삭제된 노드인지 필수 검사!
		var drag_data = get_viewport().gui_get_drag_data()
		if typeof(drag_data) == TYPE_DICTIONARY and drag_data.has("source_ui"):
			var source_ui = drag_data["source_ui"]
			if is_instance_valid(source_ui) and not source_ui.is_queued_for_deletion():
				source_ui.show()
