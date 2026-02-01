extends AudioStreamPlayer2D


var level_music
func _ready():
	level_music = load("res://music/Jeremy Blake - Powerup!.mp3")

func _play_music(music: AudioStream, volume = -20.0):
	if stream == music:
		return

	stream = music
	volume_db = volume
	play()

func play_music_level():
	_play_music(level_music)
