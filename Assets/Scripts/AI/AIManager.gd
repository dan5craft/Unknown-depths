class_name AIManager extends Node3D

var AIList:Array[AI]
var goalList:Array[Goal]
var subgoalList:Array[Subgoal]

func _enter_tree() -> void:
	var surviveGoal:Goal = Goal.new("Survive", "Prioritize actions that benefit survival", self)
	var eatFoodSubgoal:EatFoodSubgoal = EatFoodSubgoal.new(self)
	var hideSubgoal:HideSubgoal = HideSubgoal.new(self)
