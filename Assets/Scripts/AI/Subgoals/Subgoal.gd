class_name Subgoal

var name:String
var description:String
var requirements:Dictionary
# requirements layout:
#{
#	"stats": [
#		{"name": "Intelligence", "value": 0.0},
#		{"name": "Leadership", "value": 0.0}
#	],
#	"excludeTypes": ["Human", "Fish"],
#	"includeStates": ["Ground"]
#}

func _init(tempName:String, tempDescription:String, tempRequirements:Dictionary, manager:AIManager) -> void:
	name = tempName
	description = tempDescription
	requirements = tempRequirements
	manager.subgoalList.append(self)
	print("Subgoal "+name+" created with description:\n"+description)

func evaluate(ai:AI) -> Dictionary:
	return {
		"values": []
	}

func progress(ai:AI):
	print(ai.NpcName+" is "+description)
