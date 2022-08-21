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
life_get_pickup_cnt = 20

--global varibles
platform_cnt = 15
starting_platform = 1
points = 0
pickups = 0
actors = {}
particles = {}
platforms = {}
dynamics = {}
background_objects = {}
player = {}
boss_queue = {}
gamestate = "menu"
gamelevel = 1
progress_event = 1
totalframes = 0
cx = 63
cy = 63
prev_button_states = btn()
spin_start = 0

debug_testing = true

function make_actor(s,x,y,w,h)
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
	if (gamestate == "game") then
		if (i <= player.current_platform) then
	  player.current_platform += 1
	 end
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
 b.state = "disabled"
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

function make_dynamic(s,x,y,w,h)
 --projectiles
 d = make_actor(s,x,y,w,h)
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
							accel = 1,
       frames = 1}
 add(particles,p)
 return p
end

function make_background_object(x,y,s,w,h)
 --visual effects
	d = { s = s,
       x = x,
						 y = y,
						 w = w,
						 h = h,}
 d.xvel = 0
 d.yvel = 0
	d.accel = 1
 add(background_objects,d)
 return d
end

-->8
-->gamestate

function _init()
 --runs on start up
	generate_platforms(10)
end

function start_game()
	empty_list(actors)
	empty_list(platforms)
 generate_platforms(platform_cnt)

 player = make_player(0,0,1,1)
 boss = make_boss()
 gamestate = "game"
 gamelevel = 1
 progress_event = 5 -- five sand tiles
 points = 0
	pickups = 0
	_update60()
end

function end_game()
 platforms = {}
 actors = {}
 player = {}
 --boss = {}
 dynamics = {}
 gamestate = "end"
	generate_platforms(10)
end

-->8
--update

function _update60()
 totalframes += 1
 update_particles()
	update_all_platforms()
	update_background_objects()

if (gamestate == "menu") then
	if (totalframes % 10 == 0) then
		for n=1,3 do
			gen_star_particle(cx,40,7)
		end
	end
	if(btn() > 0) then
		start_game()
	end
