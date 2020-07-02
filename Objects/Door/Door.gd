extends Area2D

export(String, FILE, "*.tscn") var level_file

onready var victoryfx = $AudioStreamPlayer
onready var victoryfx2 = $AudioStreamPlayer2

func _on_Door_body_entered(body):
	if body.name == "Player":
		if level_file != null:
			body._done()
			SceneTransition.start_transition()
			victoryfx.play()
			$Timer.start(1.2)

func _on_Timer_timeout():
	get_tree().change_scene(level_file)


func _on_AudioStreamPlayer_finished():
	victoryfx2.play()
