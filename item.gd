extends Area2D

# 에디터 인스펙터 창에서 미리 .tres 파일을 꽂아둘 수 있습니다.
@export var item_data: Itemdata : set = _set_item_data

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# 플레이어가 닿았을 때의 시그널 연결 (에디터에서 안 했다면 코드로 안전하게 연결)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# 인스펙터에서 미리 데이터가 지정되어 있었다면 외형 반영
	if item_data:
		_apply_item_data()

# 코드로 동스폰할 때 호출하는 함수 (예: ItemManager가 호출)
func setup(data: Itemdata) -> void:
	item_data = data
	_apply_item_data()

# 인스펙터에서 아이템 데이터를 바꿀 때 실시간으로 반영되게 해주는 setter
func _set_item_data(value: Itemdata) -> void:
	item_data = value
	if is_node_ready():
		_apply_item_data()

# 데이터 내용을 화면(스프라이트, 크기 등)에 적용하는 함수
func _apply_item_data() -> void:
	if not item_data:
		return
		
	# 1. 스프라이트 이미지 적용 (WeaponData의 경우 sprite_texture 우선, 없으면 icon 사용)
	if "sprite_texture" in item_data and item_data.sprite_texture:
		sprite_2d.texture = item_data.sprite_texture
	elif item_data.icon:
		sprite_2d.texture = item_data.icon
		
	# 2. 크기(item_size)가 지정되어 있다면 비율에 맞게 스케일 조절
	if "item_size" in item_data and sprite_2d.texture:
		var original_size = sprite_2d.texture.get_size()
		if original_size.x > 0 and original_size.y > 0:
			# 지정한 픽셀 크기에 맞추어 스케일 계산 (예: 75x15 크기 반영)
			sprite_2d.scale = item_data.item_size / original_size

# 플레이어가 아이템 영역에 진입했을 때
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("[Item] 아이템 획득 시도: ", item_data.item_name)
		
		# TODO: 플레이어의 인벤토리 시스템에 아이템 데이터를 전달하는 로직
		# 예시: body.add_item_to_inventory(item_data)
		
		# 획득 완료 후 바닥에서 아이템 삭제
		queue_free()
