pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--startup

--const
spr_platform = 1
spr_platform_final = 2
spr_player = 33
spr_player_dash = 34
spr_boss = 14

--global varibles
platform_cnt = 20
starting_platform = 1
points = 0
actors = {}
particles = {}
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
end

function generate_platforms(n)
 for i=1,n do
  make_platform(0,0)
 end
end

function make_platform(x,y)
 p = make_actor(spr_platform,x,y,1,1)
 p.spriteset = {1,2,3}
 p.type = "grass"
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
  bh = (h*8) / 2,
  frames = 0
	}
	add(actors,a)
	return a
end

function make_boss()
 b = make_actor(spr_boss,cx-8,cy-8,2,2)
 b.state = "static"
 b.action = "static"
 b.frames = 0
 b.fullFrameCnt = 0
 b.cycles = 0
 b.cachex = 0
 b.cachey = 0
 return b
end


function make_dynamic(x,y)
 d = make_actor(17,x,y,1,1)
 d.xvel = 0
 d.yvel = 0
 d.damage = 1
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

function make_particle(x,y,c)
 p = { x = x,
       y = y,
       c = c,
       xvel = 0,
       yvel = 0,
       frames = 1}
 add(particles,p)
 return p
end
-->8
--calculate

angle = 0

function _update60()
 angle += 0.0005
 place_platforms_circle(cx,cy,56+5*sin(angle*5),sin(angle))

	get_user_input()
	update_player()
 update_boss()
	update_platform_spr()
	move_dynamics()

	check_dynamic_collisions()
	update_particles()

	record_button_states()

 remove_desert_if_touching()

	add_desert_if_missing()
end

function remove_desert_if_touching()
 if (platforms[player.current_platform].type == "desert") then
  platforms[player.current_platform].type = "grass"
  platforms[player.current_platform].spriteset = {1,2,3}
  sfx(2)
  points += 1
 end
end

function check_for_desert()
 for i in all(platforms) do
  if (i.type == "desert") then
   return true
  end
 end
 return false
end

function add_desert_if_missing()
 if (not(check_for_desert())) then
  make_random_platform_into_desert()
 end
end

function change_platform_to_desert_sprites(p)
 p.spriteset = {4,5,6}
 p.type = "desert";
 for i = 1,20 do
  gen_desert_particle(p.x,p.y)
 end
end

function make_random_platform_into_desert()
 change_platform_to_desert_sprites(random_platform(p.current_platform))
end

