class_name Weapondata
extends Itemdata

enum WeaponType {MELEE, RANGE}

@export var weapon_type: WeaponType
@export var damage: float = 20.0
@export var attack_speed: float = 1.0
@export var max_ammo: int = 0
@export var item_size: Vector2 = Vector2(75, 15)
# 여기에 칼의 외형 스프라이트(디자인)를 직접 연결합니다!
@export var sprite_texture: Texture2D 
