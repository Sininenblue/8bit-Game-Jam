extends TextureButton

export(String, FILE, "*.tscn") var path



func _on_Start_pressed():
	SceneTransition.start_transition()
	$Delay.start(1.2)


func _on_Delay_timeout():
	get_tree().change_scene(path)
