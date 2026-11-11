extends Control
## Live dashboard. All readings come directly from the mounted vehicle.
const INK := Color("111e20")
const FACE := Color("18292b")
const RIM := Color("b3a17a")
const PAPER := Color("e8dfc8")
const MUTED := Color("a6b1a8")
const ORANGE := Color("f5a348")
var wagon: EscapeWagon
var needle_speed := 0.0
var needle_fuel := 1.0
var _initialized := false
var _panel: StyleBoxFlat
var _slot: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(250,132)
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color(0.055,0.09,0.095,0.95)
	_panel.border_color = Color("766e56")
	_panel.set_border_width_all(2)
	_panel.set_corner_radius_all(13)
	_panel.shadow_color = Color(0,0,0,0.35)
	_panel.shadow_size = 4
	_slot = StyleBoxFlat.new()
	_slot.bg_color = Color("0c1719")
	_slot.border_color = Color("55635c")
	_slot.set_border_width_all(1)
	_slot.set_corner_radius_all(3)

func _process(delta: float) -> void:
	if not is_instance_valid(wagon):return
	var speed: float = absf(wagon.speed_mps)*3.6
	var fuel: float = clampf(wagon.fuel/maxf(1.0,wagon.fuel_capacity),0.0,1.0)
	if not _initialized:
		needle_speed=speed;needle_fuel=fuel;_initialized=true
	needle_speed=lerpf(needle_speed,speed,1.0-exp(-14.0*delta))
	needle_fuel=lerpf(needle_fuel,fuel,1.0-exp(-10.0*delta))
	queue_redraw()

func _text(text: String, center: Vector2, font_size: int, color: Color = PAPER) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,center-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _needle(center: Vector2, angle: float, length: float, color: Color) -> void:
	var direction := Vector2.from_angle(angle)
	var normal := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([center-direction*8+normal*2.3,center+direction*length,center-direction*8-normal*2.3]),color)
	draw_circle(center,5.5,INK)
	draw_circle(center,3.0,RIM)

func _bar(y: float, label: String, value_text: String, ratio: float, color: Color) -> void:
	_text(label,Vector2(171,y),11,MUTED)
	_text(value_text,Vector2(228,y),11,PAPER)
	var rect := Rect2(136,y+4,104,8)
	draw_style_box(_slot,rect)
	if ratio>0.0:
		draw_rect(Rect2(rect.position+Vector2(2,2),Vector2(100*clampf(ratio,0,1),4)),color)
	for i in range(1,10):
		var x:float=138+i*10.0
		draw_line(Vector2(x,y+6),Vector2(x,y+10),Color(0.03,0.07,0.075,0.55),1.0)

func _draw() -> void:
	if _panel==null or not is_instance_valid(wagon):return
	# Separate housings leave the world visible around the instruments.
	draw_style_box(_panel,Rect2(130,76,118,54))
	var center := Vector2(64,64)
	draw_circle(center+Vector2(0,2),63,Color("080f11"))
	draw_circle(center,62,RIM)
	draw_circle(center,59,INK)
	draw_arc(center,57,0,TAU,96,Color("65756b"),1.0,true)
	draw_circle(center,54,FACE)
	var start:float=deg_to_rad(135)
	var sweep:float=deg_to_rad(270)
	draw_arc(center,50,start,start+sweep,80,Color("455b55"),1.0,true)
	draw_arc(center,50,start+sweep*0.8,start+sweep,24,Color("bd624b"),3.0,true)
	for i in range(41):
		var a:float=start+sweep*float(i)/40.0
		var ray:=Vector2.from_angle(a)
		var major:bool=i%4==0
		draw_line(center+ray*(44 if major else 48),center+ray*53,PAPER if major else Color("899b8e"),2 if major else 1,true)
		if major:
			_text(str(i*5),center+ray*36+Vector2(0,4),10)
	_text("KM/H",center+Vector2(0,25),10,MUTED)
	_needle(center,start+sweep*clampf(needle_speed/200.0,0,1),43,ORANGE)
	draw_style_box(_slot,Rect2(39,96,50,20))
	_text("%03d" % roundi(absf(wagon.speed_mps)*3.6),Vector2(64,111),16,PAPER)
	# Smaller analogue fuel instrument, with an explicit reserve sector.
	var tank := Vector2(172,43)
	draw_circle(Vector2(172,37),35,RIM)
	draw_circle(Vector2(172,37),33,INK)
	_text("TANK",Vector2(172,16),11,MUTED)
	draw_arc(tank,24,PI,TAU,48,RIM,2,true)
	draw_arc(tank,21,PI,PI+PI*0.16,10,Color("db6b4d"),3,true)
	for i in range(9):
		var ray:=Vector2.from_angle(PI+PI*float(i)/8)
		draw_line(tank+ray*18,tank+ray*22,PAPER,1,true)
	_needle(tank,PI+PI*clampf(needle_fuel,0,1),18,ORANGE)
	_text("E",Vector2(140,49),10,MUTED)
	_text("V",Vector2(204,49),10,MUTED)
	var fuel:float=clampf(wagon.fuel/maxf(1,wagon.fuel_capacity),0,1)
	_text("%d%%" % roundi(fuel*100),Vector2(172,64),12,Color("ef8a64") if fuel<0.16 else PAPER)
	var nitro:float=clampf(wagon.nitro/maxf(1,wagon.nitro_capacity),0,1)
	var installed:bool=wagon.nitro_level>0
	_bar(89,"NITRO",("%d%%" % roundi(nitro*100)) if installed else "OHNE",nitro if installed else 0.0,Color("7cd8ec") if wagon.boost_active else Color("479bb3"))
	var condition:float=clampf(wagon.durability/100.0,0,1)
	_bar(114,"ZUSTAND","%d%%" % roundi(condition*100),condition,Color("da644c") if condition<0.25 else Color("b9b272"))
