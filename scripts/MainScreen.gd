# scripts/MainScreen.gd
extends Control

@onready var start_button: Button = $StartButton # Ensure your button is named StartButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Make sure your battle scene is saved as BattleScene.tscn in the scenes folder
	var battle_scene_path = "res://scenes/BattleScene.tscn" 
	var result = get_tree().change_scene_to_file(battle_scene_path)
	if result != OK:
		printerr("Failed to load battle scene: ", battle_scene_path)
