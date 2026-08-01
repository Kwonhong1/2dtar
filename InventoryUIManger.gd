extends Control
class_name InventoryUIManager

@export var player: CharacterBody2D # 플레이어 참조 (인스펙터에서 연결하거나 그룹으로 자동 탐색)
@export var grid_ui: Control # Reference to the GridUI node

@onready var nearby_item_list: VBoxContainer = $MarginContainer/HBoxContainer/NearbyPanel/VBoxContainer/ScrollContainer/NearbyItemList

const ITEM_UI_SCENE = preload("res://UI/ItemUI.tscn")

func _ready() -> void:
	hide()
	# 인스펙터에서 연결을 깜빡했을 경우를 대비해 그룹으로 자동 탐색
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	player.nearby_items_changed.connect(_on_player_nearby_items_changed)

func _on_player_nearby_items_changed() -> void:
	# 인벤토리 창이 열려있을 때만 실시간으로 주변 아이템 목록 갱신
	if visible:
		refresh_nearby_items()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Tab"): 
		toggle_inventory()

func toggle_inventory() -> void:
	visible = !visible
	if visible:
		refresh_nearby_items()

func refresh_nearby_items() -> void:
	# 1. 기존 리스트 초기화
	for child in nearby_item_list.get_children():
		child.queue_free()

	# 2. 플레이어 주변 아이템 가져오기
	var nearby_items = player.get_nearby_items()
	
	for area in nearby_items:
		if area.is_in_group("item"):
			# 🔍 [디버그] item_data가 null인지 확인
			var item_res = area.get("item_data")
			if not item_res:
				# 만약 Area2D의 변수명이 item_resource 라면 이쪽을 가져옴
				item_res = area.get("item_resource")
			
			if not item_res:
				print("❌ 에러: ", area.name, " 노드에 item_data(또는 item_resource)가 null입니다!")
				continue

			# ItemUI 인스턴스 생성
			var item_ui = ITEM_UI_SCENE.instantiate()
			
			# 🎯 [핵심] VBoxContainer 안에서 크기가 0이 되지 않도록 최소 크기 강제 지정
			item_ui.custom_minimum_size = Vector2(64, 64)
			
			nearby_item_list.add_child(item_ui)
			
			# setup 호출
			item_ui.setup(item_res, false) 
			
			# 메타데이터 저장
			item_ui.set_meta("world_area", area)
			print("✅ ItemUI 생성 완료: ", item_res.resource_path if item_res else "데이터 없음")
