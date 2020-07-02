extends Area2D

onready var FX = preload("res://Player/particles/Dust.tscn")

func _on_Repeller_body_entered(body):
	if body.name == "Player":
		$AnimationPlayer.play("Bounce")
		body._reppel((body.global_position - global_position).normalized())
		$AudioStreamPlayer.play()
		
		var fx = FX.instance()
		fx.emitting = true
		fx.direction = (body.global_position - global_position).normalized()
		
		call_deferred("add_child", fx)

