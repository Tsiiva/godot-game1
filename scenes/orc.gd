extends CharacterBody2D

const SPEED = 50.0
const ATTACK_RANGE = 25.0       # distance à laquelle il se met à frapper
const ATTACK_DAMAGE = 10
const ATTACK_COOLDOWN = 1.0     # secondes entre deux attaques
const HIT_FRAME = 2             # frame d'orc_attack où l'arme frappe
const SPRITE_FACES_LEFT = false # à tester, voir plus bas

@onready var target = $"../Player"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackOrc

var health := 50
var facing := 1
var is_attacking := false
var is_hurt := false
var is_dead := false
var can_attack := true
var attack_area_x := 0.0

signal died


func _ready() -> void:
	attack_area_x = abs(attack_area.position.x)
	add_to_group("enemies")
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	#print(sprite.sprite_frames.get_animation_names())


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead:
		velocity.x = 0
		move_and_slide()
		return

	var dx = target.global_position.x - global_position.x

	# Il se tourne vers le joueur (sauf en pleine attaque ou blessé)
	if not is_attacking and not is_hurt and dx != 0:
		facing = 1 if dx > 0 else -1
		update_facing()

	# La petite IA
	if is_attacking or is_hurt or target.is_dead:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif abs(dx) > ATTACK_RANGE:
		velocity.x = facing * SPEED
	else:
		velocity.x = 0
		if can_attack:
			start_attack()

	move_and_slide()
	update_animation()


func update_facing() -> void:
	sprite.flip_h = (facing == 1) if SPRITE_FACES_LEFT else (facing == -1)
	attack_area.position.x = attack_area_x * facing
	#print("facing = ", facing, " | scale AttackOrc = ", attack_area.scale)


func start_attack() -> void:
	is_attacking = true
	can_attack = false
	sprite.play("orc_attack")
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true


func update_animation() -> void:
	if is_attacking or is_hurt or is_dead:
		return
	if abs(velocity.x) > 1:
		sprite.play("orc_walk")
	else:
		sprite.play("orc_idle")


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		sprite.play("orc_hurt")


func die() -> void:
	is_dead = true
	is_attacking = false
	is_hurt = false
	sprite.play("orc_death")
	remove_from_group("enemies")
	collision_layer = 0   # plus de collision avec le joueur, mais il reste posé au sol
	died.emit()
	


func _on_frame_changed() -> void:
	if sprite.animation == "orc_attack" and sprite.frame == HIT_FRAME:
		deal_damage()


func deal_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body == target and body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)


func _on_animation_finished() -> void:
	if sprite.animation == "orc_attack":
		is_attacking = false
	elif sprite.animation == "orc_hurt":
		is_hurt = false
	elif sprite.animation == "orc_death":
		queue_free()   # le cadavre disparaît à la fin de l'animation
