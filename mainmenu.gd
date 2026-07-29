extends Control

@onready var settings_panel = $SettingsPanel
@onready var start_button = $MenuContainer/StartButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var close_button = $SettingsPanel/CloseButton

func _ready() -> void:
	settings_panel.hide()
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_start_pressed() -> void:	
	get_tree().change_scene_to_file("res://main/main.tscn")
	
func _on_settings_pressed() -> void:
	settings_panel.show()

func _on_close_pressed() -> void:
	settings_panel.hide()
