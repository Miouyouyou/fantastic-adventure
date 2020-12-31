extends RenIK

func _ready():
	set_skeleton_path("../AliciaSolid_vrm-051/Root/Skeleton")
	enable_solve_ik_every_frame(true)
	#armature_head_target = "../LookAtNode"
	armature_left_hand = "../LookAtNode"
	#print("IK Weady")
	pass

#func _process(delta):
	#update_ik()
#	pass
