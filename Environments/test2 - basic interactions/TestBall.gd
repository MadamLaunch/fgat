extends Fighter2D


var duration : float = 0
var hitboxes = []
var last_cycle : int = -1


func _ready():
	randomize()
	hitboxes = [$Strike, $Throw, $Guard]
	set_process(false)


func _process(delta):
	duration += delta
	
	if duration >= 1.5:
		for j in hitboxes:
			j.hide()
		
		var n = randi() % 3
		while n == last_cycle:
			n = randi() % 3
		
		hitboxes[n].show()
		last_cycle = n
		duration = 0
