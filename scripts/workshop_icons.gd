extends RefCounted
## Painted catalog illustrations; never used to choose mounted vehicle parts.
const TEXTURES:Dictionary={
	"engine":preload("res://assets/ui/workshop/engine_v1.png"),
	"tires":preload("res://assets/ui/workshop/tires_v1.png"),
	"tank":preload("res://assets/ui/workshop/tank_v1.png"),
	"armor":preload("res://assets/ui/workshop/armor_v1.png"),
	"nitro":preload("res://assets/ui/workshop/nitro_v1.png"),
	"weapon":preload("res://assets/ui/workshop/weapon_v1.png")
}
static var _sources:Dictionary={}
static func source(part:String) -> Rect2:
	if not _sources.has(part):
		var im:Image=TEXTURES[part].get_image()
		_sources[part]=Rect2(im.get_used_rect())
	return _sources[part]
static func draw(target:CanvasItem,center:Vector2,part:String,tint:Color) -> void:
	var color:=Color(.45,.48,.45) if tint.r<.6 else Color.WHITE
	_paint(target,Rect2(center-Vector2(28,24),Vector2(56,48)),part,color)
static func draw_preview(target:CanvasItem,rect:Rect2,part:String) -> void:
	_paint(target,rect,part,Color.WHITE)
static func _paint(target:CanvasItem,rect:Rect2,part:String,tint:Color) -> void:
	if not TEXTURES.has(part):return
	var region:Rect2=source(part)
	var scale_factor:float=minf(rect.size.x/region.size.x,rect.size.y/region.size.y)
	var size:Vector2=region.size*scale_factor
	target.draw_texture_rect_region(TEXTURES[part],Rect2(rect.get_center()-size*.5,size),region,tint)

