extends Node


var properties := {}

signal property_changed(
	property : String,
	new_value : Variant,
	old_value : Variant,
)


func _ready() -> void:
	apply("ammo.pistol", 6)
	apply("ammo.sniper", 12)


func of(property : String, default : Variant = 0) -> Variant:
	if not properties.has(property):
		apply(property, default)
	return properties.get(property)

func change_by(property : String, change) -> void:
	var value = of(property)
	if not typeof(value) in [2, 3]: # int float
		push_warning("trying to change non-number property %s by %s" % [property, change])
		return
	apply(property, value + change)


func apply(property : String, to : Variant) -> void:
	var old_value : Variant = properties.get(property)
	properties[property] = to
	property_changed.emit(property, to, old_value)
