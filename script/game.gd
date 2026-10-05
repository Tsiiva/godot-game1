extends Node2D

const ORC_SCENE = preload("res://scenes/orq.tscn")
const START_DELAY = 3.0     # délai entre deux orcs au début
const MIN_DELAY = 0.8       # délai minimum : ne descend jamais en dessous
const DELAY_STEP = 0.05     # de combien le délai raccourcit à chaque orc
const MAX_ORCS = 8          # nombre max d'orcs vivants en même temps

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_points: Array = [$SpawnLeft, $SpawnRight]
@onready var player = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverPanel/VBoxContainer/RestartButton

var score := 0
var spawn_delay := START_DELAY


func _ready() -> void:
	spawn_timer.wait_time = spawn_delay
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	player.died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart_pressed)
	print("Panel : ", game_over_panel.get_global_rect())
	#print("Label : ", score_label.get_global_rect())
	#print("Écran : ", get_viewport().get_visible_rect())


func _on_spawn_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("enemies").size() < MAX_ORCS:
		spawn_orc()
	# Le prochain orc arrivera un peu plus vite
	spawn_delay = max(MIN_DELAY, spawn_delay - DELAY_STEP)
	spawn_timer.wait_time = spawn_delay


func spawn_orc() -> void:
	var orc = ORC_SCENE.instantiate()
	add_child(orc)
	orc.global_position = spawn_points.pick_random().global_position
	orc.died.connect(_on_orc_died)


func _on_orc_died() -> void:
	score += 1
	score_label.text = "Score : " + str(score)


func _on_player_died() -> void:
	spawn_timer.stop()
	final_score_label.text = "Score final : " + str(score)
	game_over_panel.show()


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
