extends Control

var is_new_game:bool
func _ready() -> void:
	MusicGame.play_music_level()
	is_new_game = Global.initialize_game()

func _on_config_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")

func _on_play_button_pressed() -> void:
	if is_new_game:
		get_tree().change_scene_to_file("res://scenes/selection.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/level_map.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
