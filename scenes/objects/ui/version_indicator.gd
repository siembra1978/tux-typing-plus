extends Control

@onready var version_label = get_node("VersionLabel")

func _ready() -> void:
	version_label.text = Config.GAME_VERSION
