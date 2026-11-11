extends RefCounted
## One measured sheet per identity, shared by hanging, climbing and crawling.
const DATA = preload("res://scripts/zombie_data.gd")
const ATLAS = preload("res://assets/zombie_attachment_identity_v4.png")
# Filled from opaque bounds; no cell padding participates in body scale.
const RECTS: Array[Rect2] = [Rect2(72,32,247,167),Rect2(490,31,174,172),Rect2(828,59,259,138),Rect2(1224,62,238,135),Rect2(72,242,241,161),Rect2(496,244,165,166),Rect2(824,265,261,134),Rect2(1229,265,233,135),Rect2(77,442,235,157),Rect2(505,441,156,161),Rect2(830,466,252,130),Rect2(1229,467,228,129),Rect2(73,629,239,158),Rect2(503,632,161,163),Rect2(832,654,248,133),Rect2(1233,655,227,132),Rect2(72,826,239,162),Rect2(489,832,173,164),Rect2(824,862,268,126),Rect2(1229,864,234,124)]
const GRIPS: Array[Vector2] = [Vector2(220.8718,11.672911),Vector2(154.47,43.05667),Vector2.ZERO,Vector2.ZERO,Vector2(215.288,11.8736),Vector2(146.2031,32.505120000000005),Vector2.ZERO,Vector2.ZERO,Vector2(209.5652,11.813187),Vector2(137.7455,32.03763),Vector2.ZERO,Vector2.ZERO,Vector2(212.3362,12.02754),Vector2(142.7956,31.54144),Vector2.ZERO,Vector2.ZERO,Vector2(210.3703,12.15287),Vector2(153.4727,29.65608),Vector2.ZERO,Vector2.ZERO]

static func pose_index(variant: int, pose: int) -> int:
	return (clampi(variant,1,5)-1)*4+clampi(pose,0,3)

static func body_scale(variant: int) -> float:
	return float(DATA.profile(variant).visual_height)/maxf(RECTS[pose_index(variant,2)].size.x,RECTS[pose_index(variant,3)].size.x)

static func pose_rect(variant: int, pose: int, crawl_scale: float = 1.0) -> Rect2:
	var index: int = pose_index(variant,pose)
	var size: Vector2 = RECTS[index].size * body_scale(variant) * (crawl_scale if pose >= 2 else 1.0)
	return Rect2(-GRIPS[index]*body_scale(variant),size) if pose < 2 else Rect2(Vector2(-size.x*0.5,-size.y),size)

static func local_rect(variant: int, frame: int, side: bool, pull: float = -1.0, crawl_scale: float = 1.0, crawl_offset: float = 0.0) -> Rect2:
	if pull>=0:
		var stage:float=smoothstep(0.0,0.25,pull) if pull<0.5 else smoothstep(0.72,1.0,pull)
		var first:int=0 if pull<0.5 else 1
		var a:Rect2=pose_rect(variant,first)
		var b:Rect2=pose_rect(variant,first+1,crawl_scale)
		if first + 1 == 2: b.position.x += crawl_offset
		if stage<=0.001:return a
		if stage>=0.999:return b
		return a.merge(b)
	return pose_rect(variant,0 if side else 2+posmod(frame,2),crawl_scale)

static func draw_pose(target: CanvasItem, variant: int, frame: int, side: bool, wind: float, phase: float, opacity: float = 1.0, pull: float = -1.0, crawl_scale: float = 1.0, crawl_offset: float = 0.0) -> void:
	if pull >= 0.0:
		var stage: float = smoothstep(0.0,0.25,pull) if pull < 0.5 else smoothstep(0.72,1.0,pull)
		var first: int = 0 if pull < 0.5 else 1
		var second: int = first+1
		for entry in [[first,1.0-stage],[second,stage]]:
			var weight: float = float(entry[1])*opacity
			if weight <= 0.001: continue
			var pose: int = int(entry[0])
			var offset := Vector2(crawl_offset, 0.0) if pose == 2 else Vector2.ZERO
			_draw_frame(target,variant,pose,wind,phase,weight,offset,crawl_scale)
		return
	_draw_frame(target,variant,0 if side else 2+posmod(frame,2),wind,phase,opacity,Vector2.ZERO,crawl_scale)

static func _draw_frame(target: CanvasItem, variant: int, pose: int, wind: float, phase: float, opacity: float, offset: Vector2 = Vector2.ZERO, crawl_scale: float = 1.0) -> void:
	var source: Rect2 = RECTS[pose_index(variant,pose)]
	var rect: Rect2 = pose_rect(variant,pose,crawl_scale)
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns := PackedFloat32Array([0,0.25,0.5,0.75,1])
	var rows := PackedFloat32Array([0,0.2,0.4,0.6,0.8,1])
	for v in rows:
		for u in columns:
			var point: Vector2 = rect.position+rect.size*Vector2(u,v)
			if pose==0:
				var loose: float = smoothstep(0.25,1.0,v)
				point.x -= wind*loose*(2.0+sin(phase*1.2)*1.2)
				point.y += sin(phase*1.2)*0.5*loose
			elif pose>=2:
				var free: float = pow(1.0-v,2.0)
				point.x -= wind*free*(1.5+sin(phase)*1.1)
				point.y += sin(phase*1.3+u*1.8)*1.2*free
			vertices.append(point+offset)
			uv.append((source.position+source.size*Vector2(u,v))/ATLAS.get_size())
	for row in range(rows.size()-1):
		for col in range(columns.size()-1):
			var i: int = row*columns.size()+col
			indices.append_array(PackedInt32Array([i,i+1,i+columns.size(),i+1,i+columns.size()+1,i+columns.size()]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	target.get("_zombie_pose_meshes").append(mesh)
	target.draw_mesh(mesh,ATLAS,Transform2D.IDENTITY,Color(1,1,1,opacity))

