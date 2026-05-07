extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	#Discord RPC
	DiscordRPC.app_id = 1485290726349602897
	DiscordRPC.details = "Hello World!"
	DiscordRPC.large_image = "icon"
	DiscordRPC.large_image_text = "Tux Typing+"

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

	DiscordRPC.refresh() # Always refresh after changing the values!


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
