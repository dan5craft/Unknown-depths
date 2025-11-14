extends Area3D

func isPlayer(node : Area3D):
	if node.get_meta("isPlayer") == true:
		return true
	else:
		return false

func _on_area_entered(area: Area3D) -> void:
	if isPlayer(area):
		var filter := area.get_parent().get_node("./Filter")
		filter.underWater = false
	print("ENTERED HULL")

func _on_area_exited(area: Area3D) -> void:
	if isPlayer(area):
		var filter := area.get_parent().get_node("./Filter")
		filter.underWater = true
	print("EXITED HULL")
