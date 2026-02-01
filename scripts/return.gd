extends Control


func _on_return_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/level_map.tscn")
