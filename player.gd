extends CharacterBody2D
#move variables
@export var speed:int
var move_direction:Vector2=Vector2.ZERO
var last_facing_direction: Vector2 = Vector2(0, 1) # 기본값: 아래쪽 바라보기

#item variables
var equipped_weapon: Weapondata = null
var inventory_consumables: Array = [] # 소모품 리스트 (수류탄 등)
var hold_distance: float = 120


#stat variables
var health:int=100

@onready var weapon_holder: Marker2D = $Weaponholder
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var weapon_hitbox: CollisionShape2D=$Weaponholder/Area2D/CollisionShape2D
func _ready() -> void:
	RoomManager.room_changed.connect(_on_room_changed)

func _physics_process(delta: float) -> void:
	movement_loop()

func movement_loop() -> void:
	# 1. 입력값 계산 (대각선 이동을 위해 원본 입력 유지)
	move_direction.x = int(Input.is_action_pressed("Right")) - int(Input.is_action_pressed("Left"))
	move_direction.y = int(Input.is_action_pressed("Down")) - int(Input.is_action_pressed("Up"))
	
	if move_direction != Vector2.ZERO:
		# 2. 💡 애니메이션을 위한 방향값만 4방향(상하좌우) 중 하나로 강제 고정
		if abs(move_direction.x) > abs(move_direction.y):
			last_facing_direction = Vector2(sign(move_direction.x), 0) # 좌 또는 우
		else:
			last_facing_direction = Vector2(0, sign(move_direction.y)) # 상 또는 하

	# 3. 4방향으로 고정된 값만 AnimationTree에 전달 (경로 본인 설정에 맞게 확인!)
	animation_tree.set("parameters/Idle/blend_position", last_facing_direction)

	# 4. 실제 캐릭터 이동은 대각선으로 부드럽게 작동
	var motion: Vector2 = move_direction.normalized() * speed
	velocity = motion
	move_and_slide()

# when interact with doors
func _on_room_changed(active_room: Node2D, direction: String) -> void:
	var door_node_path = ""
	var offset_vec = Vector2.ZERO
	var door_offset = 130.0 # 문에 다시 닿지 않도록 여유 공간 부여
	
	# 들어온 방향의 반대쪽 문 앞으로 배치
	match direction:
		"up":
			door_node_path = "Doors/DoorDown"
			offset_vec = Vector2(0, -door_offset)
		"down":
			door_node_path = "Doors/DoorUp"
			offset_vec = Vector2(0, door_offset)
		"left":
			door_node_path = "Doors/DoorRight"
			offset_vec = Vector2(-door_offset, 0)
		"right":
			door_node_path = "Doors/DoorLeft"
			offset_vec = Vector2(door_offset, 0)
			
	var target_door = active_room.get_node_or_null(door_node_path)
	if target_door:
		global_position = target_door.global_position + offset_vec
		velocity = Vector2.ZERO
		
		

# 🎒 플레이어가 현재 소유/장착 중인 아이템 관리 변수

# 아이템(Area2D)과 충돌하여 획득할 때 호출되는 함수
func pick_up_item(data: Itemdata) -> void:
	if data is Weapondata:
		equipped_weapon = data
		_equip_weapon(data)
		print("[Player] 무기 획득 및 장착: ", data.item_name, " (데미지: ", data.damage, ")")
		
	elif data is Consumabledata:
		inventory_consumables.append(data)
		print("[Player] 소모품 획득: ", data.item_name, " (남은 수량 또는 인벤토리 추가)")

# 무기를 손에 시각적으로 쥐여주는 함수
func _equip_weapon(data: Weapondata) -> void:

	# 1. 기존에 손에 들고 있던 무기 그래픽이 있다면 삭제
	for child in weapon_holder.get_children():
		# 만약 Area2D가 자식으로 박혀있다면 Area2D를 지우지 않도록 주의해야 합니다!
		if child.name != "Area2D": 
			child.queue_free()
		
	# 2. 새로운 무기의 스프라이트 노드를 생성해서 쥐어줌
	var weapon_sprite = Sprite2D.new()
	
	# 스프라이트 이미지 지정 (WeaponData에 있는 sprite_texture 사용)
	if data.sprite_texture:
		weapon_sprite.texture = data.sprite_texture
	elif data.icon:
		weapon_sprite.texture = data.icon
		
	# 3. 규격(75x15 등)에 맞게 크기(Scale) 자동 조절
	if data.item_size and weapon_sprite.texture:
		var original_size = weapon_sprite.texture.get_size()
		if original_size.x > 0 and original_size.y > 0:
			weapon_sprite.scale = data.item_size / original_size
			
	# 4. WeaponHolder의 자식으로 등록하여 플레이어와 함께 움직이게 함
	print("its child")
	weapon_holder.add_child(weapon_sprite)
	
	# hitbox setting
	var hitbox_shape = weapon_holder.find_child("CollisionShape2D")
	if hitbox_shape and hitbox_shape.shape is RectangleShape2D:
		# 무기 규격 크기를 히트박스에 그대로 반영
		hitbox_shape.shape.size = data.item_size
# 입력 처리 (공격 키를 눌렀을 때)
func _unhandled_input(event: InputEvent) -> void:
	# 'attack' 액션은 프로젝트 설정에서 미리 만들어두어야 합니다 (예: 마우스 좌클릭)
	if event.is_action_pressed("Attack") and equipped_weapon:
		_use_weapon()

# 무기 사용 로직
func _use_weapon() -> void:
	print("[Player] 무기 휘두르기! 장착된 무기: ", equipped_weapon.item_name)
	
	# 무기 타입에 따른 분기 (근접 vs 원거리)
	if equipped_weapon.weapon_type == Weapondata.WeaponType.MELEE:
		animation_tree.set("parameters/Attackblend/blend_position", last_facing_direction)
		playback.travel("Attackblend")
		attack(equipped_weapon.damage)
		# TODO: 근접 공격 판정 (예: 검 휘두르기 애니메이션, 범위 내 적에게 데미지 주기)
		pass
	elif equipped_weapon.weapon_type == Weapondata.WeaponType.RANGE:
		# TODO: 총알 발사 (탄창 소모, 총알 인스턴스 생성 등)
		pass

	
func take_damage(damage:int) ->void:
	health-=damage
	print("now hp: ", health)
	pass
	
func attack(damage: int) -> void:
	weapon_hitbox.disabled = false
	await get_tree().create_timer(0.2).timeout # 0.2초 동안 공격 판정 유지
	weapon_hitbox.disabled = true
	pass
	

# monster damaged
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("monster"):
		var damage=equipped_weapon.damage
		body.take_damage(damage)
	pass # Replace with function body.
