class_name AI extends Node3D

var id:int
@export var NpcName:String
@export var type:String
@export var state:String
@export var friendlies:Array[String]
@export var enemies:Array[String]
@export var activeGoals:Array[String]
var subgoals:Array[Subgoal]
var goals:Array[Goal]
@export_custom(PROPERTY_HINT_RANGE, "-1, 1") var bravery:float
@export_custom(PROPERTY_HINT_RANGE, "-1, 1") var ethics:float
@export_custom(PROPERTY_HINT_RANGE, "0, 1") var intelligence:float
@export_custom(PROPERTY_HINT_RANGE, "0, 1") var cooperation:float
@export_custom(PROPERTY_HINT_RANGE, "0, 1") var leadership:float
var data:Dictionary
var memory:Dictionary
@export var manager:AIManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data = {
		"personality": [
			{"name": "Bravery", "value": bravery},
			{"name": "Ethics", "value": ethics},
			{"name": "Intelligence", "value": intelligence},
			{"name": "Cooperation", "value": cooperation},
			{"name": "Leadership", "value": leadership}
		],
		"health": [
			{"name": "food", "value": 1.0}
		]
	}
	for goal in manager.goalList:
		if activeGoals.count(goal.name) > 0:
			goals.append(goal)
			print(NpcName+" will "+goal.description)
	for subgoal in manager.subgoalList:
		if subgoal.requirements.get("excludeTypes").count(type) > 0:
			continue
		var hasReq = true
		for reqStat in subgoal.requirements.get("stats"):
			if getPersonalityStat(reqStat.get("name")) < reqStat.get("value"):
				hasReq = false
		if hasReq:
			subgoals.append(subgoal)
			print(NpcName+" will be able to "+subgoal.name)
	evaluateSubgoal()
	evaluateSubgoal()
	evaluateSubgoal()
	evaluateSubgoal()
	pass # Replace with function body.

func evaluateSubgoal():
	var maxFufillment := -10000.0
	var targetSubgoal:Subgoal
	for subgoal in subgoals:
		var fufillment:float = 0.0
		var evaluation = subgoal.evaluate(self)
		for value in evaluation.get("values"):
			if isActiveGoal(value.get("name")):
				fufillment += value.get("value")
		if fufillment > maxFufillment:
			maxFufillment = fufillment
			targetSubgoal = subgoal
	print(NpcName+" chose to "+targetSubgoal.name)
	targetSubgoal.progress(self)

func isActiveGoal(goalString) -> bool:
	for goal in goals:
		if goal.name == goalString:
			return true
	return false

func getPersonalityStat(statString:String):
	for stat in data.get("personality"):
		if stat.get("name") == statString:
			return stat.get("value")

func getHealthStat(statString:String):
	for stat in data.get("health"):
		if stat.get("name") == statString:
			return stat.get("value")

func setHealthStat(statString:String, value):
	for stat in data.get("health"):
		if stat.get("name") == statString:
			stat.set("value", value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
