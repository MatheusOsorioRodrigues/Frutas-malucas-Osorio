extends Area2D

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var CoinsCounter = $CoinsCounter

var total_levels = 11
var scroll_till_bottom = 160 * 2 #Tamanho da tela vertical * numero de telas extras
var sprite_leaf = load("res://sprites/Others/fallen_leaves.png")
var collision_shapes = []
var node_leaves = []

func _ready() -> void:
	# Obtens todos os objetos de colisões dos 'botões' de seleção de niveis
	var levels_parent = $SelectLevels
	for level in levels_parent.get_children():
		var collision = level.get_node("Collision")
		collision_shapes.append({
		"node": collision,
		"original_x": collision.position.x,
		"original_y": collision.position.y
		})
	
	create_leaves_sprites()
	
	# Conecta o sinal de scroll
	var v_scroll:VScrollBar = scroll_container.get_v_scroll_bar()
	v_scroll.value_changed.connect(_update_collisions_positions)

	#faz o label receber o valor das moedas
	CoinsCounter.text = str(Global.Coins)
	
func _update_collisions_positions(scroll_value: float) -> void:
	for i in range(collision_shapes.size()):
		collision_shapes[i].node.position.y = collision_shapes[i]["original_y"] + scroll_till_bottom - scroll_value
	
	for leaf in node_leaves:
		var collision_index = leaf.get_meta("collision_index")
		leaf.position.y = collision_shapes[collision_index]["original_y"] + scroll_till_bottom - scroll_value

func _process(delta: float) -> void:
	pass
	
func create_leaves_sprites():
	#Elimina os sprite de chamadas anteriores da cena
	for leaf in node_leaves:
		leaf.queue_free()
	node_leaves.clear()
	
	var leaves:Node2D =$Leaves	
	# Cria folhas apenas para níveis bloqueados
	var first_blocked_level = Global.higher_level_completed + 1
	for i in range(first_blocked_level, collision_shapes.size()):
		var leaf:Sprite2D = Sprite2D.new()
		leaf.texture = sprite_leaf
		leaf.scale = Vector2(0.06, 0.06)
		leaf.position = Vector2(
			collision_shapes[i]["original_x"],
			collision_shapes[i]["original_y"]
		)
		leaf.set_meta("collision_index", i)
		leaves.add_child(leaf)
		node_leaves.append(leaf)
		collision_shapes[i]["node"].disabled = true


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_config_button_pressed() -> void:
	pass

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
