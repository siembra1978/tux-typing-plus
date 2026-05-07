extends CharacterBody2D

var speed = 0
var scene
var target
var self_active = false
var active = true
var queue = []
var moving = true

var eating = false

func _ready() -> void:
	scene = self.get_parent()
	
	
func move_to(chosen_pos, chosen_spd):
	queue.append({'target': chosen_pos, 'speed': chosen_spd})
	#self_active = true

func _process(delta: float):
	if queue.size() > 0:
		self_active = true
		var current_move = queue[0]
		target = current_move['target']
		speed = position.distance_to(target) * 1
		
	active = scene.active
	if active:
		#print(eating)
		if self_active and not eating:
			if target:
				var direction = sign(target.x - position.x)
				if not $Running.playing:
					$Running.play()

				if abs(target.x - position.x) < 10:
					velocity.x = 0
					position.x = target.x
					self_active = false
				else:
					velocity.x = direction * speed
		else:
			velocity.x = 0

		#Active animation based on dir and speed (There's gotta be a better way to do this)
		if moving:
			if velocity.x > 0:
				if speed > 299:
					$FishTux.play("run")
				else:
					$FishTux.play("walk")
				$FishTux.scale.x = 1

			elif velocity.x < 0:
				if speed > 299:
					$FishTux.play("run")
				else:
					$FishTux.play("walk")
				$FishTux.scale.x = -1
			else:
				$Running.stop()
				$FishTux.play("stand")
				if Config.min_effects:
					$FishTux.stop()

		move_and_slide()

		position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
		
func eat():
	if not eating:
		print("eating!")
		eating = true
		moving = false
		queue.pop_front()
		$Bite.play()
		$FishTux.play('gulp')
		
		# TO-DO: figure out why this await likes the hang for no reason
		await $FishTux.animation_finished
		
		print("yum!")
		moving = true
		$FishTux.play("stand")
		eating = false
