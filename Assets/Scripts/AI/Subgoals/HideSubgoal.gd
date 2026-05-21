class_name HideSubgoal extends Subgoal

var req = {
	"stats": [
		{"name": "Intelligence", "value": 0.5}
	],
	"excludeTypes": [],
	"includeStates": []
}

func _init(manager:AIManager) -> void:
	super._init("Hide", "Hiding in a small place", req, manager)

func evaluate(ai:AI) -> Dictionary:
	var evaluation = {
		"values": [
			{"name": "Survive", "value": 0.5}
		]
	}
	return evaluation

func progress(ai:AI):
	super(ai)
	var food = ai.getHealthStat("food")
	print("and lost food in the process")
	ai.setHealthStat("food", max(food-0.2, 0.0))
