extends Node
class_name SoundComponent

func play_sound(sound: AudioStreamPlayer):
	if not sound.playing:
		sound.play()
		
func play_sound_noCheck(sound: AudioStreamPlayer):
	sound.play()
