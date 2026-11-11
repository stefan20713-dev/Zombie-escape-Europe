extends RefCounted
## Planned story route, deliberately separate from playable campaign levels.
const MAP=preload("res://assets/ui/workshop/journey_map_v1.png")
const STOPS: Array[Dictionary] = [
	{"id":"amsterdam","city":"Amsterdam","p":Vector2(0.83794,0.11740)},
	{"id":"utrecht","city":"Utrecht","p":Vector2(0.86096,0.12638)},
	{"id":"breda","city":"Breda","p":Vector2(0.84715,0.15746)},
	{"id":"antwerpen","city":"Antwerpen","p":Vector2(0.82320,0.17818)},
	{"id":"bruessel","city":"Brüssel","p":Vector2(0.80571,0.19890)},
	{"id":"mons","city":"Mons","p":Vector2(0.78269,0.21547)},
	{"id":"paris","city":"Paris","p":Vector2(0.69797,0.31561)},
	{"id":"orleans","city":"Orléans","p":Vector2(0.68324,0.36948)},
	{"id":"tours","city":"Tours","p":Vector2(0.61786,0.39710)},
	{"id":"poitiers","city":"Poitiers","p":Vector2(0.59945,0.45442)},
	{"id":"bordeaux","city":"Bordeaux","p":Vector2(0.54604,0.52141)},
	{"id":"bayonne","city":"Bayonne / Biarritz","p":Vector2(0.47882,0.56837)},
	{"id":"san_sebastian","city":"San Sebastián","p":Vector2(0.44475,0.58149)},
	{"id":"burgos","city":"Burgos","p":Vector2(0.40331,0.63536)},
	{"id":"valladolid","city":"Valladolid","p":Vector2(0.35175,0.67818)},
	{"id":"madrid","city":"Madrid","p":Vector2(0.41068,0.73343)},
	{"id":"cordoba","city":"Córdoba","p":Vector2(0.35912,0.82459)},
	{"id":"sevilla","city":"Sevilla","p":Vector2(0.29466,0.85152)},
	{"id":"jerez","city":"Jerez de la Frontera","p":Vector2(0.28453,0.89157)},
	{"id":"algeciras","city":"Algeciras","p":Vector2(0.33149,0.91022)}
]
static func draw(target:CanvasItem, rect:Rect2, current:String, completed:Array[String], large:bool=false) -> void:
	target.draw_rect(Rect2(rect.position+Vector2(3,4),rect.size),Color(0,0,0,.35))
	target.draw_rect(rect,Color("b6a17a"))
	target.draw_rect(rect.grow(-2),Color("d0bc91"))
	var ratio:float=MAP.get_width()/float(MAP.get_height())
	var image_size:=Vector2(minf(rect.size.x,rect.size.y*ratio),rect.size.y)
	var area:=Rect2(rect.get_center()-image_size*.5,image_size)
	target.draw_texture_rect(MAP,area,false)
	var route:=PackedVector2Array()
	for stop in STOPS:route.append(area.position+area.size*Vector2(stop.p))
	target.draw_polyline(route,Color("4c3327"),4 if large else 1.9,true)
	target.draw_polyline(route,Color("bb6246"),2 if large else 1.1,true)
	for i in range(STOPS.size()):
		var stop:Dictionary=STOPS[i]
		var p:Vector2=route[i]
		if completed.has(String(stop.id)):
			target.draw_circle(p,4 if large else 2,Color("476b4f"))
		if String(stop.id)==current:
			target.draw_circle(p,7 if large else 3.7,Color("a74734"))
			target.draw_circle(p,3 if large else 1.5,Color("476b4f") if completed.has(String(stop.id)) else Color("f8df9f"))
		elif large and not completed.has(String(stop.id)):target.draw_circle(p,2,Color("675640"))
	var font:Font=ThemeDB.fallback_font
	var title:String="AMSTERDAM → ALGECIRAS" if large else "EUROPA"
	var fs:int=15 if large else 8
	var text_width:float=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	target.draw_string(font,Vector2(rect.get_center().x-text_width*.5,rect.position.y+(24 if large else 12)),title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("5a4935"))
	if large:
		target.draw_string(font,area.position+area.size*Vector2(.64,.12),"START",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("674b37"))
		target.draw_string(font,area.position+area.size*Vector2(.39,.94),"ZIEL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("674b37"))
	else:
		target.draw_string(font,Vector2(rect.position.x+7,rect.end.y-6),"REISEPLAN",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("5a4935"))
