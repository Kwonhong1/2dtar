extends CanvasLayer

@onready var inventory_window = $SafeArea/InventoryWindow
@onready var time_label = $SafeArea/TopLeft/StatsInfo/TimeLabel
@onready var inventory_btn = $SafeArea/InventoryBtn
@onready var hp_bar = $SafeArea/TopLeft/StatsInfo/HPBar

var elapsed_time: float = 0.0
var is_playing: bool = true

func _ready() -> void:
	inventory_window.hide()
	inventory_btn.pressed.connect(toggle_inventory)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 1. 플레이어의 신호들과 나의 UI 갱신 함수를 연결합니다.
		player.hp_changed.connect(_on_player_hp_changed)
		player.inventory_updated.connect(_on_inventory_updated)
		
		# 2. 게임 시작 시점의 초기 체력바로 UI를 한 번 세팅해 줍니다.
		hp_bar.max_value = player.max_health
		hp_bar.value = player.health
func _process(delta: float) -> void:
	if is_playing:
		elapsed_time += delta
		update_time_display()

func update_time_display() -> void:
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	# "02:05" 형태로 포맷팅
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _unhandled_input(event: InputEvent) -> void:
	# Project Settings -> Input Map에 "toggle_inventory" (Tab 키) 등록 필요
	if event.is_action_pressed("Tab"):
		toggle_inventory()

func toggle_inventory() -> void:
	inventory_window.visible = not inventory_window.visible
	# 인벤토리가 열렸을 때 뒷배경 게임 클릭을 막으려면 아래 옵션 활용
	# inventory_window.mouse_filter = Control.MOUSE_FILTER_STOP 


func _on_player_hp_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	print("체력바 업데이트: %d / %d" % [current, maximum])

# 🎒 인벤토리 변경 신호를 받았을 때 실행될 함수
func _on_inventory_updated(items: Array) -> void:
	print("인벤토리 UI 새로고침! 현재 소지 아이템 개수: ", items.size())
	
	# TODO: items 배열을 순회하며 인벤토리 창(GridContainer) 안의 
	# 슬롯 UI(TextureRect 등)에 아이콘을 그려주는 로직을 여기에 구현하면 됩니다.
