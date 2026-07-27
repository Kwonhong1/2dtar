extends CharacterBody2D

enum State{
	IDLE,
	CHASE,
	RETURN,
	ATTACK,
	DEAD
}



signal enemy_died



@export_category("Related Scenes")

@export var enemy_data: Enemydata

@export_category("Stats")
var state:State=State.IDLE
var speed: int =128
var attack_damage:int=10
var attack_speed: float =1.0
var hitpoints:int =180
var aggro_range: float =256.0
var attack_range:float=150
var exp_reward:int=600


@onready var spawn_point: Vector2 = global_position
@onready var animation_tree: AnimationTree=$AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback=$AnimationTree["parameters/playback"]
@onready var player: CharacterBody2D=get_tree().get_first_node_in_group("player")
@onready	 var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_hitbox:CollisionShape2D=$Hitbox/CollisionShape2D


func  _ready() ->void:
	animation_tree.set_active(true)
	if enemy_data:
		speed=enemy_data.speed
		hitpoints=enemy_data.hitpoints
		aggro_range=enemy_data.aggro_range
		attack_range=enemy_data.attack_range
		attack_speed=enemy_data.attack_speed
		attack_damage=enemy_data.attack_damage
		if enemy_data.sprite_texture:
			$Sprite2D.texture=enemy_data.sprite_texture
			
func _physics_process(delta: float) -> void:
	if state==State.DEAD:
		return
	if state==State.ATTACK:
		return
	if distance_to_player() <= attack_range:
		state=State.ATTACK
		attack()
	elif distance_to_player() <=aggro_range:
		state=State.CHASE
		move()
	elif global_position.distance_to(spawn_point)>32:
		state=State.RETURN
		move()
	elif state != State.IDLE:
		state=State.IDLE
		update_animation()
		
		
		
func distance_to_player() ->float:
	return global_position.distance_to(player.global_position)
	
	
	
func move() -> void:
	if state == State.CHASE:
		nav_agent.target_position = player.global_position
	elif state == State.RETURN:
		nav_agent.target_position=spawn_point
	var next_path_position: Vector2=nav_agent.get_next_path_position()
	velocity=global_position.direction_to(next_path_position)*speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)
	move_and_slide()
	
	if state==State.IDLE or State.CHASE:
		if velocity.x<-0.01:
			$Sprite2D.flip_h=true
		if velocity.x>0.01:
			$Sprite2D.flip_h=false
			
	update_animation()
func update_animation() ->void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.CHASE or State.RETURN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")

func attack() -> void:
	if not player:
		state = State.IDLE
		return
	
	var attack_dir: Vector2 = (player.position - global_position).normalized()
	$Sprite2D.flip_h=attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	
	update_animation()	
	
	if enemy_data is MeleeEnemyData:
		# 1. 💡 공격 판정 시작 (히트박스 켜기)
		if attack_hitbox:
			attack_hitbox.disabled = false
			
		# 2. 0.2초 동안 공격 판정 유지
		await get_tree().create_timer(0.2).timeout
		if attack_hitbox:
			attack_hitbox.disabled = true
		await get_tree().create_timer(attack_speed).timeout
		state=State.IDLE
	elif enemy_data is RangedEnemyData:
		shoot_projectile(attack_dir)
	await get_tree().create_timer(enemy_data.attack_speed).timeout
	state=State.IDLE

func shoot_projectile(dir:Vector2)->void:
	if enemy_data is RangedEnemyData and enemy_data.projectile_scene:
		var proj=enemy_data.projectile_scene.instantiate()
		proj.global_position=global_position
		get_tree().current_scene.add_child(proj)

#damage
func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()
		

func death() -> void:
	emit_signal("enemy_died")
	queue_free()
	


func _on_hitbox_area_entered(area: Area2D) -> void:
	area.owner.take_damage(attack_damage)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	nav_agent.velocity = safe_velocity
