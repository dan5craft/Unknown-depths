class_name Goal

var name:String
var description:String

func _init(tempName:String, tempDescription:String, manager:AIManager) -> void:
	name = tempName
	description = tempDescription
	manager.goalList.append(self)
	print("Subgoal "+name+" created with description:\n"+description)
