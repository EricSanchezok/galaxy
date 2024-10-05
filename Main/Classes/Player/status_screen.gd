extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func show_screen() -> void:
	animation_player.play("show_screen")
	
func hide_screen() -> void:
	animation_player.play("hide_screen")
	
func _on_button_edit_pressed() -> void:
	hide_screen()
