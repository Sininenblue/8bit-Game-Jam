extends Area2D



func _on_Floating_Spike_body_entered(body):
	if body.name == "Player":
		body._kill()
		$AnimationPlayer.play("default")
