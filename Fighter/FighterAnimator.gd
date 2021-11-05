tool
class_name FighterAnimator
extends AnimationPlayer


func _ready():
	if Engine.editor_hint:
		# warning-ignore:return_value_discarded
		connect('animation_started', self, 'assign_self')
		# warning-ignore:return_value_discarded
		connect('animation_started',
			get_node(root_node), 'reset_position')


func assign_self(_anim_name):
	var f = get_node(root_node)
	if f is Fighter:
		f.current_player = self
