class_name EatFoodSubgoal extends Subgoal

var req = {
	"stats": [],
	"excludeTypes": [],
	"includeStates": []
}

func _init(manager:AIManager) -> void:
	super._init("Eat food", "Eating food", req, manager)

func evaluate(ai:AI) -> Dictionary:
	var food = ai.getHealthStat("food")
	var survivalPoints = 1.0-food
	var evaluation = {
		"values": [
			{"name": "Survive", "value": survivalPoints}
		]
	}
	return evaluation

func progress(ai:AI):
	super(ai)
	var food = ai.getHealthStat("food")
	ai.setHealthStat("food", min(food+0.5, 1.0))
