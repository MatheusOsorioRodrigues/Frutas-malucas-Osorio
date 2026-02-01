extends Node

var CoinsEd = 0 #CoinsEd significa o valor de moedas ganhadas no final da fase
var TimeL = 0
var characters:Dictionary = {
	"Crimson": "res://actors/Char_Hood.tscn",
	"Hickory": "res://actors/Char_Florest.tscn",
	"Owlet": "res://actors/Char_Owlet.tscn",
	"Zinnia": "res://actors/Char_PinkMonster.tscn"
}

var current_level:int
var higher_level_completed:int
var infinite_level:int
var Coins:int
var selected_character:String
var unlocked_characters:Array = []
var character_levels:Dictionary = {}

func save_game():
	var save_file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	var save_data = {
		"selected_character": selected_character,
		"current_level": current_level,
		"higher_level_completed": higher_level_completed,
		"infinite_level": infinite_level,
		"Coins": Coins,
		"unlocked_characters": unlocked_characters,
		"character_levels": character_levels
	}
	
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)

func load_game():
	if not FileAccess.file_exists("user://save.dat"): #Não tem arquivo de salvamento ainda
		return false
	
	var save_file = FileAccess.open("user://save.dat", FileAccess.READ)
	var json_string = save_file.get_line()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Erro ao analisar o arquivo de salvamento!")
		return false
	
	var save_data = json.get_data()
	
	# Carregue os dados salvos nas variáveis globais
	selected_character = save_data["selected_character"]
	current_level = save_data["current_level"]
	higher_level_completed = save_data["higher_level_completed"]
	infinite_level = save_data["infinite_level"]
	Coins = save_data["Coins"]
	unlocked_characters = save_data["unlocked_characters"]
	character_levels = save_data["character_levels"]
	
	return true

#Inicializa as variaveis globais
func initialize_game():
	if not load_game():
		#Cria variáveis com valores padrões em um jogo novo
		selected_character = "Owlet"
		current_level = 1
		higher_level_completed = 0
		infinite_level = 1
		Coins = 0
		unlocked_characters = []
		character_levels = {
			"Crimson": 1,
			"Hickory": 1,
			"Owlet": 0,
			"Zinnia": 0
		}
		
		return true
	return false
