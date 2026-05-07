extends Node

const GAME_VERSION = "v1.0.1"

var config = ConfigFile.new()

var wumba = false
var music = AudioServer.get_bus_index('Master')

# accessibility
var min_effects
var improve_readability
var dyslexic_mode

#loading
var loading = load('res://scenes/menus/loading/loading.tscn')
var next_scene = 'res://scenes/menus/select_mode/select_mode.tscn'
var start = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	#Load Config
	var err = config.load("user://config.cfg")

	#Create Initial cfg if doesn't exist
	if err != OK:
		config.set_value("Tux Typing Config", "Resolution", Vector2i(1920,1080))
		config.set_value("Tux Typing Config", "Fullscreen", DisplayServer.window_get_mode())
		config.set_value("Tux Typing Config", "Volume", AudioServer.get_bus_volume_db(Config.music))
		config.set_value('Tux Typing Config', 'FPS', Engine.get_max_fps())
		config.set_value('Tux Typing Config', 'ShowFPS', false)
		config.set_value('Tux Typing Config', 'Vsync', false)

		config.set_value('Tux Typing Config', 'MinEffects', false)
		config.set_value('Tux Typing Config', 'ImproveRead', false)
		config.set_value('Tux Typing Config', 'Dyslexia', false)
		config.save("user://config.cfg")
		return

	Config.min_effects = config.get_value('Tux Typing Config', 'MinEffects')
	Config.improve_readability = config.get_value('Tux Typing Config', 'ImproveRead')
	Config.dyslexic_mode = config.get_value('Tux Typing Config', 'Dyslexia')

	#Load Config cont
	DisplayServer.window_set_size(config.get_value('Tux Typing Config', 'Resolution'))
	DisplayServer.window_set_mode(config.get_value('Tux Typing Config', 'Fullscreen'))
	AudioServer.set_bus_volume_db(Config.music, config.get_value('Tux Typing Config', 'Volume'))
	Engine.max_fps = config.get_value('Tux Typing Config', 'FPS')
	FpsCounter.get_node('CanvasLayer').visible = config.get_value('Tux Typing Config', 'ShowFPS')
	if config.get_value('Tux Typing Config', 'Vsync'):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_scene(scene):
	next_scene = scene
	get_tree().change_scene_to_packed(loading)
