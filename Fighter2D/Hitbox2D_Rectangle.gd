tool
extends Hitbox2D
class_name HitboxRectangle


export(int) var margin = 0
export(Vector2) var extents


func _set_texture(value : Texture):
	._set_texture(value)
	_assign_graphic()



func _ready():
	$Shape.shape = $Shape.shape.duplicate()
	_assign_graphic()


func _process(_delta):
	state_process()
	
	if $Shape.shape.extents != extents:
		$Shape.shape.extents = extents
	
	$Flip/Graphic.rect_position = -extents
	$Flip/Graphic.rect_size = extents * 2
	if get_global_transform().get_scale().y < 0:
		$Flip.scale.x = -1
	else:
		$Flip.scale.x = 1


func _assign_graphic():
	$Flip/Graphic.texture = texture
	$Flip/Graphic.patch_margin_bottom = margin
	$Flip/Graphic.patch_margin_left = margin
	$Flip/Graphic.patch_margin_right = margin
	$Flip/Graphic.patch_margin_top = margin


func reset():
	.reset()
	
	position = Vector2.ZERO
	rotation = 0
	scale = Vector2.ONE
	z_index = 0
	modulate = Color.white
	
	if texture:
		extents = texture.get_size() * .5
	else:
		extents = Vector2.ZERO
