extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPRITE_FACES_LEFT = false
const HIT_FRAME = 2              # la frame de l'attaque où la hache frappe

@onready var attack_area: Area2D = $AttackArea
var facing := 1                  # 1 = droite, -1 = gauche
#var attack_area_x := 0.0

var health := 100
var is_attacking := false
var is_hurt := false
var is_dead := false

signal died


func _ready() -> void:
	# On écoute le signal "l'animation vient de se terminer"
	#attack_area_x = abs(attack_area.position.x)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Mort : on ne contrôle plus rien
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return

	# Attaque
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_hurt:
		is_attacking = true
		sprite.play("attack")

	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking and not is_hurt:
		velocity.y = JUMP_VELOCITY

	# Déplacement
	var direction := Input.get_axis("move_left", "move_right")
	if is_attacking or is_hurt:
		velocity.x = move_toward(velocity.x, 0, SPEED)  # il glisse jusqu'à l'arrêt
	elif direction:
		velocity.x = direction * SPEED
		facing = sign(direction)
		sprite.flip_h = (facing == 1) if SPRITE_FACES_LEFT else (facing == -1)
		attack_area.scale.x = facing
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animation(direction)


func update_animation(direction: float) -> void:
	# Si une animation "spéciale" est en cours, on ne touche à rien
	if is_attacking or is_hurt or is_dead:
		return
	if direction != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")  # si tu n'as pas d'animation idle, voir note plus bas


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false  # être touché interrompt l'attaque
		sprite.play("hurt")


func die() -> void:
	is_dead = true
	is_attacking = false
	is_hurt = false
	sprite.play("death")
	died.emit()


func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
	elif sprite.animation == "hurt":
		is_hurt = false
	# "death" : on ne fait rien, le soldat reste sur la dernière image

func _on_frame_changed() -> void:
	# On frappe une seule fois, à la frame où la hache touche
	if sprite.animation == "attack" and sprite.frame == HIT_FRAME:
		deal_damage()


func deal_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(25)
