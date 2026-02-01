extends Area2D

#OBS: Precisa generalizar para funcionar em tabuleiros 3x3, 4x4, 5x5
const BOARD_OFFSET_X: int = 5 #Espaço da borda da tela
const BOARD_OFFSET_Y: int = 52
const BOARD_SIZE: int = 80
const TILES_COLORS = [Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 1.0), Color(1.0, 1.0, 0.0),
 Color(0.0, 1.0, 0.0), Color(1.0, 0.67, 0.11), Color(1.0, 0.07, 0.57), Color(0.1, 0.1, 0.9)]
# Carrega as frutas e os fundos
const FRUIT_SCENE:PackedScene = preload("res://actors/fruit.tscn") 
const EMPTY_SCENE:PackedScene = preload("res://actors/empty.tscn")
const BACKGROUND_SCENE:PackedScene = preload("res://actors/tile_background.tscn")
const CHEST_SCENE:PackedScene = preload("res://scenes/chest_scene.tscn")
const TILE_BRIGHT:PackedScene = preload("res://actors/tile_bright.tscn")

var grid_size: int
var tile_count: int
var time_to_finish: int
var boss_power_time:int = 20
var current_tile_src: int = -1
var current_tile_dst: int = -1
var power_charges: int = Global.character_levels[Global.selected_character]
var is_power_used: bool = false
var scale_tile: float
var tile_size: float
var boss_power_used:bool = false 
var enable_boss_infinite_level:bool = false
var tiles: Array = []
var solved_rows: Array = []
var restrictions: Array = [] 
var fences: Array = []
var map:Array = []
var player: CharacterBody2D
var boss_power_animation_timer:Timer = Timer.new()

