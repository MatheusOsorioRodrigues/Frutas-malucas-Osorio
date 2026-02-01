extends Control

func _on_chest_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_map.tscn")
#quando o botao do bau é apertado nos leva devolta a cena com as fases
