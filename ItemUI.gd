extends TextureRect
class_name ItemUI

var item_resource: Resource # 아이템 정보 (texture, icon, grid_size 등 포함)
var is_in_grid: bool = false
var grid_pos: Vector2i = Vector2i.ZERO
var is_rotated: bool = false
var current_cell_size: int = 64
# ItemUI.gd에 임시 추가해서 터치 감지 여부 확인
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		print("터치 감지됨! (Touch Down)")
	elif event is InputEventMouseButton and event.pressed:
		print("마우스 클릭 감지됨!")

# 1. 아이템 리소스를 받아 UI를 초기화하는 함수
func setup(res: Resource, in_grid: bool, pos: Vector2i = Vector2i.ZERO, rotated: bool = false, c_size: int = 64) -> void:
	item_resource = res
	is_in_grid = in_grid
	grid_pos = pos
	is_rotated = rotated
	current_cell_size = c_size
	
	# 🎯 [수정 1] 리소스에서 텍스처/아이콘 변수를 안전하게 받아오기 (icon, texture 모두 지원)
	if "icon" in item_resource and item_resource.icon:
		texture = item_resource.icon


	# 🎯 [수정 2] 이미지가 찌그러지거나 안 보이지 않도록 기본 확장 옵션 설정
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	if is_in_grid:
		# 그리드 내 위치 및 크기 맞추기
		stretch_mode = TextureRect.STRETCH_SCALE
		size = Vector2(item_resource.grid_size) * current_cell_size
		position = Vector2(grid_pos) * current_cell_size
		pivot_offset = Vector2.ZERO
		rotation = PI / 2 if is_rotated else 0.0
		
		# 회전된 상태라면 축을 기준으로 위치를 보정
		if is_rotated:
			position.x += item_resource.grid_size.y * current_cell_size
	else:
		# 🎯 [수정 3] 주변 아이템 리스트(List View)에서 예쁘게 보이도록 설정
		rotation = 0.0
		position = Vector2.ZERO
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		custom_minimum_size = Vector2(64, 64)
	await get_tree().process_frame # 레이아웃 계산 대기
	print("ItemUI 노드 이름: ", name, " | 실제 터치 영역: ", get_global_rect())
# 2. 드래그 시작 시 호출되는 함수
func _get_drag_data(at_position: Vector2) -> Variant:
	print("drag")
	var drag_data = {
		"item_resource": item_resource,
		"source_ui": self,
		"is_rotated": is_rotated
	}
	
	# 내부 클래스로 만든 드래그 프리뷰(미리보기) 인스턴스 생성
	var preview = ItemDragPreview.new()
	preview.setup(drag_data, current_cell_size)
	set_drag_preview(preview)
	
	# 드래그 하는 동안 원래 있던 아이템은 숨김 처리
	hide() 
	
	# 원래 그리드에 있던 아이템이라면, 그리드 배열에서 자신의 공간을 비워줌 (다시 놓을 때 충돌 방지)
	if is_in_grid:
		var grid_ui = get_parent()
		if grid_ui and "grid_matrix" in grid_ui:
			var size = item_resource.grid_size
			if is_rotated: 
				size = Vector2i(size.y, size.x) # 회전 시 차지하는 가로/세로 반전
			
			for y in range(size.y):
				for x in range(size.x):
					if grid_pos.y + y < grid_ui.grid_matrix.size() and grid_pos.x + x < grid_ui.grid_matrix[0].size():
						grid_ui.grid_matrix[grid_pos.y + y][grid_pos.x + x] = null
	
	return drag_data
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			# 드래그 실패 시 복원
			show()

# ==========================================
# 드래그 중 미리보기와 'E'키 회전을 담당하는 내부 클래스
# ==========================================
class ItemDragPreview extends Control:
	var drag_data: Dictionary
	var cell_size: int
	var tex_rect: TextureRect
	
	func setup(data: Dictionary, c_size: int) -> void:
		drag_data = data
		cell_size = c_size
		
		# 🐛 [수정 4] Key Error 버그 수정: drag_data["item"] -> drag_data["item_resource"]
		var res = drag_data["item_resource"]
		
		# 미리보기용 텍스처 생성
		tex_rect = TextureRect.new()
		
		tex_rect.texture = res.icon
							
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size = Vector2(res.grid_size) * cell_size
		add_child(tex_rect)
		
		update_visuals()

	# 매 프레임 입력 검사 대신, 키가 눌렸을 때만 반응하도록 _input 사용
	func _input(event: InputEvent) -> void:
		# E 키를 막 눌렀을 때만 작동 (꾹 누르고 있을 때 연속 회전되는 것 방지)
		if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
			drag_data["is_rotated"] = !drag_data["is_rotated"] # 회전 상태 반전
			update_visuals()
			
			# 입력 이벤트를 여기서 처리했음을 엔진에 알림
			get_viewport().set_input_as_handled() 

	# 회전 상태에 따라 텍스처의 방향과 위치 업데이트
	func update_visuals() -> void:
		var res = drag_data["item_resource"]
		if drag_data["is_rotated"]:
			tex_rect.rotation = PI / 2
			# 90도 회전 시 마우스 커서 위치와 이미지 기준점이 어긋나므로 위치 보정
			tex_rect.position = Vector2(res.grid_size.y * cell_size, 0)
		else:
			tex_rect.rotation = 0.0
			tex_rect.position = Vector2.ZERO
