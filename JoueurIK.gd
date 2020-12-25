extends RenIK

func _ready():
	set_skeleton_path("EveJGonzalez-Mixamoed/Node 2/Skeleton")
	enable_solve_ik_every_frame(true)
	print("IK Weady")