function get_user_input()
 if btnp(0) then
  player.current_platform =
   ((player.current_platform-2) % #platforms) + 1
  player.state = "jumping"
  player.frames = 10
  player.s = 34
 end
 if btnp(1) then
  player.current_platform =
   (player.current_platform % #platforms) + 1
  player.state = "jumping"
  player.frames = 10
  player.s = 34
 end
 if btnp(4) then
  player.current_platform =
   ((player.current_platform - (#platforms/2) - 1) % #platforms) + 1
  player.state = "jumping"
  player.frames = 10
  player.s = 34
 end

end

function update_player()
 if (player.state == "jumping") then
  animate_to_platform()
 elseif (player.state == "static") then
  warp_to_platform()
 end
end

function animate_to_platform()
 local pcoords = get_platform_coords(player.current_platform)
 player.x += (pcoords.x-player.x) / player.frames
 player.y += (pcoords.y-player.y) / player.frames
 player.frames -= 1
 local c = get_actor_center(player)
 gen_simple_particle(c.x, c.y)
 if (player.frames <= 0) then
  player.state = "static"
  player.s = 33
 end
end

function warp_to_platform()
 local pcoords = get_platform_coords(player.current_platform)
 player.x = pcoords.x
 player.y = pcoords.y
end

function warp_to_platform()
 local pcoords = get_platform_coords(player.current_platform)
 player.x = pcoords.x
 player.y = pcoords.y
end

function get_platform_coords(index)
 local p = platforms[index]
 local pcx = p.x + (p.w*4)
 local pcy = p.y + (p.h*4)
 local angle = atan2(pcx-cx,pcy-cy)
 local dx = -player.platform_buffer * cos(angle)
 local dy = -player.platform_buffer * sin(angle)
 return {x=p.x+dx,y=p.y+dy}
end

function update_platform_spr()
 for i=1,#platforms do
  local p = platforms[i]
  local u = select_platform_spr(p.x,p.y,cx,cy,p.spriteset[1],p.spriteset[2],p.spriteset[3])
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

function check_dynamic_collisions()
 for d in all(dynamics) do
  if (do_actors_collide(player,d)) then
   sfx(0)
   del(dynamics, d)
  	del(actors, d)
  end
 end
end

function record_button_states()
 prev_button_states = btn()
end

function update_particles()
 for p in all(particles) do
  p.x += p.xvel
  p.y += p.yvel
  p.frames -= 1
  if (p.frames <= 0) then
   add(t0_del,p)
   del(particles,p)
  end
 end
end

function update_boss()
 if (boss.state == "static") then
  if (boss.action == "floating") then
   if (first_frame()) then
    boss.cachex = boss.x
    boss.cachey = boss.y
   end
   if (move_to_next_frame()) then
    boss.s = 14
    boss.x += 0.2*cos(boss.frames/boss.maxFrameCnt)
    boss.y += 0.2*cos(2*boss.frames/boss.maxFrameCnt)
   else
    if (move_to_next_cycle()) then
     boss.x = boss.cachex
     boss.x = boss.cachey
    else
     retrieve_next_action()
    end
   end
  elseif (boss.action == "mad") then
   if (first_frame()) then
    boss.cachex = boss.x
    boss.cachey = boss.y
   end
   if (move_to_next_frame()) then
    boss.s = 46
    boss.x += cos(boss.frames/boss.maxFrameCnt)
   else
    if (move_to_next_cycle()) then
     local c = get_actor_center(boss)
     apply_angle_mag_dynamic(make_dynamic(c.x,c.y),rnd(1),0.4)
     boss.x = boss.cachex
     boss.y = boss.cachey
    else
     retrieve_next_action()
    end
   end
  elseif (boss.action == "charging") then
   if (first_frame()) then
    boss.cachex = boss.x - 20 + rnd(40)
    boss.cachey = boss.y - 20 + rnd(40)
   end
   if (move_to_next_frame()) then
    boss.s = 46
    boss.x += (boss.cachex - boss.x) * (1 - (boss.frames / boss.maxFrameCnt))
    boss.y += (boss.cachey - boss.y) * (1 - (boss.frames / boss.maxFrameCnt))
   else
    if (move_to_next_cycle()) then
     boss.cachex = boss.x - 20 + rnd(40)
     boss.cachey = boss.y - 20 + rnd(40)
    else
     retrieve_next_action()
    end
   end
  elseif (boss.action == "go home") then
   if (move_to_next_frame()) then
    boss.s = 14
    boss.x += (cx - boss.w*4 - boss.x) * (1 - (boss.frames / boss.maxFrameCnt))
    boss.y += (cy - boss.h*4 - boss.y) * (1 - (boss.frames / boss.maxFrameCnt))
   else
    if (move_to_next_cycle()) then
     set_boss_action("floating",120,1)
    else
     set_boss_action("floating",120,1)
    end
   end
  else
   retrieve_next_action()
  end
 end
end

function first_frame()
 return (boss.frames == boss.maxFrameCnt)
end

function move_to_next_frame()
 boss.frames -= 1
 return (boss.frames > 0)
end

function move_to_next_cycle()
 boss.cycles -= 1
 boss.frames = boss.maxFrameCnt
 return (boss.cycles > 0)
end

function retrieve_next_action()
 while true do
  local r = ceil(rnd(4))
  if (r == 1) then
   set_boss_action("floating",120,1)
   return
  end
  if (r == 2) then
   set_boss_action("mad",3,10)
   return
  end
  if (r == 3) then
   set_boss_action("charging",20,5)
   return
  end
  if (r == 4) then
   local c = get_actor_center(boss)
   if (distance_to_center(c.x, c.y) > 30) then
    set_boss_action("go home",40,1)
    return
   end
   sfx(3)
  end
 end
end

function set_boss_action(action, maxFrameCnt, cycles)
 boss.action = action
 boss.maxFrameCnt = maxFrameCnt
 boss.frames = maxFrameCnt
 boss.cycles = cycles
end

-->8
--render

function _draw()
	cls()
	draw_particles()
	draw_actors()
	print(boss.action,0,0)
 print(boss.frames,0,8)
 print(boss.maxFrameCnt,0,16)
 print(boss.cycles,0,24)
	print(player.frames,0,120)
 print("sCORE: "..tostring(points),0,5,10,11)
end

function draw_actors()
 for a in all(actors) do
  spr(a.s,a.x,a.y,a.w,a.h,a.fh,a.fv)
 end
end

function draw_particles()
 for p in all(particles) do
  pset(p.x,p.y,p.c)
 end
end

function draw_actor_box(a)
 local ac = get_actor_center(a)
 rect(ac.x-a.bw,ac.y-a.bh,
 					ac.x+a.bw,ac.y+a.bh)
end

function select_platform_spr(sx,sy,ox,oy,spr_t,spr_s,spr_d)
 local angle = atan2(sx-ox,sy-oy)
 local output = {}
 -- {spr,fliph,flipv}
 if (angle < 1/16) then
  output = {spr_s,false,false}
 elseif (angle < 3/16) then
  output = {spr_d,false,true}
 elseif (angle < 5/16) then
  output = {spr_t,false,true}
 elseif (angle < 7/16) then
  output = {spr_d,true,true}
 elseif (angle < 9/16) then
  output = {spr_s,true,false}
 elseif (angle < 11/16) then
  output = {spr_d,true,false}
 elseif (angle < 13/16) then
  output = {spr_t,false,false}
 elseif (angle < 15/16) then
  output = {spr_d,false,false}
 else
  output = {spr_s,false,false}
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

function distance_to_center(x,y)
 return sqrt((cx - x)^2 + (cy - y)^2)
end

function gen_simple_particle(x,y)
 p = make_particle(x,y,2)
 apply_angle_mag_dynamic(p,rnd(1),0.1)
 p.frames = 30
end

function gen_desert_particle(x,y)
 p = make_particle(x,y,9)
 apply_angle_mag_dynamic(p,rnd(1),0.4)
 p.frames = 20

 p2 = make_particle(x,y,15)
 apply_angle_mag_dynamic(p2,rnd(1),0.5)
 p2.frames = 20
end

--gives a random platform id, will not return excluded id. give 0 if unnecessary
function random_platform(exclude_num)
 random = ceil(rnd(platform_cnt))
 while (random == exclude_num) do
  random = ceil(rnd(platform_cnt))
 end
 return platforms[random]
end

-->8
--boss attacks

attack_list = {}

function random_attack()
 return ceil(rnd(#attack_list))
end
__gfx__
00000000bbbbbbbbb300000000000b00aaaaaaaaa900000000000a00000000000000000000000000000000000000000000000000000000000000000dd0000000
000000003bb3bbb3bbb300000000bb309aa9aaa9aaa900000000aa9000000000000000000000000000000000000000000000000000000000000000daad000000
000000000bb43bb0bbbb3400000bbb300aaf9aa0aaaa9f00000aaa9000000000000000000000000000000000000000000000000000000000000000daad000000
0000000003344b30bb34444000bb3340099ffa90aa9ffff000aa99f00000000000000000000000000000000000000000000000000000000000000daaaad00000
0000000000444300b34444440bb3444000fff900a9ffffff0aa9fff000000000000000000000000000000000000000000000000000000000ddddd99aa99ddddd
0000000000444400bbb34400bbb3444400ffff00aaa9ff00aaa9ffff00000000000000000000000000000000000000000000000000000000daaaa92aa29aaaad
0000000000044000bbb300000b344444000ff000aaa900000a9fffff000000000000000000000000000000000000000000000000000000000daaa92aa29aaad0
0000000000040000b300000000000444000f0000a900000000000fff0000000000000000000000000000000000000000000000000000000000daa92aa29aad00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daaaaaaaad000
0000000000a99a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000da2aaaaaad000
000000000a9889a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daaa2222aaad00
000000000988889000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daaaaaaaaaad00
00000000098888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daaaaaddaaaaad0
000000000a9889a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daaadd00ddaaad0
0000000000a99a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daadd000000ddaad
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000000000ddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0000000
0000000000cccc0000eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88d000000
000000000c1cc1c00e1ee1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88d000000
000000000c1cc1c00e1ee1e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111881110000
000000000cccccc00eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd111111ddddd
000000000c2222c00e2222e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88889111198888d
0000000000cccc0000eeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d888928829888d0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8892882988d00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88888888d000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88888888d000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8882222888d00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8828888288d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88888dd88888d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d888dd00dd888d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88dd000000dd88d
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000000000ddd
__gff__
0000010000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002f450264501f4501b45029450234501f4501b4501945025450214501c4502b4002840025400224001f4001c4000e0001400024400214001c400194002f40030400304002b60031400314003140031400
00050000091500a150131502615013150131501410007100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c05022050270502d0502e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001a55020550285502b55033550355500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
