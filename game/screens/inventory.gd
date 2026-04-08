extends Screen



func _ready() -> void:
	super()
	for property : String in Data.properties.keys():
		if property.begins_with("item."):
			%Label.text += "%s: %s" % [property, Data.of(property)]



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		close()
