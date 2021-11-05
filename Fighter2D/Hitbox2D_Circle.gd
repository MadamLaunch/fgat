tool
extends Hitbox2D
class_name HitboxCircle


export(float) var radius


func _set_texture(value):
	._set_texture(value)
	$Graphic.texture = texture


# Called when the node enters the scene tree for the first time.
func _ready():
	$Shape.shape = $Shape.shape.duplicate()
	
	if texture:
		$Graphic.texture = texture


func _process(_delta):
	state_process()
	
	if $Shape.shape.radius != radius:
		$Shape.shape.radius = radius
	
	var texture_size = $Graphic.texture.get_size()
	$Graphic.scale.x = (radius / texture_size.x) * 2
	$Graphic.scale.y = (radius / texture_size.y) * 2


func reset():
	.reset()
	
	position = Vector2.ZERO
	rotation = 0
	scale = Vector2.ONE
	z_index = 0
	modulate = Color.white
	
	if texture:
		var t = texture.get_size()
		radius = ((t.x + t.y) * .5) * .5
	else:
		radius = 0
