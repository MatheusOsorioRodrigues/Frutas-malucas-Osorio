extends VBoxContainer

var index:int = 0
var character_name:String = ""
var characters:Array = [
	{"Crimson": preload("res://actors/Char_Hood.tscn")},
	{"Hickory": preload("res://actors/Char_Florest.tscn")}
]

var characters_power= {
	"name":
		["Fruit Swap", "Fencebreaker"],
	"description": 
		["Identifica a primeira peça que está fora da posição correta e a substitui pela peça adequada.",
		"Detecta o primeiro obstáculo no caminho e o remove."]
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_character_display()

func update_character_display() -> void:
	#Deleta as instancias anteriores
	var container:SubViewportContainer = $ContentArea/Character/SubViewportContainer
	for child in container.get_children():
		child.queue_free()
	
	var current_char:Dictionary = characters[index]
	#var char_name:String = current_char.keys()[0]
	character_name = current_char.keys()[0]
	var char_scene:PackedScene = current_char.values()[0]
	
	#Muda os textos do label de acordo com o personagem
	$CharacterNav/CharacterName.text = character_name
	$ContentArea/Character/CharacterLevel.text = "LV. %d" % Global.character_levels[character_name]
	$ContentArea/ContentText/PowerDesc.text = characters_power["description"][index]
	$ContentArea/ContentText/PowerTitle.text = characters_power["name"][index]
	
	#Instacia e posiciona o personagem
	var character_instance:CharacterBody2D = char_scene.instantiate()
	character_instance.position = Vector2(20, 18)
	character_instance.scale = Vector2(1.4, 1.4)
	
	if character_name not in Global.unlocked_characters: 
		character_instance.modulate = Color(0, 0, 0) #Aplico cor preta ao personagem não desbloqueado
		$ContentArea/ContentText/ContainerBuy/BuyControl/Price.text = "150" # Preço base para desbloquear
		#$ContainerBuy/BuyControl/Text.text = "Desbloquear \nPersonagem"
		$ContentArea/ContentText/ContainerBuy/BuyControl/Text.text = "Desbloquear"
	else:
		#$ContainerBuy/BuyControl/Text.text = "Melhorar \nPersonagem"
		$ContentArea/ContentText/ContainerBuy/BuyControl/Text.text = "Melhorar"
		$ContentArea/ContentText/ContainerBuy/BuyControl/Price.text = str(Global.character_levels[character_name] * 150)
		
	container.add_child(character_instance) #Adiciona personagem a cena
	$Coins/CoinAnimation/LabelCoins.text = str(Global.Coins)  #Atualiza quantidaade de moedas no label
	

func _on_buy_button_pressed() -> void:
	#Obtem o personagem e o seu valor
	var item_price:int = int($ContentArea/ContentText/ContainerBuy/BuyControl/Price.text)
	character_name = $CharacterNav/CharacterName.text
	
	if character_name not in Global.unlocked_characters:
		if Global.Coins >= item_price:
			Global.Coins -= item_price
			Global.unlocked_characters.append(character_name)
			update_character_display()
			
	else: #Se o personagem já estiver desbloqueado, melhora de nivel
		if Global.Coins >= item_price:
			Global.Coins -= item_price
			Global.character_levels[character_name] += 1
			update_character_display()
	
	Global.save_game()


func _on_next_button_pressed() -> void:
	 # "Loopa" o index para acessar os personagens de forma circular
	index = (index + 1) % characters.size()
	update_character_display()

func _on_previous_button_pressed() -> void:
	index = (index - 1) % characters.size()
	update_character_display()

func _on_select_char_button_pressed() -> void:
	if character_name in Global.unlocked_characters:
		Global.selected_character = character_name
