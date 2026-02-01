extends Node2D

@onready var BOARD_SCENE:PackedScene = preload("res://scenes/main.tscn")

func _ready():
	#Conecta cada nivel a função que verifica se o click ocorre
	for level in range(1, 12):
		var node_name = "Level%02d" % level
		get_node(node_name).input_event.connect(_on_level_clicked.bind(level))

func _on_level_clicked(viewport, event, shape_idx, level_id):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#Define o valor da váriavel global que é usado em board.gd para montar o tabuleiro
		Global.current_level = level_id
		get_tree().change_scene_to_packed(BOARD_SCENE)
		
