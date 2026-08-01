extends CanvasLayer

# 1. 예전의 InventoryWindow 대신, 새로 만든 InventoryUI 씬 인스턴스를 참조합니다.
# (노드 경로나 이름은 씬 트리에 맞게 적절히 수정해 주세요)
@onready var inventory_ui: InventoryUIManager = $SafeArea/InventoryUI 
@onready var time_label = $SafeArea/TopLeft/StatsInfo/TimeLabel
@onready var inventory_btn = $SafeArea/InventoryBtn
@onready var hp_bar = $SafeArea/TopLeft/StatsInfo/HPBar

var elapsed_time: float = 0.0
var is_playing: bool = true

func _ready() -> void:
	# 인벤토리 켜고 끄는 역할을 매니저에게 맡겼으므로, HUD의 버튼 클릭도 매니저로 연결해 줍니다.
	inventory_btn.pressed.connect(inventory_ui.toggle_inventory)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 체력바 관련 연결만 남깁니다.
		player.hp_changed.connect(_on_player_hp_changed)
		hp_bar.max_value = player.max_health
		hp_bar.value = player.health
		
		# 💡 꿀팁: 여기서 매니저에게 플레이어 노드를 꽂아주면 인스펙터 연결을 깜빡해도 자동으로 연결됩니다!
		inventory_ui.player = player

func _process(delta: float) -> void:
	if is_playing:
		elapsed_time += delta
		update_time_display()

func update_time_display() -> void:
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_player_hp_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	print("체력바 업데이트: %d / %d" % [current, maximum])
