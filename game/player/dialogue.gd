@tool
extends LineReader


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


func set_opening_background_visible(value:bool):
	%OpeningBackground.visible = value