@onready var timer = $Timer
@onready var label = $"Timer Game"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_background()
	start_game()
	call_deferred("initialize_player")
	
	timer.wait_time = time_to_finish
	timer.start()
	boss_power_animation_timer.timeout.connect(_on_animation_timer_timeout)
	add_child(boss_power_animation_timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = "%02d: %02d" % time_left()
	
	if Global.current_level % 10 == 0 or enable_boss_infinite_level:
		#Chama a animação 3 segundos antes do swap
		if time_left()[1] % boss_power_time == 3 and !boss_power_used:
			boss_power_animation()
			boss_power_used = true
			boss_power_animation_timer.start(3)
		elif time_left()[1] % boss_power_time != 5:
			boss_power_used = false
	
func initialize_player():
	player = get_node_or_null("../Character/Player")
	player.board = self #Passa o objeto para o acesso das variaveis internas
	player.power_used.connect(_on_power_used)
	player.get_child(0).visible = true #Torna vísivel o efeito atrás do personagem

func _on_power_used():
	if power_charges > 0:
		power_charges -= 1

func generate_infinite_level() -> void:
	var base_grid_size = 3
	 #A cada 5 niveis compretado aumenta o tamanho do grid
	var size_increase = floor((Global.infinite_level - 1) / 4)
	grid_size = clamp(base_grid_size + size_increase, 3, 7) #Trava os valores entre 3 e 7
	tile_count = grid_size * grid_size
	time_to_finish = 60 + grid_size * (10 + Global.infinite_level)
	
	#Causa niveis insoluveis :/ 
	#enable_boss_infinite_level = Global.infinite_level >= 10 # Ativa a mecaninca do boss fazer 10 niveis
	#boss_power_time = 40 - Global.infinite_level
	
	var fruits = ["Apple", "Grape", "Banana", "Pear", "Orange", "DragonFruit", "BlueBerry"]
	solved_rows = []
	
	#Cria o vetor com as frutas nas posições corretas de acordo com o tamanho do grid
	for row in range(grid_size):
		var fruit_type = fruits[row % fruits.size()]
		for col in range(grid_size):
			if col == grid_size - 1 and row == col:
				map.append("Empty")
				break
			var tile_name = "%s%d" % [fruit_type, col + 1]
			map.append(tile_name)
	
	#Cria a matriz com as linhas nas posições certas, usada em is_solved
	var aux = []
	for i in range(0, tile_count):
		aux.append(str(map[i]))
		if (i + 1) % grid_size == 0:
			solved_rows.append(aux)
			aux = []

	restrictions = []
	restrictions.resize(tile_count)
	restrictions.fill("free")
	
	#A cada 3 niveis completado aumenta o numeros de restrições, trava o valor entre 0 e 
	#-3 da quantidade de peças (tem que ser testado para, com a adição de muitas restições 
	#provalvemente deve gerar um tambuleiro mais facil de resolver
	var num_fences = clamp(floor(Global.infinite_level / 3) + 1, 0, tile_count - 3)
	
	#Aleatoariza as posições das cercas
	for i in range(num_fences):
		var pos = randi() % (tile_count - 1)
		
		#Ignora configuração problematica com o poder de trocar peça (3x3, com restrição total no meio)
		if grid_size == 3 and pos == 4: 
			pos += 1
			
		if restrictions[pos] == "free":
			var fence_types = ["locked", "horizontal_locked", "vertical_locked"]
			restrictions[pos] = fence_types[randi() % fence_types.size()]
	

func start_game() -> void:
	if Global.current_level == 11: #Nivel infinito
		generate_infinite_level()
	else:
		var level = "res://levels/level%s.json" % Global.current_level
		var file:FileAccess = FileAccess.open(level, FileAccess.READ)
		var text:String = file.get_as_text()
		var data:Dictionary = JSON.parse_string(text)

		#Define valores para a construção do tabuleiro
		#var map:Array = data["map"] #O mapa com a ordem que as peças estarão
		map = data["map"] #O mapa com a ordem que as peças estarão
		grid_size = (data["size"]) #Tamanho do map
		restrictions = data["restrictions"] #Lugares onde há restrições(cercas)]
		time_to_finish = data["time"]
		solved_rows = data["solved"]
	
	tile_count  = grid_size * grid_size #Quantidade de peças
	tile_size = BOARD_SIZE / grid_size #Define o tamanho da peça em pixels
	scale_tile = 0.14 / grid_size #Escala para transformar o sprite original no tamanho do tile_size
	
	# Referências para os nós pais ondes as frutas e o fundo serão instanciados
	var fruits_parent:Node2D = get_node("Frutas")
	var backgrounds_parent:Node2D = get_node("FundosPeca")

	#Ajusta local da peças, já que a escala aumenta o tamanho da peças em todos sentidos
	var tile_offset:float = 42 / grid_size 
	
	#Instacia os sprites da fruta
	for i in range(tile_count):
		var fruit_instance:Sprite2D = FRUIT_SCENE.instantiate()
		var fruit_texture:Texture
		
		if map[i].contains("Apple"):
			fruit_texture = load("res://sprites/Fruits/AppleNL_HL.png") 
		elif map[i].contains("Grape"):
			fruit_texture = load("res://sprites/Fruits/PurplegrapeNL_HL.png") 
		elif map[i].contains("Banana"):
			fruit_texture = load("res://sprites/Fruits/BananaNL_HL.png")
		elif map[i].contains("Pear"):
			fruit_texture = load("res://sprites/Fruits/PearNL_HL.png")
		elif map[i].contains("Orange"):
			fruit_texture = load("res://sprites/Fruits/OrangeNL_HL.png")
		elif map[i].contains("DragonFruit"):
			fruit_texture = load("res://sprites/Fruits/DragonFruitNL_HL.png")
		elif map[i].contains("BlueBerry"):
			fruit_texture = load("res://sprites/Fruits/BlueberryNL_HL.png")
		elif map[i].contains("Empty"):
			fruit_instance = EMPTY_SCENE.instantiate()
			
		fruit_instance.name = map[i] 
		fruit_instance.texture = fruit_texture
		
		tiles.append(fruit_instance) #Adiciona a instacia no array do estado atual do board
		fruits_parent.add_child(fruit_instance)
		
	#Instacia cada fundo
	for i in range(grid_size):
		for j in range(grid_size):
			var background_instance: Sprite2D
			background_instance = BACKGROUND_SCENE.instantiate()
			background_instance.scale = Vector2(scale_tile, scale_tile)
			
			#Ignora o ultima peça na hora de colocar cor
			if (i * grid_size + j) != tile_count - 1:
				#background_instance.modulate = TILES_COLORS[i] 
				background_instance.modulate = TILES_COLORS[i % TILES_COLORS.size()] 
				
			#Muda a cor do fundo de acordo com  a linha atual
			background_instance.position = Vector2((tile_size * j + tile_offset), tile_size * i + tile_offset)
			backgrounds_parent.add_child(background_instance)
			
	var scale_fruit:float = 2.0 / grid_size 
	for i in range(grid_size):
		for j in range(grid_size):
			tiles[grid_size * i + j].position = Vector2(tile_size * j \
				+ tile_offset, tile_size * i + tile_offset)
			tiles[grid_size * i + j].scale = Vector2(scale_fruit, scale_fruit)
	
	instantiate_fences(restrictions)
	if Global.current_level <= Global.higher_level_completed or Global.current_level == 11: 
			while true: #Evite que o level aleatório esteja na posição resolvida
				shuffle_tiles()
				if !is_solved():
					break

func adjust_background() -> void:
	#Pega o tamanho da tela do dispositivo
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var background: Sprite2D = $Background

	var texture_size: Vector2 = background.texture.get_size()

	# Calcular escala
	var scale_x: float = screen_size.x / texture_size.x
	var scale_y: float = screen_size.y / texture_size.y

	var scale_factor: float = max(scale_x, scale_y)

	# Ajustar o sprite com o fator de escala
	background.scale = Vector2(scale_factor, scale_factor)
	
	# Ajustar a posição do sprite para manter o fundo centralizado
	var offset_x: float = (screen_size.x - texture_size.x * scale_factor) / 2
	var offset_y: float = (screen_size.y - texture_size.y * scale_factor) / 2
	background.position = Vector2(offset_x + 40, offset_y + 28)
	#background.position = Vector2(offset_x + 42, offset_y + 58)
	
func instantiate_fences(restrictions: Array) -> void:
	#Dependendo do tipo de restrição instancia a cena da cerca
	var scene: PackedScene
	for i in range(len(restrictions)):
		match restrictions[i]:
			"free":
				fences.append(null)
				continue
			"locked":
				scene = load("res://actors/fullFence.tscn")
			"horizontal_locked":
				scene = load("res://actors/verticalFence.tscn")
			"vertical_locked":
				scene = load("res://actors/horizontalFence.tscn")

		var instance: Node2D = scene.instantiate()
		#Calcula a posição da cerca na tela de acordo com a posição da restrição
		instance.position.x += (i % grid_size) * tile_size
		instance.position.y += (i / grid_size) * tile_size
		instance.scale = Vector2(4.0 / grid_size, 4.0 / grid_size)
		
		add_child(instance)
		fences.append(instance)
		
		#Caso o nível esteja sendo jogado denovo, aleatoriza os locais das peças

#Procura pelo espaço vazio
func find_empty() -> int:
	for count in range(tile_count):
		if tiles[count] == $Frutas/Empty:
			return count
	return -1

#Verifica quais são os vizinhos ortoganais do espaço vazinho
func empty_neighbours(empty: int, restrictions: Array) -> Array:
	var directions: Array = [
		-grid_size,   # baixo
		grid_size,  # cima
		1,   # direita
		-1   # esquerda
	]

	var neighbours: Array = []
	for direction in directions:
		var neighbour: int = empty + direction

		#Ignora vizinhos que estrapolam os limites do tabuleiro
		if neighbour < 0 or neighbour >= tile_count:
			continue
		
		#Impede que a peça mova da ultima coluna para a primeira da próxima linha e vice-versa
		#Att: é necessaria :)
		if direction == 1 and empty % grid_size == grid_size - 1:
			continue  
		if direction == -1 and empty % grid_size == 0:
			continue  
		
		#Caso haja uma restrição horizontal, ignora as movimentação para esquerda e direita
		if direction in [1, -1] and restrictions[neighbour] == "horizontal_locked":
			continue
			
		#Caso haja uma restrição vertical, ignora as movimentação para cima e baixo
		if direction in [grid_size, -grid_size] and restrictions[neighbour] == "vertical_locked":
			continue
			
		neighbours.push_back(neighbour)

	return neighbours

#Escolhe um dos vizinho do espaço vazio a ser movido (Provavelmente sera retirado
#E usado nivel criado manualmente
func choose_neighbour(neighbours: Array) -> int:
	randomize()
	var random_index: int = randi() % neighbours.size()
	return neighbours[random_index]

func shuffle_tiles() -> void:
	#Bem direto, acha o espaço vazio, ve quem são os vizinho e escolhe aleatoriamente um deles
	for t in range(1000 * grid_size):
		var empty: int = find_empty()
		var neighbours: Array = empty_neighbours(empty, restrictions)
		var moved_tile: int = choose_neighbour(neighbours)

		swap_tiles(empty, moved_tile, "random")

func extract_fruit_name(fruit_name) -> String:
	"""Remove os valores numéricos dos nomes dos nós das frutas"""
	var name:String = ""
	
	for character in str(fruit_name):
		if character.is_valid_int():
			break
		name += character
	
	return name 

func find_fruit_in_order() -> int:
	#Encontra a primeira fruta que está na posição correta
	
	var fruis_in_the_right_row = []
	for row in range(grid_size):
		# Obtém o nome da fruta esperada para esta linha a partir do solved
		var expected_fruit = extract_fruit_name(solved_rows[row][0])
		for col in range(grid_size):
			var index:int = row * grid_size + col
			#Não permite que a fruta a ser mexida contenha restrições, poderia tornar o tabuleiro não solucionavel
			if restrictions[index] != "free": 
				continue
				
			var tile:Sprite2D = tiles[index]
			if extract_fruit_name(tile.name) == expected_fruit: 
				fruis_in_the_right_row.append(index)
				#return index #Retorna o indice da fruta correta
	
	if len(fruis_in_the_right_row) > 0:
		var fruit_index = randi() % fruis_in_the_right_row.size()
		return fruis_in_the_right_row[fruit_index]
		
	return -1 # Não há fruta na linha correta

func boss_power_animation() -> void:
	current_tile_src = find_fruit_in_order()
	current_tile_dst = -1

	#Escolhe aleatoriamente, onde a troca ocorrera. 
	while true:
		current_tile_dst = randi() % tile_count
		if restrictions[current_tile_dst] == "free": #Evita peça com restrição
			break

	if current_tile_src != -1:
		# Limpa brilhos das peças anteriores
		for child in $BrightsTiles.get_children():
			child.queue_free()

		# Cria novos brilhos
		var bright_instance_src = TILE_BRIGHT.instantiate()
		bright_instance_src.position = tiles[current_tile_src].position
		bright_instance_src.scale = Vector2(scale_tile, scale_tile)
		$BrightsTiles.add_child(bright_instance_src)

		var bright_instance_dst = TILE_BRIGHT.instantiate()
		bright_instance_dst.position = tiles[current_tile_dst].position
		bright_instance_dst.scale = Vector2(scale_tile, scale_tile)
		$BrightsTiles.add_child(bright_instance_dst)

func _on_animation_timer_timeout() -> void:
	if current_tile_src != -1 && current_tile_dst != -1:
		#Depois da animação faz a troca
		swap_tiles(current_tile_src, current_tile_dst, "random")

		# Remove bordas brilhantes
		for child in $BrightsTiles.get_children():
			child.queue_free()

		#Reseta os índices
		current_tile_src = -1
		current_tile_dst = -1

func is_valid_position(position: Vector2) -> bool:
	#Restringe o clique apenas a região do tabuleiro
	#84x84 é o tamanho do tabuleiro
	return position.x >= BOARD_OFFSET_X and position.x < BOARD_OFFSET_X + BOARD_SIZE  \
	and position.y >= BOARD_OFFSET_Y and position.y < BOARD_OFFSET_Y + BOARD_SIZE

func swap_tiles(tile_src: int, tile_dst: int, type_caller: String) -> void:
	if restrictions[tile_dst] == "locked":
		return
	#Troca a posição da peça pelo espaço vazio no sprite
	var temp_pos: Vector2 = tiles[tile_src].position
	tiles[tile_src].position = tiles[tile_dst].position
	tiles[tile_dst].position = temp_pos

	#Troca de posição da peça pelo espaço vazio no vetor
	var temp_tile: Sprite2D = tiles[tile_src]
	tiles[tile_src] = tiles[tile_dst]
	tiles[tile_dst] = temp_tile
	
	#Troca as posições das restrições
	var temp_restriction: String = restrictions[tile_src]
	restrictions[tile_src] = restrictions[tile_dst]
	restrictions[tile_dst] = temp_restriction

	var temp_fence: Node2D = fences[tile_src]
	fences[tile_src] = fences[tile_dst]
	fences[tile_dst] = temp_fence

	# Atualize a posição dos sprites de fences
	if fences[tile_src] != null and fences[tile_src].name != "free":
		fences[tile_src].position.x = (tile_src % grid_size) * tile_size
		fences[tile_src].position.y = (tile_src / grid_size) * tile_size

	if fences[tile_dst] != null and fences[tile_dst].name != "free":
		fences[tile_dst].position.x = (tile_dst % grid_size) * tile_size
		fences[tile_dst].position.y = (tile_dst / grid_size) * tile_size
	
	if type_caller == "Player":
		if is_solved():
			print("Resolvido")
			Global.CoinsEd =(100-(60 - time_left()[1]))
			#60 segundos, realiza a soma das moedas em questao ao tempo gasto quanto mais tempo gasto menos moedas
			
			#Evita que ao completar novamente niveis mais baixo libere os mais acima
			if Global.current_level - 1 == Global.higher_level_completed and Global.current_level != 11:
				Global.higher_level_completed += 1 
			elif Global.current_level != 11: #Ignora para os niveis infinitos
				Global.CoinsEd /= 10 #Caso o nivel seja rejogado a recompensa é menor
			
			if Global.current_level == 11:
				Global.infinite_level += 1
				
			Global.Coins += (Global.CoinsEd)
			Global.save_game()
			#Carregar a cena no inicio do nivel evita queda de FPS, quando ela é mudada
			get_tree().change_scene_to_packed(CHEST_SCENE)
			#get_tree().change_scene_to_file("res://scenes/chest_scene.tscn")
			
func handle_mouse_click(mouse_position: Vector2) -> void:
	if !is_valid_position(mouse_position):
		return

	var rows: int = int((mouse_position.y - BOARD_OFFSET_Y) / (tile_size))
	var cols: int = int((mouse_position.x - BOARD_OFFSET_X) / (tile_size))
	var pos: int = rows * grid_size + cols #Posição no vetor unidimensional

	#Se a peça clicacada for toltamente cercada é ignorada
	if restrictions[pos] == "locked":
		return
		
	var empty: int = find_empty()
	var neighbours: Array = empty_neighbours(empty, restrictions)

	#Verifica se a peça que o jogador clicou é vizinha ao espaço vazio
	if pos in neighbours:
		swap_tiles(empty, pos, "Player")

func is_solved() -> bool:
	var aux: Array = []
	var actual_rows: Array = []
	#Verifica se o espaço vazio está na ultima posição(canto inferior direito) (verificação mais rapida)
	if find_empty() != tile_count - 1:
		return false

	#Meio repetitivo provalmente tem uma solução melhor
	#Transforma o vetor unidimension do estado atual do tabuleiro em um vetor MxN
	for i in range(0, tile_count):
		aux.append(str(tiles[i].name))
		if (i + 1) % grid_size == 0:
			actual_rows.append(aux)
			aux = []
	
	"""Diferente do 15tile padrão que a ordem é numérica de 1a16, aqui precisa
	estar apenas com cada elemento na sua linha correta sem importar a coluna"""
	for i in range(0, actual_rows.size()):
		actual_rows[i].sort()
		solved_rows[i].sort()
		
		#Caso um elemento esteja fora da sua linha esperada retorna falso
		if actual_rows[i] != solved_rows[i]:
			return false

	return true

func time_left():
	var time_left = timer.time_left
	var minute = floor(time_left /60)
	var second = int(time_left) %60
	#var second2 = int(time_left) %60
	return [minute,second]
	#realiza o contador dentro do jogo
	
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_mouse_click(event.position)
