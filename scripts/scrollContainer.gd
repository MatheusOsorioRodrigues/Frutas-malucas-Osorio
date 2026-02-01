extends ScrollContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("init_scroll")
	
func init_scroll():
	var current_level:int = Global.current_level 
	
	#Move o scroll próximo ao ultimo level aberto. (Não funciona direito pois as
	#distancia da colisões na imagem é totalmente diferente :/ 
	#Adicionei para pegar as posições de dois niveis e medir a distância, funciona melhor
	var v_scroll:VScrollBar = get_v_scroll_bar()
	v_scroll.allow_greater = true
	var pos_current_level = get_node("../").collision_shapes[current_level - 1]["original_y"]
	var pos_below_level = get_node("../").collision_shapes[current_level - 2]["original_y"]
	var distance_levels = abs(pos_current_level - pos_below_level)
	v_scroll.set_value_no_signal(320.0 - (distance_levels * (current_level - 2) )) 
	v_scroll.allow_greater = false

	get_node("../")._update_collisions_positions(v_scroll.value) 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