elseif (gamestate == "game") then
		if (totalframes % 10 == 0) then
			for n=1,3 do
		  gen_star_particle(cx,cy,7)
		 end
	 end

		if (totalframes % 120 == 0) then
			gen_planet()
		end

		get_user_input()
  remove_desert_if_touching()
		update_player()

  if (boss.state != "disabled") then
   update_boss()
   check_boss_collision()
  end

		update_dynamics()
		check_dynamic_collisions()
		add_desert_if_missing()
  clean_up_dynamics()

  if (player.life <= 0) then
   if (not(debug_testing)) then
    end_game()
   end
  end

  if (boss.state == "dead") then
   end_game()
  end

  advance_game_level()

 elseif (gamestate == "end") then
		if (totalframes % 10 == 0) then
			if (#platforms > 0 and boss.state != "dead") then
				local c = get_actor_center(platforms[ceil(rnd(#platforms))])
				gen_firework_particle(c.x,c.y)
			end
			for n=1,3 do
		  gen_star_particle(cx,40,7)
		 end
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
 if btnp(5) then
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

function advance_game_level()
 if (progress_event <= 0) then
  sfx(6)
  gamelevel += 1
  points = 0
  if (gamelevel == 2) then
   --starting second phase
   -- 3 hits to move on
   spawn_boss()
   progress_event = 3
  elseif (gamelevel == 3) then
   --starting thrid phase
   -- 3 hits to move on
   -- loop starts moving
   spin_start = totalframes
   progress_event = 3
  elseif (gamelevel == 4) then
   --starting fourth phase
   -- 3 hits to move on
   progress_event = 3
  elseif (gamelevel == 5) then
   set_boss_action("dying",3,80)
  end
 end
end

-->8
--draw

function _draw()
	cls()
	if (gamestate == "game") then
		rectfill(0,0,128,128,0)
		draw_background()
	 draw_particles()
		draw_actors()
		draw_player_health()
		draw_pickup_counter()

		if (gamelevel == 1) then
			print("press ⬅️ and ➡️",cx-28,cy-20,11)
			print("to side step",cx-22,cy-12,11)
			print("press ❎",cx-16,cy-4,11)
			print("to hop across",cx-26,cy+4,11)
		end

		if (debug_testing) then
	  print(boss.action,0,16)
	  print(#boss_queue,0,24)
			local c = get_actor_center(boss)
			print(boss.frames,0,112)
			print(boss.maxFrameCnt,0,120)
		 print("sCORE: "..tostring(points),0,5,10,11)
		end

 elseif (gamestate == "menu") then
  rectfill(0,0,128,128,0)
		draw_particles()
		draw_actors()
  print("pHASE gATE",42,35,11)
		print("press ❎ to start",30+10*cos(0.005*(totalframes-5)),100+5*sin(0.005*2*(totalframes-5)),1)
  print("press ❎ to start",30+10*cos(0.005*totalframes),100+5*sin(0.005*2*totalframes),6)

 elseif (gamestate == "end") then
		rectfill(0,0,128,128,0)
		draw_particles()
		draw_actors()
		if (boss.state == "dead") then
		 print("cONGRATS!",46,35,11)
			print("mission sucessful!",30,90,11)
	 else
			print("gAME oVER",45,35,11)
			print("the phasegate was destroyed!",10,90,11)
	 end
  print("press ❎ and 🅾️ to play again",9,100,11)
 end
end

function draw_actors()
 for a in all(actors) do
  if (a.state != "disabled") then
   spr(a.s,a.x,a.y,a.w,a.h,a.fh,a.fv)
  end
 end
end

function draw_background()
 for b in all(background_objects) do
		local sx = (b.s % 16) * 8
		local sy = flr(b.s / 16) * 8
		local d = distance_to_center(b.x,b.y) --fudge
  sspr(sx,sy,b.w*8,b.h*8,b.x,b.y,(d/30)*16,(d/30)*16)
 end
end

function draw_player_health()
	for i=1,player.life do
		spr(16,8*(16-i),0)
	end
end

function draw_pickup_counter()
	rectfill(1,1,2*life_get_pickup_cnt+3,6,13)
	for i=1,pickups do
		line(2*i,2,2*i,5,10)
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

function move_actor_center(actor,x,y)
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

function remove_platforms(n)
 --removes platforms
 for i=1,n do
  local p = platforms[ceil(rnd(#platforms))]
  del(platforms,p)
		del(actors,p)
 end
 for i=1,#platforms do
  platforms[i].state = "seeking"
  set_actor_frames(platforms[i],100)
 end
end

function update_all_platforms()
	if (gamestate == "menu") then
		if (totalframes % 180 == 0) then add_platforms(1) end
		place_platforms_ellispe(cx,40,
			50+5*slow_start_sin(0.0035*(totalframes-spin_start),1),
			20+5*slow_start_sin(0.0035*(totalframes-spin_start),1),
			0.005*totalframes)
	elseif (gamestate == "end") then
		if (totalframes % 30 == 0 and boss.state != "dead") then remove_platforms(1) end
		place_platforms_ellispe(cx,40,
			50*cos(0.005*totalframes),
			30*sin(0.005*totalframes),0.005*totalframes)
	else
		if (gamelevel == 1 or gamelevel == 2) then
	  place_platforms_circle(cx,cy,55,1.0)
	 else
	  place_platforms_circle(cx,cy,
	   55+5*slow_start_sin(0.0035*(totalframes-spin_start),1),
	   slow_start_sin(0.0005*(totalframes-spin_start),1))
	 end
	end

 animate_all_platforms()

	if (gamestate == "menu") then
		rotate_all_platform_spr(cx,40)
	else
		rotate_all_platform_spr(cx,cy)
	end
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
 move_actor_center(platform,platform.targetx,platform.targety)
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

function place_platforms_ellispe(x,y,r1,r2,a)
 for n=1,#platforms do
  platforms[n].targetx = r1*cos(((n-1)/#platforms)+a) + x
  platforms[n].targety = r2*sin(((n-1)/#platforms)+a) + y
 end
end

function rotate_all_platform_spr(x,y)
 for i=1,#platforms do
  local p = platforms[i]
  local u = rotate_platform_spr(p.x,p.y,x,y,
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
		inc_pickups(1)
  if (gamelevel == 1) then
   progress_event -= 1
   if (progress_event > 0) then
    add_platforms(1)
   end
  end
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

function inc_pickups(x)
	pickups += x
	while (pickups >= life_get_pickup_cnt) do
	 pickups -= life_get_pickup_cnt
		player.life += 1
		-- needs a sound effect
 end
end

-->8
--dynamics

function make_fireball(x,y)
	d = make_dynamic(17,x,y,1,1)
	move_actor_center(d,x,y)
	return d
end

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
--background_objects
function update_background_objects()
	for p in all(background_objects) do
  p.x += p.xvel
  p.y += p.yvel
		p.xvel *= p.accel
		p.yvel *= p.accel
 end
end

function gen_planet()
	local l = ceil(rnd(4))
	if (l == 1) then l = 76
 elseif (l == 2) then l = 108
 elseif (l == 3) then l = 78
 elseif (l == 4) then l = 110 end
	planet = make_background_object(cx,cy,l,2,2)
	apply_angle_mag_dynamic(planet,rnd(1),0.1)
	planet.accel = 1.01
end

-->8
--particles

function update_particles()
 --move all particles and advance frames
 for p in all(particles) do
  p.x += p.xvel
  p.y += p.yvel
		p.xvel *= p.accel
		p.yvel *= p.accel
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

function gen_star_particle(x,y,c)
 p = make_particle(x,y,c)
 apply_angle_mag_dynamic(p,rnd(1),0.2)
 p.frames = 200
	p.accel = 1.01
end

-->8
--boss

function spawn_boss()
 set_boss_action("spawning",20,4)
end

function update_boss()
 if (boss.state == "disabled") then return end
 if (boss.action == "dying") then
  run_boss_death()
 elseif (boss.action == "spawning") then
  run_boss_spawn()
 elseif (boss.action == "floating") then
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
	elseif (boss.action == "static fire") then
  run_boss_static_fire()
 else
  sfx(0)
  retrieve_next_action()
 end
end

function run_boss_death()
 --boss flashes in and out every frame
 if (on_cycle_start()) then
  boss.cachex = boss.x
  boss.cachey = boss.y
 end
 if (move_to_next_frame()) then
  boss.s = 42
  boss.x += 2*cos(boss.frames/boss.maxFrameCnt)
  local c = get_actor_center(boss)
  if (totalframes % 8 == 0) then
   gen_firework_particle(c.x,c.y)
   sfx(0)
  end
 else
  if (move_to_next_cycle()) then
   boss.x = boss.cachex
   boss.y = boss.cachey
  else
   boss.state = "dead"
  end
 end
end

function run_boss_spawn()
 --boss flashes in and out every frame
 if (move_to_next_frame()) then
  if (boss.frames % boss.maxFrameCnt < (boss.maxFrameCnt/2)) then
   boss.s = 14
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

function run_boss_float()
 --boss floats in a figure eight each cycle
 if (on_cycle_start()) then
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
 if (on_cycle_start()) then
  boss.cachex = boss.x
  boss.cachey = boss.y
 end
 if (move_to_next_frame()) then
  boss.s = 46
  boss.x += cos(boss.frames/boss.maxFrameCnt)
 else
  if (move_to_next_cycle()) then
   local c = get_actor_center(boss)
   apply_angle_mag_dynamic(make_fireball(c.x,c.y),rnd(1),0.4)
   boss.x = boss.cachex
   boss.y = boss.cachey
  else
   retrieve_next_action()
  end
 end
end

function queue_boss_charging(isImediate,frames,cycles,chargeradius)
	local param = {}
	if (chargeradius != nil) then param.chargeradius = chargeradius end

	if (isImediate == true) then
		add_boss_queue("charging",frames,cycles,param,1);
	else
		add_boss_queue("charging",frames,cycles,param);
	end
end

function run_boss_charging()
 --boss charges around in short bursts
	if (boss.chargeradius == nil) then
		error("boss charge radius is not defined")
	end
 if (on_cycle_start()) then
  boss.cachex = boss.x + boss.chargeradius*cos(rnd())
  boss.cachey = boss.y + boss.chargeradius*sin(rnd())
 end
 if (move_to_next_frame()) then
  boss.s = 46
  move_actor_dash_pause(boss, boss.cachex, boss.cachey,
			boss.frames, boss.maxFrameCnt, false)
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_dash_rnd_platform()
 --boss goes to a rnd platform each cycle
 if (on_cycle_start()) then
  local index = ceil(rnd(#platforms))
  local t = get_platform_coords(index)
		boss.platform = index
  boss.targetx = t.x
  boss.targety = t.y
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

function queue_boss_dash_nxt_platform(isImediate,frames,cycles,direction)
	local param = {}
	if (direction != nil) then param.direction = direction end

	if (isImediate == true) then
		add_boss_queue("dash to next platform",frames,cycles,param,1);
	else
		add_boss_queue("dash to next platform",frames,cycles,param);
	end
end

function run_boss_dash_nxt_platform()
 --boss goes to the next nearest platform, then in consectutive order for each cycle
	if (boss.direction == nil) then
		error("boss direction is not defined")
	end
	if (on_cycle_start()) then
		if (on_first_cycle()) then
			--locate closest platform
		 local c = get_actor_center(boss)
		 boss.platform = find_closest_platform_index(c.x, c.y)
	 end
		--set target to next platform
  boss.platform = ((boss.platform - 1 + boss.direction) % #platforms) + 1
  local t = get_platform_coords(boss.platform)
  boss.targetx = t.x
  boss.targety = t.y
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
 if (on_cycle_start()) then
  local c = get_actor_center(boss)
  boss.radius = distance_to_center(c.x,c.y)
  boss.angle = atan2(c.x-cx,c.y-cy)
 end
 if (move_to_next_frame()) then
  boss.s = 46
  move_actor_center(boss,
   cx + boss.radius*cos(boss.angle + (1 - (boss.frames / boss.maxFrameCnt))),
   cy + boss.radius*sin(boss.angle + (1 - (boss.frames / boss.maxFrameCnt)))
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
 if (move_to_next_frame()) then
  boss.s = 14
  move_actor_dash_pause(boss,cx,cy,boss.frames,boss.maxFrameCnt,true)
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function run_boss_panting()
 --boss floats in a weak state each cycle
 if (on_cycle_start()) then
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

function queue_boss_hint_laser(isImediate,frames,cycles,angle)
	local param = {}
	if (angle != nil) then param.angle = angle end

	if (isImediate == true) then
		add_boss_queue("hint laser",frames,cycles,param,1);
	else
		add_boss_queue("hint laser",frames,cycles,param);
	end
end

function run_boss_hint_laser()
 --boss generates particles in a direction each cycle
	if (boss.angle == nil) then error("boss angle not definded") end
 if (on_cycle_start()) then
  boss.cachex = boss.x
  boss.cachey = boss.y
 end
 if (move_to_next_frame()) then
  boss.s = 46
  boss.x += cos(boss.frames/boss.maxFrameCnt)
  local c = get_actor_center(boss)
  gen_hint_laser(c.x,c.y,boss.angle,10)
 else
		boss.x = boss.cachex
		boss.y = boss.cachey
  if (not(move_to_next_cycle())) then
   retrieve_next_action()
  end
 end
end

function queue_boss_fire_laser(isImediate,frames,cycles,a,sweep,direction)
	local param = {}
	if (a != nil) then param.angle = a end
	if (sweep != nil) then param.sweep = sweep end
	if (direction != nil) then param.direction = direction end

	if (isImediate == true) then
		add_boss_queue("fire laser",frames,cycles,param,1);
	else
		add_boss_queue("fire laser",frames,cycles,param);
	end
end

function run_boss_fire_laser()
 --boss shakes and trys to apply damage using the angle from hint laser each cycle
	if (boss.angle == nil) then error("boss angle not definded") end
	if (boss.direction == nil) then error("boss direction not definded") end
	if (boss.sweep == nil) then error("boss sweep not definded") end
 if (move_to_next_frame()) then
  boss.s = 42
  sfx(5)
  local angle = boss.angle + boss.sweep*boss.direction*(1-boss.frames/boss.maxFrameCnt)
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

function queue_boss_static_firing_plattern(isImediate,frames,cycles,checkerFireEnabled,checkerFireQuantity)
	local param = {}
	if (checkerFireEnabled != nil) then param.checkerFireEnabled = checkerFireEnabled end
	if (checkerFireQuantity != nil) then param.checkerFireQuantity = checkerFireQuantity end

	if (isImediate == true) then
		add_boss_queue("static fire",frames,cycles,param,1);
	else
		add_boss_queue("static fire",frames,cycles,param);
	end
end

function run_boss_static_fire()
 --boss fires dynamics in determined patterns
	if (boss.checkerFireEnabled == nil) then error("boss checkerFireEnabled not definded") end
	if (boss.checkerFireQuantity == nil) then error("boss checkerFireQuantity not definded") end

 if (move_to_next_frame()) then
  if (true) then
			if (boss.frames == boss.maxFrameCnt - 1) then
				sfx(0)
				for i=1,boss.checkerFireQuantity do
					-- spawn star
					local c = get_actor_center(boss)
		   apply_angle_mag_dynamic(make_fireball(c.x,c.y),(i/boss.checkerFireQuantity),0.4)
				end
		 end
			if (boss.frames == flr(boss.maxFrameCnt/2)) then
				-- spawn same star shifted in phase
				for i=1,boss.checkerFireQuantity do
					local c = get_actor_center(boss)
		   apply_angle_mag_dynamic(make_fireball(c.x,c.y),(i/boss.checkerFireQuantity)+(1/(2*boss.checkerFireQuantity)),0.4)
				end
		 end
		end
 else
  if (move_to_next_cycle()) then
  else
   retrieve_next_action()
  end
 end
end

function on_cycle_start()
 return (boss.frames == boss.maxFrameCnt)
end

function on_first_cycle()
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

 local c = get_actor_center(boss)
 if (distance_to_center(c.x, c.y) > 64) then
  set_boss_action("go home",40,1)
  return
 end

	if (#boss_queue == 0) then
		if (gamelevel == 2) then getStageOnePhases()
		elseif (gamelevel == 3) then getStageTwoPhases()
		elseif (gamelevel == 4) then getStageThreePhases()
		end
	end

 if (not(queued_boss_action())) then
		getRandomAction()
	end

end

function getStageOnePhases()
	local r = ceil(rnd(60))
	if (r < 20) then
		wave1Laser()
	elseif (r < 40) then
		add_boss_queue("go home",80,1)
		queue_boss_static_firing_plattern(false,100,4,true,5)
	elseif (r < 60) then
		add_boss_queue("dash to platform",80,1)
		queue_boss_dash_nxt_platform(false,8,#platforms,randDirection())
	end
	if (points > 15) then
		add_boss_queue("panting",160,2)
	elseif (points > 6) then
		if (ceil(rnd(10)) == 1) then
			add_boss_queue("panting",160,2)
		else
			add_boss_queue("floating",120,2)
		end
	end
end

function getStageTwoPhases()
	local r = ceil(rnd(80))
	if (r < 20) then
		wave2Laser()
	elseif (r < 40) then
		add_boss_queue("mad",3,15)
		queue_boss_charging(false,20,10,30)
		add_boss_queue("mad",3,15)
	elseif (r < 60) then
		local l = randDirection()
		add_boss_queue("dash to platform",60,1)
		queue_boss_dash_nxt_platform(false,6,#platforms,l)
		queue_boss_dash_nxt_platform(false,6,#platforms,-l)
	elseif (r < 80) then
		add_boss_queue("ring run",120,1)
		add_boss_queue("dash to platform",60,1)
		add_boss_queue("ring run",120,1)
	end
	if (points > 15) then
		add_boss_queue("panting",160,2)
	elseif (points > 6) then
		if (ceil(rnd(10)) == 1) then
			add_boss_queue("panting",160,2)
		else
			add_boss_queue("floating",120,2)
		end
	end
end

function getStageThreePhases()
	local r = ceil(rnd(80))
	if (r < 20) then
		wave3Laser()
	elseif (r < 40) then
		add_boss_queue("mad",3,20,1)
		add_boss_queue("charging",20,15,2)
		add_boss_queue("mad",3,20,3)
	elseif (r < 60) then
		add_boss_queue("dash to platform",40,1,1)
		add_boss_queue("dash to next platform",4,#platforms,2)
	elseif (r < 80) then
		add_boss_queue("ring run",80,1,1)
		add_boss_queue("dash to platform",40,1,2)
		add_boss_queue("ring run",80,1,3)
	end
	if (points > 15) then
		add_boss_queue("panting",160,2,0)
	elseif (points > 6) then
		if (ceil(rnd(10)) == 1) then
			add_boss_queue("panting",160,2,0)
		else
			add_boss_queue("floating",120,2,0)
		end
	end
end

function getRandomAction()
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

function set_boss_action(action, maxFrameCnt, cycles)
 boss.action = action
 boss.maxFrameCnt = maxFrameCnt
 boss.frames = maxFrameCnt
 boss.cycles = cycles
 boss.maxCycleCnt = cycles

	if (boss.action == "panting") then
		boss.state = "weak"
	elseif (boss.action == "hit"
						or boss.action == "dying"
					 or boss.action == "spawning") then
		boss.state = "invincible"
	else
		boss.state = "active"
	end
end

function queued_boss_action()
 if (#boss_queue > 0) then
  set_boss_action(boss_queue[1].action,
   boss_queue[1].maxFrameCnt,
   boss_queue[1].cycles)

		if (boss_queue[1].param != nil) then
			if(boss_queue[1].param.angle != nil) then boss.angle = boss_queue[1].param.angle end
			if(boss_queue[1].param.chargeradius != nil) then boss.chargeradius = boss_queue[1].param.chargeradius end
			if(boss_queue[1].param.direction != nil) then boss.direction = boss_queue[1].param.direction end
			if(boss_queue[1].param.sweep != nil) then boss.sweep = boss_queue[1].param.sweep end
			if(boss_queue[1].param.checkerFireEnabled != nil) then boss.checkerFireEnabled = boss_queue[1].param.checkerFireEnabled end
			if(boss_queue[1].param.checkerFireQuantity != nil) then boss.checkerFireQuantity = boss_queue[1].param.checkerFireQuantity end
	 end

  del(boss_queue, boss_queue[1])
  return true
 end
 return false
end

function add_boss_queue(action, maxFrameCnt, cycles, param, index)
 bq = { action = action,
        maxFrameCnt = maxFrameCnt,
        cycles = cycles,
							 param = param }
 if (index == nil) then
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
   damage_boss(1)
  elseif (boss.state == "active") then
   damage_player(1)
  end
 end
end

function damage_boss(d)
 sfx(4)
 boss.life -= d
 if (gamelevel > 1) then
  progress_event -= 1
 end
end

-->8
--boss attack

function wave1Laser()
	for i=1,3 do
		local ang = rnd(1)
		queue_boss_hint_laser(false,3,10,ang)
		queue_boss_fire_laser(false,50,1,ang,0.1+0.05*(rnd(1)),randDirection())
	end
end

function wave2Laser()
	for i=1,3 do
		local ang = rnd(1)
		queue_boss_hint_laser(false,3,10,ang)
		queue_boss_fire_laser(false,150,1,ang,0.1+0.3*(rnd(1)),randDirection())
	end
end

function wave3Laser()
	add_boss_queue("go home",50,1)
	for i=1,5 do
		local ang = rnd(1)
		queue_boss_hint_laser(false,5,10,ang)
		queue_boss_fire_laser(false,30,1,ang,0.1,randDirection())
	end
	queue_boss_hint_laser(false,5,40,ang)
	queue_boss_fire_laser(false,400,1,ang,2,randDirection())
end


-->8
--helper functions

function error(message)
	assert(false, message)
end

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

function slow_start_sin(x,d)
 return sin(x) * (1-(2.71)^(-x*d))
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
00000000ddddddddd600000000000d0022222222260000000000020000000000000000000000000000000000000000000000000dd00000000000000dd0000000
00000000655d5556d55600000000ddd06aa2aaa62aa60000000022200000000000000000000000000000000000000000000000deed000000000000daad000000
0000000005d55d50d5d55600000dd6500a2aa2a02a2aa600000226a00000000000000000000000000000000000000000000000deed000000000000daad000000
000000000655d560d55d555600dd556006aa2a602aa2aaa60022aa60000000000000000000000000000000000000000000000d1ee1d0000000000daaaad00000
00000000005d5500dd55d5560dd5d5d000a2aa0022aa2aa6022a2a200000000000000000000000000000000000000000ddddd19ee91dddddddddd99aa99ddddd
0000000000655600d5d55600dd65d5d6006aa6002a2aa600226a2a260000000000000000000000000000000000000000deee199ee991eeeddaaaa92aa29aaaad
0000000000055000d55600000d5655d5000aa0002aa6000002a6aa2a00000000000000000000000000000000000000000deee92ee29eeed00daaa92aa29aaad0
0000000000066000d6000000000006d500066000260000000000062a000000000000000000000000000000000000000000dee92ee29eed0000daa92aa29aad00
0660660000000000aaaaaaaa999999998888888800000000000000000000000000000000000000000000000000000000000deeeeeeeed000000daaaaaaaad000
6886886000a99a00a000000a900000098000000800000000000000000000000000000000000000000000000000000000000dee2222eed000000da2aaaaaad000
688888600a9889a0a000000a90000009800000080000000000000000000000000000000000000000000000000000000000deeeeeeeeeed0000daaa2222aaad00
6888886009888890a000000a90000009800000080000000000000000000000000000000000000000000000000000000000deeeeeeeeeed0000daaaaaaaaaad00
6888886009888890a000000a9000000980000008000000000000000000000000000000000000000000000000000000000deeeeeddeeeeed00daaaaaddaaaaad0
068886000a9889a0a000000a9000000980000008000000000000000000000000000000000000000000000000000000000deeedd00ddeeed00daaadd00ddaaad0
0068600000a99a00a000000a900000098000000800000000000000000000000000000000000000000000000000000000deedd000000ddeeddaadd000000ddaad
0006000000000000aaaaaaaa999999998888888800000000000000000000000000000000000000000000000000000000ddd0000000000dddddd0000000000ddd
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700000000009aaaaa00000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777cc77770000009999998888000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003777733cccc3000099aaaaaaaa8800
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3333333ccc333009a888889999aa90
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c333333ccc333c00aa99ffff99999f0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc33333ccc33ccc99ffff999ffff88f
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc3cc3ccc3cc339ff999aaa9999998
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc33cccccc3333f999aaa9aaaaaa99
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc333cccc33339888a999999999aa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333cc33338999999998888999
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333ccc3339999a99888888899
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc33333cccc3009aaa99888888ff0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc333ccccc30099fffffffffff90
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc33cccccc000098899998888900
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c777ccc7770000009988aaaaaa000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000099889900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999000000000026666600000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449944499000000222222dddd000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000094449944444900002266666666dd00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000494444994449990026ddddd22226620
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000049999999999994006622eeee22222e0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999994499944422eeee222eeeedde
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099449449444944442ee222666222222d
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009944994444449944e222666266666622
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000049444999444494492ddd622222222266
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004999999999449999d22222222dddd222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044999999994999992222622ddddddd22
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444999999944900266622ddddddee0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444449999994490022eeeeeeeeeee20
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044449944994400002dd2222dddd200
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000499944499900000022dd666666000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999000000000022dd2200000
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
00110000000001825022250272502a2502925026250222501c25019250152501125012250162501c2501e25000000000000000000000000000000000000000000000000000000000000000000000000000000000
