class_name RoomData
extends Resource
enum RoomType { NORMAL, ITEM, MONSTER }

@export var room_type: RoomType = RoomType.NORMAL
@export var room_id: int = 1
@export var room_name: String = "Room 1"
@export var background_color: Color = Color.WHITE

# 몬스터 관련
@export var enemies_to_spawn: Array[PackedScene] = []

# 💡 아이템 관련 필드 추가
@export var has_chest: bool = false                    # 상자가 존재하는지 여부
@export var item_scene_to_spawn: PackedScene           # 방에 배치될 아이템 씬 (또는 상자 씬)
@export var item_datas_to_drop: Array[Resource] = []   # 드랍될 아이템 리소스 목록

# 지형 관련
@export var custom_room_layout_scene: PackedScene 
