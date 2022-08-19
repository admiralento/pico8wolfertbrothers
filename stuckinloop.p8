pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--startup

--const
spr_platform = 1
spr_platform_final = 2
spr_player = 33
spr_boss = 13

--global varibles
platform_cnt = 20
starting_platform = 1
actors = {}
platforms = {}
dynamics = {}
player = {}

cx = 63
cy = 63

prev_button_states = btn()

function _init()
 cls()
 generate_platforms(platform_cnt,1,1)

 --place platforms
 place_platforms_circle(63,63,56,0)

 --change last platform spr
 platforms[#platforms].s = spr_platform_final

 player = make_player(0,0,1,1)

 boss = make_boss()
 shot = make_dynamic(cx,cy)
 apply_angle_mag_dynamic(shot,0.75,0.4)
end

function generate_platforms(n)
 for i=1,n do
  make_platform(0,0)
 end
end

function make_platform(x,y)
 p = make_actor(spr_platform,x,y,1,1)
 add(platforms, p)
end

function make_player(x,y)
 p = make_actor(spr_player,x,y,1,1)
 p.state = "static"
 p.current_platform = 1
 p.platform_buffer = 8
 return p
end

function make_actor(s,x,y,h,w)
	a={
	 x = x,
	 y = y,
		s = s,
		w = w,
		h = h,
		fh = false,
		fv = false,
  bw = (w*8) / 2,
  bh = (h*8) / 2
	}
	add(actors,a)
	return a
end

function make_boss()
 b = make_actor(spr_boss,128/2-8,128/2-8,2,2)
 b.state = "static"
 return p
end

function make_dynamic(x,y)
 d = make_actor(17,x,y,1,1)
 d.xvel = 0
 d.yvel = 0
 add(dynamics,d)
 return d
end

function apply_vector_dynamic(d,dx,dy)
 d.xvel += dx
 d.yvel += dy
end

function apply_angle_mag_dynamic(d,a,m)
 return apply_vector_dynamic(d,m*cos(a),m*sin(a))
end
-->8
--calculate

angle = 0

function _update60()
 angle += 0.0005
 place_platforms_circle(cx,cy,56,sin(angle))

	get_user_input()
	move_to_platform()
	update_platform_spr()
	move_dynamics()
	record_button_states()
end

function get_user_input()
 if btnp(0) then
  player.current_platform =
   ((player.current_platform-2) % #platforms) + 1
 end
 if btnp(1) then
  player.current_platform =
   (player.current_platform % #platforms) + 1
 end

end

function move_to_platform()
 local p = platforms[player.current_platform]
 local pcx = p.x + (p.w*4)
 local pcy = p.y + (p.h*4)
 local angle = atan2(pcx-cx,pcy-cy)
 local dx = -player.platform_buffer * cos(angle)
 local dy = -player.platform_buffer * sin(angle)

 if (player.x != p.x + dx) then
  player.x = p.x + dx
 end
 if (player.y != p.y + dy) then
  player.y = p.y + dy
 end
end

function update_platform_spr()
 for i=1,#platforms do
  local p = platforms[i]
  local u = select_platform_spr(p.x,p.y,cx,cy)
  p.s = u[1]
  p.fh = u[2]
  p.fv = u[3]
 end
end

function btnpc(index)
 local mask = 1
 for i=1, index do
  mask *= 2
 end
 return (btn(index) and (band(prev_button_states,mask) == 0))
end

function move_dynamics()
 for d in all(dynamics) do
  d.x += d.xvel
  d.y += d.yvel
 end
end

function record_button_states()
 prev_button_states = btn()
end

function do_actors_collide(a,b)
 local ac = get_actor_center(a)
 local bc = get_actor_center(b)
 return ((ac.x + a.bw > bc.x - b.bw) and
    (ac.x - a.bw < bc.x + b.bw) and
    (ac.y + a.bh > bc.y - b.bh) and
    (ac.y - a.bh < bc.y + b.bh))
end

function get_actor_center(a)
 c = {x = a.x + (a.w*4),
      y = a.y + (a.h*4)}
 return c
end
-->8
--render

function _draw()
	cls()
	draw_actors()
	draw_actor_box(dynamics[1])
	print(do_actors_collide(player,dynamics[1]),0,0)
	print(player.current_platform,0,120)
	print(select_platform_spr(player.x, player.y, 63, 63),0,112)
	line(cx,cy,((player.x+4)-cx)*2+cx,((player.y+4)-cy)*2+cy)
end

function draw_actors()
 for a in all(actors) do
  spr(a.s,a.x,a.y,a.w,a.h,a.fh,a.fv)
 end
end

function draw_actor_box(a)
 local ac = get_actor_center(a)
 rect(ac.x-a.bw,ac.y-a.bh,
 					ac.x+a.bw,ac.y+a.bh)
end

plat_top_spr = 1
plat_side_spr = 2
plat_diag_spr = 3

function select_platform_spr(sx,sy,ox,oy)
 local angle = atan2(sx-ox,sy-oy)
 local output = {}
 -- {spr,fliph,flipv}
 if (angle < 1/16) then
  output = {plat_side_spr,false,false}
 elseif (angle < 3/16) then
  output = {plat_diag_spr,false,true}
 elseif (angle < 5/16) then
  output = {plat_top_spr,false,true}
 elseif (angle < 7/16) then
  output = {plat_diag_spr,true,true}
 elseif (angle < 9/16) then
  output = {plat_side_spr,true,false}
 elseif (angle < 11/16) then
  output = {plat_diag_spr,true,false}
 elseif (angle < 13/16) then
  output = {plat_top_spr,false,false}
 elseif (angle < 15/16) then
  output = {plat_diag_spr,false,false}
 else
  output = {plat_side_spr,false,false}
 end
 return output
end
-->8
--helper functions

function place_platforms_circle(x,y,r,a)
 for n=1,#platforms do
  platforms[n].x = r*cos(((n-1)/#platforms)+a) + x
  platforms[n].y = r*sin(((n-1)/#platforms)+a) + y
 end
end
__gfx__
00000000bbbbbbbbb300000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003bb3bbb3bbb300000000bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb43bb0bbbb3400000bbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003344b30bb34444000bb3340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000444300b34444440bb34440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000444400bbb34400bbb34444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000bbb300000b344444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000040000b300000000000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a99a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a9889a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000098888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000098888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a9889a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a99a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c1cc1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c1cc1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c2222c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000000000000e0501205014050190501b0501e050230502605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
