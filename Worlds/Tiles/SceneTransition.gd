extends CanvasLayer

onready var anim = $AnimationPlayer

func start_transition():
	anim.play("Fade")
	yield(anim, "animation_finished")
	anim.play_backwards("Fade")
