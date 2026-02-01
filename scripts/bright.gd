extends Node2D

@onready var bright = $Bright
@onready var bright_scale = bright.scale

func _ready():
	animar_brilho()

func animar_brilho():
	var tween = create_tween()
	tween.set_loops() # Faz a animação rodar infinitamente
	
	bright_scale += Vector2(0.09, 0.09)
	# Aumenta o tamanho do brilho
	tween.tween_property(bright, "scale", bright_scale, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	bright_scale -= Vector2(0.09, 0.09)
	# Diminui o tamanho do brilho
	tween.tween_property(bright, "scale", bright_scale, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
