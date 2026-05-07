extends Control

@onready var custom_background = get_node("CustomBackground")
@onready var background_dim = get_node("BGDim")
@onready var gui = get_node("GUI")

@onready var info_stack = gui.get_node("Info")

@onready var song_label = info_stack.get_node("AutoScroll").get_node("SongTitle")

@onready var score_stack = info_stack.get_node("ScoreStack")
@onready var score_label = score_stack.get_node("Score")

@onready var grading_stack = info_stack.get_node("GradingStack")

@onready var left = grading_stack.get_node("Left")
@onready var perfect_stack = left.get_node("Perfect")
@onready var perfect_label = perfect_stack.get_node("PerfectNum")
@onready var good_stack = left.get_node("Good")
@onready var good_label = good_stack.get_node("GoodNum")

@onready var right = grading_stack.get_node("Right")
@onready var meh_stack = right.get_node("Meh")
@onready var meh_label = meh_stack.get_node("MehNum")
@onready var miss_stack = right.get_node("Miss")
@onready var miss_label = miss_stack.get_node("MissNum")

@onready var result_stack = info_stack.get_node("ResultStack")

@onready var acc_stack = result_stack.get_node("Accuracy")
@onready var acc_label = acc_stack.get_node("AccuracyPer")

@onready var combo_stack = result_stack.get_node("Combo")
@onready var combo_label = combo_stack.get_node("ComboLabel")

@onready var fc_label = result_stack.get_node("FC")

@onready var ranking_stack = gui.get_node("Ranking")
@onready var rank_control = ranking_stack.get_node("RankControl")
@onready var rank_letter_label = rank_control.get_node("RankLetter")

@onready var button_sound = get_node("ButtonPress")
@onready var cheer_sound = get_node("Cheer")
@onready var fade = get_node("Fade")

var song_title
var score
var judgments
var accuracy
var combo
var fc = false
var rank
var background
var legacy
var official
var mods

func _ready() -> void:
	song_label.text = song_title
	score_label.text = str(score).pad_zeros(8)
	perfect_label.text = str(judgments["perfect"])
	good_label.text = str(judgments["good"])
	meh_label.text = str(judgments["meh"])
	miss_label.text = str(judgments["miss"])
	acc_label.text = str(accuracy) + "%"
	combo_label.text = str(combo) + "x"

	if fc and (int(accuracy) == 100):
		fc_label.text = "Perfect Combo"
	elif fc:
		fc_label.text = "Full Combo"
	else:
		fc_label.text = ""

	if mods["AP"]:
		rank_letter_label.text = '"SS"'
	elif int(accuracy) == 100:
		rank_letter_label.text = "SS"
		cheer_sound.play()
	elif accuracy >= 95:
		rank_letter_label.text = "S"
		cheer_sound.play()
	elif accuracy < 95 and accuracy >= 90:
		rank_letter_label.text = "A"
		cheer_sound.play()
	elif accuracy < 90 and accuracy >= 80:
		rank_letter_label.text = "B"
		cheer_sound.play()
	elif accuracy < 80 and accuracy >= 70:
		rank_letter_label.text = "C"
	elif accuracy < 70 and accuracy >= 60:
		rank_letter_label.text = "D"
	else:
		rank_letter_label.text = "F"

	if legacy:
		if background:
			background_dim.visible = true
			custom_background.visible = true
			custom_background.texture = background
	else:
		if background:
			background_dim.visible = true
			custom_background.visible = true
			custom_background.texture = background
		
	fade.visible = true
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 0, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_menu_pressed() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(fade, "modulate:a", 1, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_sound.play()
	await get_tree().create_timer(1).timeout
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/beat/rhythmgame.tscn")
