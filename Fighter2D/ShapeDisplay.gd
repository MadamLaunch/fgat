tool
extends Control
class_name ShapeDisplay


export(NodePath) var flip_node


func _process(_delta : float):
	rect_size = $'..'.shape.extents * 2
	
	rect_position = -$'..'.shape.extents
	
	if flip_node:
		if get_node(flip_node).scale.x < 0:
			rect_scale.x = -1
			rect_position.x *= -1
		else:
			rect_scale.x = 1
	
	if $'..'.disabled:
		modulate.a = .5
	else:
		modulate.a = 1
