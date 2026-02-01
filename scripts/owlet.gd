extends CharacterBody2D

@export var characterPath: String
@export var characterTexture: AnimatedSprite2D
var board: Area2D
signal power_used(wrong: int, candidate: int)

### 

func _ready() -> void:
	pass
	#$AnimatedSprite2D.play("idle")
	#$EffectChargedPower/CharacterShade.play("idle")
	
func extract_fruit_name(fruit_name):
	"""Remove os valores numéricos dos nomes dos nós das frutas"""
	var name = ""
	
	for character in str(fruit_name):
		if character.is_valid_int():
			break
		name += character
	
	return name 
	
func use_power(tiles, solved) -> Array:
	for row in range(board.grid_size):
		# Obtém o nome da fruta esperada para esta linha a partir do solved
		var expected_fruit = extract_fruit_name(solved[row][0])
		for col in range(board.grid_size):
			var index = row * board.grid_size + col
			var tile = tiles[index]
			var actual_fruit = extract_fruit_name(tile.name)
		
			# Caso especial para "Empty" na última posição da quarta linha
			if row == board.grid_size - 1 and col == board.grid_size - 1 and actual_fruit == "Empty":
				continue  # É permitido, então ignora
		
			# Procura pela fruta certa para o lugar onde a primeira fora de lugar foi encontrada
			if actual_fruit != expected_fruit:
				var candidate_index = -1
				#Começa de traz para frente, para buscar a fruta mais distante
				for i in range(len(tiles) - 1, -1, -1): 
					var candidate_row = i / board.grid_size
					var candidate_fruit = extract_fruit_name(tiles[i].name)
					# 'candidate_row' ignora caso a fruta já esteja na linha correta
					if candidate_fruit == expected_fruit and candidate_row != row:
						candidate_index = i
						break
				
				if candidate_index != -1:
					return [index, candidate_index]
				else:
					return [index,  -1]
	
	return [-1, -1]  # Todos estão na ordem correta

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if board != null and !board.is_power_used: #Caso o board tenha carregado e o poder ainda não foi usado
			#Inicia animação de ataque
			#$AnimatedSprite2D.play("attack")
			#$EffectChargedPower/CharacterShade.play("attack")
			var result:Array = board.player.use_power(board.tiles, board.solved_rows)
			emit_signal("power_used", result[0], result[1]) #Envia sinal com os blocos a serem trocados
			pass

func _on_animated_sprite_2d_animation_finished() -> void:
	pass
	#Espera a animação acabar para mover as peças
	#var result:Array = board.player.use_power(board.tiles, board.solved_rows)
	#emit_signal("power_used", result[0], result[1]) #Envia sinal com os blocos a serem trocados
	
	#$AnimatedSprite2D.play("idle")
	#$EffectChargedPower/CharacterShade.play("idle")
	#$EffectChargedPower.visible = false #Desativa aura do personagem
	
