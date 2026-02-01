extends Control



func _ready() -> void:
	MusicGame.play_music_level()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")



func _on_mastervolume_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)
