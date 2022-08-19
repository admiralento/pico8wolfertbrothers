pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

platforms = 20
starting_platform = 1

function _init()
 cls()
 
 for i=1,(platforms - 1) do
  loc = i
  y = 15
  while i > 5 do
  i -= 5
  y += 30
  end
  make_actor(1,i*20,y,loc)
 end
 
 x = actor_length() + 1
 y = 15
 while (x > 5) do
  x -= 5
  y += 30
 end
 make_actor(2,x*20,y,platforms)
 
 make_actor(33,actor[starting_platform].x,actor[starting_platform].y,starting_platform)
end


function _update()
move_player()
end


function _draw()
cls()
draw_actors(actor)
print(actor[21].loc)
end
-->8

actor = {}

function make_actor(act_type,x,y,loc)
	a={
	 x = x,
	 y = y,
		act_type = act_type,
		
		--for the player
		loc = loc
	}
	
	add(actor,a)
	
	return a
end


function actor_length()
 actor_length = 0
 for i in all(actor) do
  actor_length += 1
 end
 return actor_length
end


function draw_actors(actor)
 for i in all(actor) do
  spr(i.act_type,i.x,i.y)
 end
end


function move_player()
	for player in all(actor) do
	 if (player.act_type == 33) do
	  if btn(⬅️,true) then player.loc -= 1 end
	  if btn(➡️,true) then player.loc += 1 end
	  if (player.loc > platforms) then player.loc = 1 end
	  if (player.loc < 1) then player.loc = 20 end
	  for platform in all(actor) do
	   if (platform.loc == player.loc) do
	    player.x = platform.x
	    player.y = platform.y
	   end
	  end
	 end
	end
end
__gfx__
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888889999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000