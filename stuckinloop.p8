pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--datatypes

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
boss_queue = {}
gamestate = "menu"
totalframes = 0
cx = 63
cy = 63
prev_button_states = btn()

function make_actor(s,x,y,h,w)
 --basic datatype for most objects
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
  frames = 0,
  maxFrameCnt = 0,
  targetx = 0,
  targety = 0
	}
	add(actors,a)
	return a
end

function make_platform(x,y)
 --a location for the player to move to
 p = make_actor(spr_platform,x,y,1,1)
 p.spriteset = {1,2,3}
 p.type = "grass"
 p.state = "static"
 add(platforms, p)
end

function make_platform_random_insert(x,y)
 p = make_actor(spr_platform,x,y,1,1)
 p.spriteset = {1,2,3}
 p.type = "grass"
 p.state = "static"
 local i = ceil(rnd(#platforms))
 if (i <= player.current_platform) then
  player.current_platform += 1
 end
 add(platforms, p, i)
end

function make_player(x,y)
 --player class
 p = make_actor(spr_player,x,y,1,1)
 p.state = "static"
 p.current_platform = 1
 p.platform_buffer = 8
 p.invincibleTimer = 0
 p.life = 3
 return p
end

function make_boss()
 --boss class
 b = make_actor(spr_boss,cx-8,cy-8,2,2)
 b.state = "static"
 b.action = "static"
 b.frames = 0
 b.maxFrameCnt = 0
 b.cycles = 0
 b.maxCycleCnt = 0
 b.cachex = 0
 b.cachey = 0
 b.life = 3
 b.platform = 0
 return b
end

function make_dynamic(x,y)
 --projectiles
 d = make_actor(17,x,y,1,1)
 d.xvel = 0
 d.yvel = 0
 d.damage = 1
 add(dynamics,d)
 return d
end

function make_particle(x,y,c)
 --visual effects
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
-->gamestate

function _init()
 --runs on start up
end

function start_game()
 generate_platforms(platform_cnt,1,1)

 player = make_player(0,0,1,1)
 boss = make_boss()
 gamestate = "game"
 points = 0

 add_boss_queue("floating",120,2,-1)
 add_boss_queue("dash to platform",80,1,-1)
 add_boss_queue("dash to next platform",8,#platforms,-1)
end

function end_game()
 platforms = {}
 actors = {}
 player = {}
 boss = {}
 dynamics = {}
 gamestate = "end"
end

-->8
--update

function _update60()
 totalframes += 1
 update_particles()

 if (gamestate == "game") then

  get_user_input()
  remove_desert_if_touching()
  update_all_platforms()
		update_player()
	 update_boss()
		update_dynamics()
		check_dynamic_collisions()
	 check_boss_collision()
		add_desert_if_missing()
  clean_up_dynamics()

  if (player.life <= 0) then
   end_game()
  end

 elseif (gamestate == "menu") then
  if(btn() > 0) then
   start_game()
  end
 elseif (gamestate == "end") then
  if (totalframes % 10 == 0) then
   gen_firework_particle(rnd(128),rnd(128))
  end
  if(btn(❎) and btn(🅾️)) then
   start_game()
  end
 end
 record_button_states()
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
   ((player.current_platform - (ceil(#platforms/2)) - 1) % #platforms) + 1
  player.state = "jumping"
  player.frames = 10
  player.s = 34
 end
end

function btnpc(index)
 --like btnp but we can tune it
 local mask = 1
 for i=1, index do
  mask *= 2
 end
 return (btn(index) and (band(prev_button_states,mask) == 0))
end

function record_button_states()
 prev_button_states = btn()
end

-->8
--draw

function _draw()
	cls()
	if (gamestate == "game") then
	 draw_particles()
		draw_actors()
  print(boss.action,0,16)
  print(boss.platform,0,24)
	 print("sCORE: "..tostring(points),0,5,10,11)
 elseif (gamestate == "menu") then
  rectfill(0,0,128,128,1)
  for i=1,16 do
   print("stuck in a loop",cx + 30*cos((i/16) + time()/4) - 25,cy + 30*sin((i/16) + time()/8) - 20,i)
  end
  print("press any key to start",20,100,0)
 elseif (gamestate == "end") then
  rectfill(0,0,128,128,2)
  draw_particles()
  for i=1,16 do
   print("you got looped",cx + 30*cos((i/16) + time()/4) - 25,cy + 30*sin((i/16) + time()/8) - 20,i)
  end
  print("sCORE: "..tostring(points),40,85)
  print("press ❎ and 🅾️ to play again",5,100,0)
 end
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
 --draws the collision bounding box
 local ac = get_actor_center(a)
 rect(ac.x-a.bw,ac.y-a.bh,
 					ac.x+a.bw,ac.y+a.bh)
end

-->8
--actor

function set_actor_frames(actor,f)
 actor.frames = f
 actor.maxFrameCnt = f
end

function do_actors_collide(a,b)
 local ac = get_actor_center(a)
 local bc = get_actor_center(b)
 return ((ac.x + a.bw > bc.x - b.bw) and
    (ac.x - a.bw < bc.x + b.bw) and
    (ac.y + a.bh > bc.y - b.bh) and
    (ac.y - a.bh < bc.y + b.bh))
end

function move_actor_center(x,y,actor)
 --move the actor to center on these coords
 actor.x = x - (actor.w*4)
 actor.y = y - (actor.h*4)
end

function get_actor_center(a)
 c = {x = a.x + (a.w*4),
      y = a.y + (a.h*4)}
 return c
end

function move_actor_linear(actor,tx,ty,frames,useCenter)
 --move actor to tx and ty in "n" frames
 if (useCenter) then
  local c = get_actor_center(actor)
  actor.x += (tx - c.x) / frames
  actor.y += (ty - c.y) / frames
 else
  actor.x += (tx - actor.x) / frames
  actor.y += (ty - actor.y) / frames
 end
end

function move_actor_const_accel(actor,tx,ty,frames,maxframes,useCenter)
 --move actor to tx and ty in "n" frames, constantly acceleratting
 if (useCenter) then
  local c = get_actor_center(actor)
  actor.x += (tx - c.x) * ((maxframes - frames) / fib(maxframes))
  actor.y += (ty - c.y) * ((maxframes - frames) / fib(maxframes))
 else
  actor.x += (tx - actor.x) * ((maxframes - frames) / fib(maxframes))
  actor.y += (ty - actor.y) * ((maxframes - frames) / fib(maxframes))
 end
end

function move_actor_dash_pause(actor,tx,ty,frames,maxframes,useCenter)
 --move actor to tx and ty quickly, then pause till frames complete
 if (useCenter) then
  local c = get_actor_center(actor)
  actor.x += (tx - c.x) * (1 - (frames / maxframes))
  actor.y += (ty - c.y) * (1 - (frames / maxframes))
 else
  actor.x += (tx - actor.x) * (1 - (frames / maxframes))
  actor.y += (ty - actor.y) * (1 - (frames / maxframes))
 end
end

-->8
--player

function update_player()
 if (player.state == "jumping") then
  animate_to_platform()
 elseif (player.state == "static") then
  warp_to_platform()
 end
 if (player.invincibleTimer > 0) then
  if (player.invincibleTimer % 8 <= 3) then
   player.s = 0
  else
   player.s = 35
  end
  player.invincibleTimer -= 1
 end
end

function animate_to_platform()
 --animate player motion to next platform
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

function damage_player(d)
 sfx(1)
 player.life -= d
 player.invincibleTimer = 120;
end

-->8
--platforms

function generate_platforms(n)
 for i=1,n do
  make_platform(0,0)
 end
end

function add_platforms(n)
 --creates more platforms away from play area and tells all platforms to regroup
 for i=1,n do
  local r = rnd(1)
  make_platform_random_insert(cx+128*cos(r),cy+128*sin(r))
 end
 for i=1,#platforms do
  platforms[i].state = "seeking"
  set_actor_frames(platforms[i],100)
 end
end

function update_all_platforms()
 place_platforms_circle(cx,cy,
  56+5*sin(0.0005*totalframes*7),
  sin(0.0005*totalframes)
 )
 animate_all_platforms()
 rotate_all_platform_spr()
end

function animate_all_platforms()
 for platform in all(platforms) do
  if (platform.state == "static") then
   warp_platform_to_target(platform)
  elseif (platform.state == "seeking") then
   drift_platform_to_target(platform)
  end

  --example
  -- if (isExploding) then
      -- set spr dependent on platform.frames
      -- play sound dependent on platform.frames
      -- make explosion particles dependent on platform.frames
      -- check for blast radius dependent on platform.frames
      -- platform.frames -= 1
      -- if frames hits zero, change to not exploding
  -- end

  -- blink in an ABAB pattern
  -- if (platform.frames % 10 < 5) platform.s = EXPLODING_SPR_NUMBER
  -- else platform.s = NORMAL_PLATFORM_SPR_NUMBER

 end
end

function warp_platform_to_target(platform)
 move_actor_center(platform.targetx,platform.targety,platform)
end

function drift_platform_to_target(platform)
 move_actor_dash_pause(platform,platform.targetx,platform.targety,
  platform.frames,platform.maxFrameCnt, true)
 platform.frames -= 1
 if (platform.frames <= 0) then
  platform.state = "static"
 end
end

function place_platforms_circle(x,y,r,a)
 for n=1,#platforms do
  platforms[n].targetx = r*cos(((n-1)/#platforms)+a) + x
  platforms[n].targety = r*sin(((n-1)/#platforms)+a) + y
 end
end

function rotate_all_platform_spr()
 for i=1,#platforms do
  local p = platforms[i]
  local u = rotate_platform_spr(p.x,p.y,cx,cy,
   p.spriteset[1],p.spriteset[2],p.spriteset[3])
  p.s = u[1]
  p.fh = u[2]
  p.fv = u[3]
 end
end

function rotate_platform_spr(sx,sy,ox,oy,spr_t,spr_s,spr_d)
 --selects and flips the platform sprite based on the angle
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

function find_closest_platform_index(x,y)
 -- returns the closest platform to x and y, based on the platforms's center
 local index = 1
 local hs = 256
 for p=1,#platforms do
  local c = get_actor_center(platforms[p])
  local uA = distance(c.x,c.y,x,y)
  if (uA < hs) then
   hs = uA
   index = p
  end
 end
 return index
end

function get_platform_coords(index)
 --returns the place where the player should sit above a platform
 local p = platforms[index]
 local pcx = p.x + (p.w*4)
 local pcy = p.y + (p.h*4)
 local angle = atan2(pcx-cx,pcy-cy)
 local dx = -player.platform_buffer * cos(angle)
 local dy = -player.platform_buffer * sin(angle)
 return {x=p.x+dx,y=p.y+dy}
end

--desert

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

-->8
--dynamics

function update_dynamics()
 for d in all(dynamics) do
  d.x += d.xvel
  d.y += d.yvel
 end
end

function clean_up_dynamics()
 --if dynamics are twice past the view screen, they are deleted
 for d in all(dynamics) do
  if (d.x < -128 or d.x > 256 or d.y < -128 or d.y > 256) then
   del(dynamics,d)
  end
 end
end

function apply_vector_dynamic(d,dx,dy)
 d.xvel += dx
 d.yvel += dy
end

function apply_angle_mag_dynamic(d,a,m)
 return apply_vector_dynamic(d,m*cos(a),m*sin(a))
end

function check_dynamic_collisions()
 for d in all(dynamics) do
  if (do_actors_collide(player,d) and (d.damage > 0) and player.invincibleTimer <= 0) then
   del(dynamics, d)
  	del(actors, d)
   damage_player(d.damage)
  end
 end
end

-->8
--particles

function update_particles()
 --move all particles and advance frames
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

function gen_firework_particle(x,y)
 for i=1,50 do
  p = make_particle(x,y,10)
  apply_angle_mag_dynamic(p,rnd(1),0.4)
  p.frames = 20 + rnd(20)
 end
 for i=1,100 do
  p = make_particle(x,y,9)
  apply_angle_mag_dynamic(p,rnd(1),0.6)
  p.frames = 20 + rnd(20)
 end
 for i=1,150 do
  p = make_particle(x,y,8)
  apply_angle_mag_dynamic(p,rnd(1),0.8)
  p.frames = 20 + rnd(20)
 end
end

function gen_laser(x,y,angle,c)
 for i=1,128,2 do
  p = make_particle(x+i*cos(angle),y+i*sin(angle),c)
  apply_angle_mag_dynamic(p,rnd(1),0.4)
  p.frames = 5
 end
end

function gen_hint_laser(x,y,angle,c)
 for i=1,32 do
  d = rnd(128)
  p = make_particle(x+d*cos(angle),y+d*sin(angle),c)
  apply_angle_mag_dynamic(p,rnd(1),0.4)
  p.frames = 20
 end
end

-->8
--boss

function update_boss()
 if (boss.action == "floating") then
  run_boss_float()
 elseif (boss.action == "mad") then
  run_boss_mad()
 elseif (boss.action == "charging") then
  run_boss_charging()
 elseif (boss.action == "dash to platform") then
  run_boss_dash_rnd_platform()
 elseif (boss.action == "dash to next platform") then
  run_boss_dash_nxt_platform()
 elseif (boss.action == "ring run") then
  run_boss_ring_run()
 elseif (boss.action == "go home") then
  run_boss_go_home()
 elseif (boss.action == "panting") then
  run_boss_panting()
 elseif (boss.action == "hit") then
  run_boss_hit()
 elseif (boss.action == "hint laser") then
  run_boss_hint_laser()
 elseif (boss.action == "fire laser") then
  run_boss_fire_laser()
 else
  sfx(0)
  retrieve_next_action()
 end
end

function run_boss_float()
 --boss floats in a figure eight each cycle
 if (first_frame()) then
  boss.state = "active"
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
   boss.y = boss.cachey
  else
   retrieve_next_action()
  end
 end
end

function run_boss_mad()
 --boss shakes and spits a fireball each cycle
 if (first_frame()) then
  boss.state = "active"
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
end

function run_boss_charging()
 --boss charges around in short bursts
 if (first_frame()) then
  boss.state = "active"
  boss.cachex = boss.x + 20*cos(rnd())
  boss.cachey = boss.y + 20*sin(rnd())
 end
 if (move_to_next_frame()) then
  boss.s = 46
  move_actor_dash_pause(boss,boss.cachex,boss.cachey,boss.frames, boss.maxFrameCnt, false)
 else
  if (move_to_next_cycle()) then
   boss.cachex = boss.x + 20*cos(rnd())
   boss.cachey = boss.y + 20*sin(rnd())
  else
   retrieve_next_action()
  end
 end
end

function run_boss_dash_rnd_platform()
 --boss goes to a rnd platform each cycle
 if (first_frame()) then
  local index = ceil(rnd(#platforms))
  local t = get_platform_coords(index)
  boss.targetx = t.x
  boss.targety = t.y
  boss.state = "active"
  boss.platform = index
  boss.direction = randDirection()
 end
 if (move_to_next_frame()) then
  boss.s = 14
  move_actor_linear(boss,boss.targetx,boss.targety,boss.frames,true)
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_dash_nxt_platform()
 --boss goes to the next nearest platform, then in consectutive order for each cycle
 if (first_frame()) then
  if (first_cycle()) then
   local c = get_actor_center(boss)
   boss.platform = find_closest_platform_index(c.x, c.y)
  end
  boss.platform = ((boss.platform - 1 + boss.direction) % #platforms) + 1
  local t = get_platform_coords(boss.platform)
  boss.targetx = t.x
  boss.targety = t.y
  boss.state = "active"
 end
 if (move_to_next_frame()) then
  boss.s = 14
  local c = get_actor_center(boss)
  move_actor_linear(boss,boss.targetx,boss.targety,boss.frames,true)
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_ring_run()
 --boss runs in a circle each cycle
 if (first_frame()) then
  local c = get_actor_center(boss)
  boss.radius = distance_to_center(c.x,c.y)
  boss.angle = atan2(c.x-cx,c.y-cy)
 end
 if (move_to_next_frame()) then
  boss.s = 46
  move_actor_center(
   cx + boss.radius*cos(boss.angle + (1 - (boss.frames / boss.maxFrameCnt))),
   cy + boss.radius*sin(boss.angle + (1 - (boss.frames / boss.maxFrameCnt))),
   boss
  )
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_go_home()
 --boss moves to the center of the screen each cycle
 if (first_frame()) then
  boss.state = "active"
 end
 if (move_to_next_frame()) then
  boss.s = 14
  move_actor_const_accel(boss,cx,cy,boss.frames, boss.maxFrameCnt, true)
 else
  if (move_to_next_cycle()) then
   set_boss_action("floating",120,1)
  else
   set_boss_action("floating",120,1)
  end
 end
end

function run_boss_panting()
 --boss floats in a weak state each cycle
 if (first_frame()) then
  boss.state = "weak"
  boss.cachex = boss.x
  boss.cachey = boss.y
 end
 if (move_to_next_frame()) then
  if (totalframes % 60 < 30) then
   boss.s = 12
  else
   boss.s = 44
  end
  boss.x += 0.1*cos(boss.frames/boss.maxFrameCnt)
  boss.y += 0.1*cos(2*boss.frames/boss.maxFrameCnt)
 else
  if (move_to_next_cycle()) then
   boss.x = boss.cachex
   boss.y = boss.cachey
  else
   retrieve_next_action()
  end
 end
end

function run_boss_hit()
 --boss flashes each cycle
 if (first_frame()) then
  boss.state = "invincible"
 end
 if (move_to_next_frame()) then
  if (boss.frames % boss.maxFrameCnt < boss.maxFrameCnt/2) then
   boss.s = 42
  else
   boss.s = 48
  end
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_hint_laser()
 --boss generates particles in a direction each cycle
 if (first_frame()) then
  boss.state = "active"
  boss.cachex = boss.x
  boss.cachey = boss.y
  if (first_cycle()) then
   local t = get_platform_coords(ceil(rnd(#platforms)))
   boss.targetx = t.x
   boss.targety = t.y
   boss.direction = randDirection()
   boss.angle = atan2(boss.targetx-boss.cachex,boss.targety-boss.cachey)
  end
 end
 if (move_to_next_frame()) then
  boss.s = 46
  boss.x += cos(boss.frames/boss.maxFrameCnt)
  local c = get_actor_center(boss)
  gen_hint_laser(c.x,c.y,boss.angle,10)
 else
  if (move_to_next_cycle()) then
   boss.x = boss.cachex
   boss.y = boss.cachey
  else
   add_boss_queue("fire laser",120,1,1)
   retrieve_next_action()
  end
 end
end

function run_boss_fire_laser()
 --boss shakes and trys to apply damage using the angle from hint laser each cycle
 if (first_frame()) then
  boss.state = "active"
 end
 if (move_to_next_frame()) then
  boss.s = 42
  sfx(5)
  local angle = boss.angle + 0.05*boss.direction*(1-boss.frames/boss.maxFrameCnt)
  local c = get_actor_center(boss)
  gen_laser(c.x,c.y,angle,7)
  if (raycast_to_actor(c.x,c.y,angle,player) and player.invincibleTimer <= 0) then
   damage_player(1)
   retrieve_next_action()
  end
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function first_frame()
 return (boss.frames == boss.maxFrameCnt)
end

function first_cycle()
 return (boss.cycles == boss.maxCycleCnt)
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
 --randomly selects the next attack or attack pattern

 if (queued_boss_action()) then
  -- if action is in queue, it is run and the rnd is aborted
  return
 end

 local c = get_actor_center(boss)
 if (distance_to_center(c.x, c.y) > 64) then
  set_boss_action("go home",40,1)
  return
 end

 while true do
  local r = ceil(rnd(8))
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
   if (distance_to_center(c.x, c.y) > 30) then
    set_boss_action("go home",40,1)
    return
   end
  end
  if (r == 5) then
   set_boss_action("panting",160,2)
   return
  end
  if (r == 6) then
   set_boss_action("hint laser",3,10)
   return
  end
  if (r == 7) then
   set_boss_action("dash to platform",80,1)
   add_boss_queue("dash to next platform",8,#platforms,-1)
   return
  end
  if (r == 8) then
   if (distance_to_center(c.x, c.y) > 30) then
    set_boss_action("ring run",160,1)
    return
   end
  end
 end
end

function set_boss_state(state)
 boss.state = state
end

function set_boss_action(action, maxFrameCnt, cycles)
 boss.action = action
 boss.maxFrameCnt = maxFrameCnt
 boss.frames = maxFrameCnt
 boss.cycles = cycles
 boss.maxCycleCnt = cycles
end

function queued_boss_action()
 if (#boss_queue > 0) then
  set_boss_action(boss_queue[1].action,
   boss_queue[1].maxFrameCnt,
   boss_queue[1].cycles)
  del(boss_queue, boss_queue[1])
  return true
 end
 return false
end

function add_boss_queue(action, maxFrameCnt, cycles, index)
 bq = { action = action,
        maxFrameCnt = maxFrameCnt,
        cycles = cycles}
 if (index <= 0) then
  add(boss_queue, bq)
 else
  add(boss_queue, bq, index)
 end
 return bq
end

function check_boss_collision()
 if (do_actors_collide(player,boss) and player.invincibleTimer <= 0) then
  if (boss.state == "weak") then
   set_boss_action("hit",10,10)
   points += 5;
   damage_boss(1)
  elseif (boss.state == "active") then
   damage_player(1)
  end
 end
end

function damage_boss(d)
 sfx(4)
 boss.life -= d
end

-->8
--helper functions

function empty_list(list)
 for i in all(list) do
  del(list,i)
 end
end

function virtualize(x)
 return x / 128
end

function randDirection()
 return ((ceil(rnd(2)) - 1.5)*2)
end

function distance_to_center(x,y)
 return distance(cx,cy,x,y)
end

function distance(x1,y1,x2,y2)
 return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function line_rect(x1,y1,x2,y2,x3,y3,x4,y4)
 uA = line_line_collision(x1,y1,x2,y2,x3,y3,x4,y3) --top
 uB = line_line_collision(x1,y1,x2,y2,x3,y4,x4,y4) --bottom
 uC = line_line_collision(x1,y1,x2,y2,x3,y3,x3,y4) --left
 uD = line_line_collision(x1,y1,x2,y2,x4,y3,x4,y4) --right
 return (uA == true or uB == true or uC == true or uD == true)
end

function line_line_collision(x1,y1,x2,y2,x3,y3,x4,y4)
 denom = (virtualize(y4-y3)*virtualize(x2-x1) - virtualize(x4-x3)*virtualize(y2-y1))
 uA = (virtualize(x4-x3)*virtualize(y1-y3) - virtualize(y4-y3)*virtualize(x1-x3)) / denom
 uB = (virtualize(x2-x1)*virtualize(y1-y3) - virtualize(y2-y1)*virtualize(x1-x3)) / denom
 return (uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1)
end

function raycast_to_actor(x,y,ang,a)
 local c = get_actor_center(a)
 return line_rect(x,y,x+128*cos(ang),y+128*sin(ang),
   c.x - a.bw, c.y - a.bh, c.x + a.bw, c.y + a.bh)
end

function fib(steps)
 local n = 0
 for i=1,steps do
  n += i
 end
 return n
end

-->8
--boss attacks

--gives a random platform id, will not return excluded id. give 0 if unnecessary
function random_platform(exclude_num)
 random = ceil(rnd(platform_cnt))
 while (random == exclude_num) do
  random = ceil(rnd(platform_cnt))
 end
 return platforms[random]
end

attack_list = {}

function random_attack()
 return ceil(rnd(#attack_list))
end


bomb_frames = 60
function platform_bomb()
 --makes a list of 5 index right next to each other (unless wrapping around platform limit)
 bomb_index_list = bomb_index_list_creation(ceil(rnd(platform_cnt)))

 --makes the platform list using the index list
 bomb_list = {}
 for i in all(bomb_index_list) do
  table.insert(bomb_list, platform[i])
 end

 --display and animate the 3 sprites
 if (bomb_frames >= 40) then
  for i=1,5 do
   spr(18, platforms[i].x, platforms[i].y)
   bomb_frames -= 1
  end
 elseif (bomb_frames >= 20) then
  for i=1,5 do
   spr(19, platforms[i].x, platforms[i].y)
   bomb_frames -= 1
  end
 else
  for i=1,5 do
   spr(20, platforms[i].x, platforms[i].y)
   bomb_frames -= 1
  end
 end
 --deal damage when the last sprite leaves
 --create particle effects
end

--suggestion from Ammon
--add a variable to the platform class (platform.isExploding or something)
--then go to the function animate_all_platforms() and and add an if statement
--in here to check if it is a bomb.
--Whatever sets this exploding varible to true should also set the platform.frames to something
--using set_actor_frames()
--then use those frames in animate_all_platforms() as a timer to animate the flashing, and trigger
--the blast radius check. The boss uses this same system
--but platform.state is important to either be "seeking" or "static"
--if you want normal movement


function bomb_index_list_creation(x)
 --creates a list of 5 platforms right next to each other
 bomb_index_list = {x-2, x-1, x, x+1, x+2}

 for i=1,2 do
  if (bomb_index_list[i] < 1) do
   bomb_index_list[i] = platform_cnt + bomb_list[i]
  end
 end

 for i=4,5 do
  if (bomb_index_list[i] > platform_cnt) do
   bomb_index_list[i] = bomb_index_list[i] - platform_cnt
  end
 end

 return bomb_index_list
end


__gfx__
00000000bbbbbbbbb300000000000b00aaaaaaaaa900000000000a0000000000000000000000000000000000000000000000000dd00000000000000dd0000000
000000003bb3bbb3bbb300000000bb309aa9aaa9aaa900000000aa900000000000000000000000000000000000000000000000deed000000000000daad000000
000000000bb43bb0bbbb3400000bbb300aaf9aa0aaaa9f00000aaa900000000000000000000000000000000000000000000000deed000000000000daad000000
0000000003344b30bb34444000bb3340099ffa90aa9ffff000aa99f0000000000000000000000000000000000000000000000d1ee1d0000000000daaaad00000
0000000000444300b34444440bb3444000fff900a9ffffff0aa9fff00000000000000000000000000000000000000000ddddd19ee91dddddddddd99aa99ddddd
0000000000444400bbb34400bbb3444400ffff00aaa9ff00aaa9ffff0000000000000000000000000000000000000000deee199ee991eeeddaaaa92aa29aaaad
0000000000044000bbb300000b344444000ff000aaa900000a9fffff00000000000000000000000000000000000000000deee92ee29eeed00daaa92aa29aaad0
0000000000040000b300000000000444000f0000a900000000000fff000000000000000000000000000000000000000000dee92ee29eed0000daa92aa29aad00
0000000000000000aaaaaaaa999999998888888800000000000000000000000000000000000000000000000000000000000deeeeeeeed000000daaaaaaaad000
0000000000a99a00a000000a900000098000000800000000000000000000000000000000000000000000000000000000000dee2222eed000000da2aaaaaad000
000000000a9889a0a000000a90000009800000080000000000000000000000000000000000000000000000000000000000deeeeeeeeeed0000daaa2222aaad00
0000000009888890a000000a90000009800000080000000000000000000000000000000000000000000000000000000000deeeeeeeeeed0000daaaaaaaaaad00
0000000009888890a000000a9000000980000008000000000000000000000000000000000000000000000000000000000deeeeeddeeeeed00daaaaaddaaaaad0
000000000a9889a0a000000a9000000980000008000000000000000000000000000000000000000000000000000000000deeedd00ddeeed00daaadd00ddaaad0
0000000000a99a00a000000a900000098000000800000000000000000000000000000000000000000000000000000000deedd000000ddeeddaadd000000ddaad
0000000000000000aaaaaaaa999999998888888800000000000000000000000000000000000000000000000000000000ddd0000000000dddddd0000000000ddd
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000000000000dd00000000000000dd0000000
0000000000cccc0000eeee0000aaaa00000000000000000000000000000000000000000000000000000000dffd000000000000deed000000000000d88d000000
000000000c1cc1c00e1ee1e00a1aa1a0000000000000000000000000000000000000000000000000000000dffd000000000000deed000000000000d88d000000
000000000c1cc1c00e1ee1e00a1aa1a000000000000000000000000000000000000000000000000000000dffffd0000000000deeeed000000000111881110000
000000000cccccc00eeeeee00aaaaaa0000000000000000000000000000000000000000000000000dddddffffffdddddddddde1ee1edddddddddd111111ddddd
000000000c2222c00e2222e00a2222a0000000000000000000000000000000000000000000000000dffff9ffff9ffffddeeee19ee91eeeedd88889111198888d
0000000000cccc0000eeee0000aaaa000000000000000000000000000000000000000000000000000dffff9ff9ffffd00dee192ee291eed00d888928829888d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000dff9ffff9ffd0000dee92ee29eed0000d8892882988d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000dff2222ffd000000de92ee29ed000000d88888888d000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000df277772fd000000deeeeeeeed000000d88888888d000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000dff2eeee2ffd0000deee2222eeed0000d8882222888d00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000dff277772ffd0000deeeeeeeeeed0000d8828888288d00
000000000000000000000000000000000000000000000000000000000000000000000000000000000dffff2222ffffd00deeeeeddeeeeed00d88888dd88888d0
000000000000000000000000000000000000000000000000000000000000000000000000000000000dfffdd00ddfffd00deeedd00ddeeed00d888dd00dd888d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000dffdd000000ddffddeedd000000ddeedd88dd000000dd88d
00000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000000000dddddd0000000000dddddd0000000000ddd
__gff__
0000010000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002f450264501f4501b45029450234501f4501b4501945025450214501c4502b4002840025400224001f4001c4000e0001400024400214001c400194002f40030400304002b60031400314003140031400
00050000091500a150131502615013150131501410007100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0000167201a7201d7001250031700005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000000000263008240026500e250036501425003650102400363009220036100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000865008650086500970009700097000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
