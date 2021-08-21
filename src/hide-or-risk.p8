pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- hide or risk
-- by peanutsfly

-- music: dimensional gate by @gruber_music

-- global var --

gamestate=1
endscore=0
sfx_effects=true
display_credits=false
t=0

-- help for non pico-8 users
info = "press x/c"

-- global const --

function initialize_const()
	states={
		{
			initialize_menu,
			update_menu,
			draw_menu
		},
		{
			initialize_game,
			update_game,
			draw_game
		},
		{
			initialize_score,
			update_score,
			draw_score
		}
	}
end

-- game loop --

function _init()
	t=0
	cartdata("hide-or-risk")
	initialize_const()
	state=states[gamestate]
	state[1]()	
end

function _update60()
	t+=1
	state[2]()
end

function _draw()
	cls(0)
	state[3]()
 --print("memory: "..(stat(0)/2048*100).."%",5,20,0)
 --print("cpu: "..stat(1),5,28,0)
 --print("fps: "..stat(7),5,36,0)
end

function reload()
	state=states[gamestate]
	state[1]()
end

-- debug --

function debug()
	print("state: "..gamestate)
end
-->8
-- menu

-- init --

function initialize_menu()
	music(-1,2400)
	selection={
		{"start",start_game},
		{"credits",show_credits}
	}
	buttons={}
	local plcy=9.75
	for s in all(selection) do
		local b=create_button(s[1],plcy,s[2])
		add(buttons,b)
		plcy+=1
	end
	btn_select=1
	buttons[btn_select].selected=true
end

-- update --
	
function update_menu()
	update_selection()
	for b in all(buttons) do
		b:update()
	end
end

function update_selection()
	if btnp(3) then
		simplesound(60)
		btn_select+=1
		if btn_select<=#selection then
			buttons[btn_select-1].selected=false
			buttons[btn_select].selected=true
		else
			btn_select=1
			buttons[#selection].selected=false
			buttons[btn_select].selected=true
		end	
	elseif btnp(2) then
		simplesound(60)
		btn_select-=1
		if btn_select>=1 then
			buttons[btn_select+1].selected=false
			buttons[btn_select].selected=true
		else
			btn_select=#selection
			buttons[1].selected=false
			buttons[btn_select].selected=true
		end	
	end
end

function start_game()
	gamestate=2
	reload()
end

function show_credits()
	if display_credits then
		display_credits=false
	else
		display_credits=true
	end
end

-- draw --

function draw_menu()
	palt(0,false)
	map(0,16,0,0,16,16)
	map(16,16,0,0,16,16)
	palt()
	cinematic_view(0,0)
	for b in all(buttons) do
		b:draw()
	end
	print(info,hcenter(info),68,1)
	draw_credits()
end

function draw_credits()
	if display_credits then
		creator="made by peanutsfly"
		credits="music by @gruber_music"
		print(creator,hcenter(creator),119,6)
		print(credits,hcenter(credits),4,6)
	end	
end
-->8
-- game

-- init --

function initialize_game()
	music(13,2400)
	game_over_sfx_played=false
	instr_x,hill_x,cloud_x=0,0,0
	player=create_player(4,10)
	blocks={
		create_block(0,10),
		create_block(8,10),
		create_block(12,10)
	}
	catchers={}
	score=0
	colors={7,11,8}
	score_color=colors[1]
	width=127
	content_timer=0
	content_pos={
		16,20,24,28
	}
	caught_timer=120
end

-- update --
	
function update_game()
	if not player.caught then
		update_map()
		player:update()
		for b in all(blocks) do
			b:update()
		end
		for c in all(catchers) do
			c:update()
		end
		update_gamescore()
		add_blocks()
		add_catchers()
	else
		game_over_sfx()
		caught_timer-=1
		if caught_timer<=0 then
			endscore=flr(score/10)*10
			gamestate=3
			reload()
		end
	end	
end

function add_blocks()
	if player==nil then
		return
	end
	if player.dir==1 and player.x==player.ox then
		content_timer-=1
		local save_n1=flr(rnd(4))+1
		local save_n2=flr(rnd(4))+1
		if content_timer<=0 then
			for n=1,4 do
				if flr(rnd(2))==0 or (n==save_n1 or n==save_n2) then
					local b=create_block(content_pos[n],10)
					add(blocks,b)
				end
			end
			content_timer=width
		end
	end	
end

function add_catchers()
	if t%(300-20*flr(score/2000))==0 then
		local c=create_catcher(28,12)
		add(catchers,c)
	end
end

function update_gamescore()
	if player.dir==1 and player.x==player.ox then
		score+=2
		score_color=colors[2]
	elseif player.dir==-1 and score>=5 and player.x>-1 then
		score-=4
		score_color=colors[3]
	else
		score_color=colors[1]	
	end
end

function update_map()
	if player==nil then
		return
	end
	if player.dir==1 and player.x==player.ox then
		instr_x-=1
		hill_x-=1
		cloud_x-=2
	else
		cloud_x-=1
	end
	if hill_x<-127 then
		hill_x=0
	end
	if cloud_x<-127 then
		cloud_x=0
	end	
end

-- draw --

function draw_game()
	draw_map()
	draw_hud()
	if instr_x>=-383 then
		draw_instructions()
	end	
	player:draw()
	for b in all(blocks) do
		b:draw()
	end
	for c in all(catchers) do
		c:draw()
	end
	--draw_shapes()
end

function draw_map()
	palt(0,false)
	map(0,0,hill_x,0,16,16)
	map(0,0,hill_x+128,0,16,16)
	map(16,0,cloud_x,0,16,16)
	map(16,0,cloud_x+128,0,16,16)
	palt()
end

function draw_hud()
	cinematic_view(0,0)
	hud_score()
	if player.dir==1 then
		hud_status(1)
	elseif 	player.dir==-1 then
		hud_status(2)
	elseif player.dir==0 then
		hud_hidden()
	end	
end

function draw_instructions()
	instr1="press l/r to move"
	instr2="hide. don't get caught"
	instr3="take risk to score"

	rectfill2(instr_x+hcenter(instr1)-4,34,4*#instr1+6,12,0)
	rectfill2(instr_x+hcenter(instr1)-3,35,4*#instr1+4,10,6)
	rectfill2(instr_x+hcenter(instr1)-2,36,4*#instr1+2,8,5)
	print(instr1,instr_x+hcenter(instr1),38,7)

	rectfill2(instr_x+hcenter(instr2)-4+127,34,4*#instr2+6,12,0)
	rectfill2(instr_x+hcenter(instr2)-3+127,35,4*#instr2+4,10,6)
	rectfill2(instr_x+hcenter(instr2)-2+127,36,4*#instr2+2,8,5)
	print(instr2,instr_x+hcenter(instr2)+127,38,7)

	rectfill2(instr_x+hcenter(instr3)-4+255,34,4*#instr3+6,12,0)
	rectfill2(instr_x+hcenter(instr3)-3+255,35,4*#instr3+4,10,6)
	rectfill2(instr_x+hcenter(instr3)-2+255,36,4*#instr3+2,8,5)
	print(instr3,instr_x+hcenter(instr3)+255,38,7)
end

function hud_status(num)
	local messages={
		"braveness +10",
		"fear -20"
	}
	local text=messages[num]
	print(text,hcenter(text),119,colors[num+1])
end

function hud_score()
	local score_value=flr(score/10)*10
	local score_label="score: "..tostr(score_value)
	print(score_label,hcenter(score_label),4,score_color)
end

function hud_hidden()
	local text
	if player.hidden then
		text="hidden"
	else
		text="unhidden"
	end
	print(text,hcenter(text),119,6)
end

-- debug --

function draw_shapes()
	rect2(player.x+player.osx,player.y,player.shape[1],player.shape[2],1)
	for b in all(blocks) do
		rect2(b.x+b.osx,b.y,b.shape[1],b.shape[2],1)
	end
	for c in all(catchers) do
		rect2(c.x+c.osx,c.y,c.shape[1],c.shape[2],1)
		rect2(c.x+c.osx-c.view[1],c.y-c.view[2],c.view[1],c.view[2],1)
	end
end

-->8
-- score

-- init --

function initialize_score()
	selection={
		{"retry",start_game},
		{"menu",return_to_menu}		
	}
	buttons={}
	local plcy=10.5
	for s in all(selection) do
		local b=create_button(s[1],plcy,s[2])
		add(buttons,b)
		plcy+=1
	end
	btn_select=1
	buttons[btn_select].selected=true
	score_evaluation()
end

function score_evaluation()
	highscore=dget(0)
	if endscore>highscore then
		highscore=endscore
		dset(0,highscore)
	end
end

-- update --
	
function update_score()
	update_selection()
	for b in all(buttons) do
		b:update()
	end
end

function return_to_menu()
	gamestate=1
	reload()
end

-- draw --

function draw_score()
	palt(0,false)
	map(0,16,0,0,16,16)
	palt()
	cinematic_view(0,0)
	draw_scores()
	for b in all(buttons) do
		b:draw()
	end
	print(info,hcenter(info),74,1)
	draw_credits()
end

function draw_scores()
	local hlabel="highscore: "..highscore
	local slabel="score: "..endscore
	local	textx=hcenter(hlabel)
	local textw=4*#hlabel
	rectfill2(8,40,111,28,0)
	rectfill2(9,41,109,26,6)
	rectfill2(10,42,107,24,5)
	--rectfill2(0,42,127,24,1)
	print(hlabel,hcenter(hlabel),46,7)
	print(slabel,hcenter(slabel),58,7)
end
-->8
-- classes

-- player --

function create_player(celx,cely)
	local p={}
	
	--variables
	p.x,p.y=celx*8,cely*8
	p.sprites={{64,65},{80,81}}
	p.dir=0
	p.ox=p.x
	p.shape={9,16}
	p.osx=3
	p.hidden=false
	p.caught=false
	
	--functions
	function p:update()
		self.dir=get_direction()
		if (self.dir==-1 and self.x>=0) or (self.dir==1 and self.x<self.ox) then
			self.x+=self.dir
		end
		if self.dir!=0 then
			sound(63,self)
		else
			self:set_time(0)	
		end
		self:check_blocks()
	end
	
	function p:draw()
		local y=self.y
		if self.dir!=0 then
			y=walk_animation(self.y)
		end
		local sflip=false
		if self.dir==-1 then
			sflip=true
		end
		draw_entity(self.sprites,self.x,y,sflip)
	end
	
	function p:check_blocks()
		for b in all(blocks) do
			if	is_colliding(self.x+p.osx,self.y,self.shape[1],self.shape[2],b.x+b.osx,b.y,b.shape[1],b.shape[2]) then
				self.hidden=true
				return
			end
		end 
		self.hidden=false
	end
	
	-- features
	p=initialize_timer(24,p)
	
	return p
end

-- block --

function create_block(celx,cely)
	local b={}
	
	--variables
	b.x,b.y=celx*8,cely*8
	b.sprites={
		{128,132,132,131},
		{129,133,133,130},
		{129,133,133,130}
	}
	b.shape={13,24}
	b.osx=9
	
	--functions
	function b:update()
		if player.dir==1 and player.x==player.ox then
			self.x-=1
		end
		if self.x<-32 then
			del(blocks,self)
		end
	end
	
	function b:draw()
		draw_entity(self.sprites,self.x,self.y,false)
	end
	
	return b
end

-- catcher --

function create_catcher(celx,cely)
	local c={}
	
	local all_sprites={}
	add(all_sprites,{{66,67},{82,83}})
	add(all_sprites,{{68,69},{84,85}})
	add(all_sprites,{{70,71},{86,87}})
	add(all_sprites,{{72,73},{88,89}})
	local n=flr(rnd(#all_sprites))+1
	
	--variables
	c.x,c.y=celx*8,cely*8
	c.sprites=all_sprites[n]
	c.shape={9,16}
	c.osx=3
	c.view={8,16}
	
	--functions
	function c:update()
		sound(62,self)
		if player.dir==1 and player.x==player.ox then
			self.x-=2
		else
			self.x-=1
		end
		if self.x<-32 then
			del(catchers,self)
		end
		self:search()
	end
	
	function c:draw()
		local y=walk_animation(self.y)
		draw_entity(self.sprites,self.x,y,false)
	end
	
	function c:search()
		if is_colliding(self.x+self.osx-self.view[1],self.y-self.view[2],self.view[1],self.view[2],player.x+player.osx,player.y,player.shape[1],player.shape[2]) then
			if not player.hidden then
				player.caught=true
			end
		end
	end	
	
	-- features
	c=initialize_timer(24,c)
		
	return c
end

-- buttons --

function create_button(label,cely,ref)
	b={}
	
	--variables
	b.x=hcenter(label)
	b.y=cely*8
	b.label=label
	b.ref=ref
	b.selected=false
	
	
	--functions
	function b:update()
		if (btnp(5) or btnp(4)) and self.selected then
			simplesound(59)
			self.ref()
		end
	end
	
	function b:draw()
		local c=0
		local text=self.label
		local x=self.x
		if self.selected then
			c=7
		end
		print(text,self.x,self.y,c)
	end
	
	function b:delete()
		del(buttons,self)
	end
	
	return b
end
-->8
-- math

function is_colliding(x1,y1,w1,h1,x2,y2,w2,h2)
	return x1<x2+w2 and x2<x1+w1 and y1<y2+h2 and y2<y1+h1
end

-- utilities

function int(boolean)
	if boolean then
		return 1
	else
		return 0
	end	
end

function draw_entity(sprites,x,y,sflip)
	local plc_y=0
	for column in all(sprites) do
		local plc_x=0
		local begin,finish,addition=1,#column,1
		if sflip then
			begin,finish,addition=#column,1,-1
		end
		for cel=begin,finish,addition do
			spr(column[cel],x+plc_x,y+plc_y,1,1,sflip)
			plc_x+=8
		end
		plc_y+=8
	end	
end

function get_direction()
	local l=int(btn(0))
	local r=int(btn(1))
	return -l+r
end

function walk_animation(y)
	y+=flr(t/12)%2
	return y
end

function cinematic_view(x,y)
	rectfill(x,y,x+127,y+12,0)
	rectfill(x,y+115,x+127,y+127,0)
end

function hcenter(text)
	return 64-#text*2
end

function rect2(x,y,w,h,c)
	rect(x,y,x+w,y+h,c)
end

function rectfill2(x,y,w,h,c)
	rectfill(x,y,x+w,y+h,c)
end

function sound(num,entity)
	if sfx_effects and entity.current_time!=nil then
		entity:countdown()
		if entity:is_countdown_done() then
			sfx(num)
			entity:reset_timer()
		end
	end	
end

function simplesound(num)
	if sfx_effects then
		sfx(num)
	end
end

function game_over_sfx()
	if sfx_effects then
		if not game_over_sfx_played then
			sfx(61)
			game_over_sfx_played=true
		end
	end
end

function initialize_timer(max_time,entity)
	entity.max_time=max_time
	entity.current_time=max_time
	
	function entity:countdown()
		self.current_time-=1
	end
	
	function entity:is_countdown_done()
		return self.current_time<=0
	end
	
	function entity:set_time(new_time)
		self.current_time=new_time
	end
	
	function entity:get_time()
		return self.current_time
	end
	
	function entity:reset_timer()
		self.current_time=self.max_time
	end
	
	return entity
end

__gfx__
00000000cccccccc5555555577777777555555556ccccccc777777766ccccccc555555500cccccc0ccccccc60555555505555555ccccccc66777777755555550
00000000cccccccc55555555777777770000000066cccccc5555777766cccccc5555555500cccc00cccccc665555555500555555cccccc667777555555555500
00700700cccccccc555555557777777766666666766ccccc55555555766ccccc55555555500cc005ccccc6675555555550055555ccccc6675555555555555005
00077000cccccccc5555555577777777666666667766cccc555555555500cccc5555555555000055cccc00555555555555005555cccc66775555555555550055
00077000cccccccc55555555777777776666666677766ccc5555555555500ccc5555555555500555ccc005555555555555500555ccc667775555555555500555
00700700cccccccc555555557777777777777777777766cc55555555555500cc5555555555550055cc0055555555555555550055cc6677775555555555005555
00000000cccccccc5555555577777777777777777777766c555555555555500c5555555555555005c00555555555555555555005c66777775555555550055555
00000000cccccccc5555555577777777777777777777776655555555555555005555555555555500005555555555555555555500667777775555555500555555
0cccccccccccccc00cccccc0ccccccc6cccccc666777777766cccccc7777777666cccccccccccc66777777776666666600000000000000000000000000000000
00cccccccccccc0000cccc00ccccccc6cccc6667777777777666cccc777777777666cccccccc6667777777777777777700000000000000000000000000000000
500cccccccccc005500cc005cccccc66ccc667777777777777766ccc7777777777766cccccc66777777777777777777700000000000000000000000000000000
5500cccccccc005555000055cccccc67cc66777777777777777766cc77777777777766cccc667777777777777777777700000000000000000000000000000000
55500cccccc0055555500555ccccc667c6677777777777777777766c777777777777766cc6677777777777777777777700000000000000000000000000000000
555500cccc00555555005555cccc6677c6777777777777777777776c777777777777776cc6777777777777777777777700000000000000000000000000000000
5555500cc005555550055555cc666777667777777777777777777766777777777777776666777777777777777777777700000000000000000000000000000000
55555500005555550055555566666666677777776666666677777776666666666666666666666666666666667777777700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044444444440000002222222222000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044444444444000022222222222000001111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044444fffff400002fffff22222000001111111111110000002222222200000000011111110000000000000000000000000000000000000000000000000000
00044444fffff000000fffff222220000002fffff222000000022222222200000000111111111000000000000000000000000000000000000000000000000000
0004444ffffff000000ffffff22220000000ffffff22000000022222222200000001111111111000000000000000000000000000000000000000000000000000
0004444ffffff000000ffffff22220000000ffffff2200000000ffffff2200000001111111111000000000000000000000000000000000000000000000000000
00044ffffffff000000ffffffff220000000ffffffff00000000ffffff2200000001ff11ff111000000000000000000000000000000000000000000000000000
00044ffffffff000000ffffffff220000000ffffffff00000000fffffff200000001ff11ff111000000000000000000000000000000000000000000000000000
0004444333333000000111111112200000001111111100000000ffffffff00000000fffffff11000000000000000000000000000000000000000000000000000
00044443333330000001111111122000000011111111000000001111111100000000ffffffff1000000000000000000000000000000000000000000000000000
00004433333330000001111111120000000011111111000000001111111100000000111111110000000000000000000000000000000000000000000000000000
00000333333330000001111111100000000011111111000000001111111100000000111111110000000000000000000000000000000000000000000000000000
00000333333330000001111111100000000011111111000000001111111100000000111111110000000000000000000000000000000000000000000000000000
00000333333330000001111111100000000011111111000000001111111100000000111111110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066000066677666000066000000666666667777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000666000066677666000066600000666666667777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006666000066677666000066660000666666667777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006666000066677666000066660000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006667000066677666000076660000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006667000066677666000076660000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006667000066677666000076660000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00006667000066677666000076660000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc6667776666cc7776667776cc7776666666ccccc7776667776cc7776667776ccccc7776667776ccccc7776666cc7776666666cc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc7776cccccccc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc7776cccccccc7776cc7776cc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776666ccccc7777776666ccccc7776ccccc7777777776cc7777776666cc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776cccccccc7777776cccccccc7776ccccc7777777776cc7777776ccccc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776cccccccc7777776cccccccc7776ccccc7777777776cc7777776ccccc
cc7776667776ccccc7776ccccc7776cc7776cc7776666cccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc6666667776cc7776667776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccccccccc7776cc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccccccccc7776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776666cc7776cc7776ccccc7776cc7776cc7777777776cc7777776666cc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776ccccc7776cc7776ccccc7776cc7776cc7777777776cc7777776ccccc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776ccccc7776cc7776ccccc7776cc7776cc7777777776cc7777776ccccc7776cc7776cc
cc6666cc6666cc6666666666cc6666666666cc6666666666ccccc6666666ccccc6666cc6666ccccc6666cc6666cc6666666666cc6666666ccccc6666cc6666cc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc677777777777777777777777777776ccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66777777777777777777777777777766cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc67777777777777777777777777777776cccccccccccccccccccccccc
cccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccc666777777777777777777777777777777666cccccccccccccccccccccc
cccccccccccccccccccccccccccc66677666cccccccccccccccccccccccccccccccc6667777777777777777777777777777777777666cccccccccccccccccccc
ccccccccccccccccccccccccccc6677777766cccccccccccccccccccccccccccccc667777777777777777777777777777777777777766ccccccccccccccccccc
cccccccccccccccccccccccccc667777777766cccccccccccccccccccccccccccc66777777777777777777777777777777777777777766cccccccccccccccccc
ccccccccccccccccccccccccc66777777777766cccccccccccccccccccccccccc6677777777777777777777777777777777777777777766ccccccccccccccccc
ccccccccccccccccccccccccc67777777777776cccccccccccccccccccccccccc6777777777777777777777777777777777777777777776ccccccccccccccccc
cccccccccccccccccccccccc6677777777777766cccccccccccccccccccccccc667777777777777777777777777777777777777777777766cccccccccccccccc
cccccccccccccccccccccccc6777777777777776cccccccccccccccccccccccc666666666666666666666666666666666666666666666666cccccccccccccccc
ccccccccccccccccccccccc6677777777777777666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccc677777777777777777666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc66777777777777777777766ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc677777777777777777777766cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc66777777777777777777777766ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc667777777777777777777777776ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccc666777777777777777777777777766cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc66666666666666666666666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777776ccccc7777777776cccccccc7777776cc7777777776ccccc7777777776cc7777777776ccccc7777776cc7776cc7776cc
cc7776cc7776cc6667776666cc7776667776cc7776666666ccccc7776667776cc7776667776ccccc7776667776ccccc7776666cc7776666666cc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc7776cccccccc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc7776cccccccc7776cc7776cc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776666ccccc7777776666ccccc7776ccccc7777777776cc7777776666cc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776cccccccc7777776cccccccc7776ccccc7777777776cc7777776ccccc
cc7777777776ccccc7776ccccc7776cc7776cc7777776cccccccc7776cc7776cc7777776cccccccc7777776cccccccc7776ccccc7777777776cc7777776ccccc
cc7776667776ccccc7776ccccc7776cc7776cc7776666cccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccc6666667776cc7776667776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccccccccc7776cc7776cc7776cc
cc7776cc7776ccccc7776ccccc7776cc7776cc7776ccccccccccc7776cc7776cc7776cc7776ccccc7776cc7776ccccc7776ccccccccccc7776cc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776666cc7776cc7776ccccc7776cc7776cc7777777776cc7777776666cc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776ccccc7776cc7776ccccc7776cc7776cc7777777776cc7777776ccccc7776cc7776cc
cc7776cc7776cc7777777776cc7777777776cc7777777776ccccc7777776ccccc7776cc7776ccccc7776cc7776cc7777777776cc7777776ccccc7776cc7776cc
cc6666cc6666cc6666666666cc6666666666cc6666666666ccccc6666666ccccc6666cc6666ccccc6666cc6666cc6666666666cc6666666ccccc6666cc6666cc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc77c777c777c777c777ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccc7cc7c7c7c7cc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc777cc7cc777c77ccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc7cc7c7c7c7cc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccc7cc7c7c7c7cc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccc00c000c000c00cc000c000cc00ccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc0ccc0c0c0ccc0c0cc0ccc0cc0ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc0ccc00cc00cc0c0cc0ccc0cc000ccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc0ccc0c0c0ccc0c0cc0ccc0cccc0ccccccccccccccccccccccccccccccccccccccccccccccccccc
6cccccccccccccccccccccccccccccccccccccc66cccccccccc00c0c0c000c000c000cc0cc00ccccccccccc66cccccccccccccccccccccccccccccccccccccc6
66cccccccccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccccccccccc6666cccccccccccccccccccccccccccccccccccc66
766cccccccccccccccccccccccccccccccccc667766cccccccccccccccccccccccccccccccccccccccccc667766cccccccccccccccccccccccccccccccccc667
7766cccccccccccccccccccccccccccccccc66777766cccccccccccccccccccccccccccccccccccccccc66777766cccccccccccccccccccccccccccccccc6677
77766cccccccccccccccccccccccccccccc6677777766cccccccccccccccccccccccccccccccccccccc6677777766cccccccccccccccccccccccccccccc66777
777766cccccccccccccccccccccccccccc667777777766cccccccccccccccccccccccccccccccccccc667777777766cccccccccccccccccccccccccccc667777
7777766cccccccccccccccccccccccccc66777777777766cccccccccccccccccccccccccccccccccc66777777777766cccccccccccccccccccccccccc6677777
77777766cccccccccccccccccccccccc6677777777777766cccccccccccccccccccccccccccccccc6677777777777766cccccccccccccccccccccccc66777777
777777766cccccccccccccccccccccc667777777777777766cccccccccccccccccccccccccccccc667777777777777766cccccccccccccccccccccc667777777
5555777766cccccccccccccccccccc66777755555555777766cccccccccccccccccccccccccccc66777755555555777766cccccccccccccccccccc6677775555
55555555766cccccccccccccccccc6675555555555555555766cccccccccccccccccccccccccc6675555555555555555766cccccccccccccccccc66755555555
555555555500cccccccccccccccc005555555555555555555500cccccccccccccccccccccccc005555555555555555555500cccccccccccccccc005555555555
5555555555500cccccccccccccc00555555555555555555555500cccccccccccccccccccccc00555555555555555555555500cccccccccccccc0055555555555
55555555555500cccccccccccc0055555555555555555555555500cccccccccccccccccccc0055555555555555555555555500cccccccccccc00555555555555
555555555555500cccccccccc005555555555555555555555555500cccccccccccccccccc005555555555555555555555555500cccccccccc005555555555555
5555555555555500cccccccc00555555555555555555555555555500cccccccccccccccc00555555555555555555555555555500cccccccc0055555555555555
55555555555555500cccccc0055555555555555555555555555555500cccccccccccccc0055555555555555555555555555555500cccccc00555555555555555
555555555555555500cccc005555555555555555555555555555555500cccccccccccc005555555555555555555555555555555500cccc005555555555555555
5555555555555555500cc00555555555555555555555555555555555500cccccccccc00555555555555555555555555555555555500cc0055555555555555555
555555555555555555000055555555555555555555555555555555555500cccccccc005555555555555555555555555555555555550000555555555555555555
5555555555555555555005555555555555555555555555555555555555500cccccc0055555555555555555555555555555555555555005555555555555555555
55555555555555555555005555555555555555555555555555555555555500cccc00555555555555555555555555555555555555550055555555555555555555
555555555555555555555005555555555555555555555555555555555555500cc005555555555555555555555555555555555555500555555555555555555555
55555555555555555555550055555555555555555555555555555555555555000055555555555555555555555555555555555555005555555555555555555555
55555555555555555555555005555555555555555555555555555555555555500555555555555555555555555555555555555550055555555555555555555555
55555555555555555555555500555555555555555555555555555555555555005555555555555555555555555555555555555500555555555555555555555555
55555555555555555555555550055555555555555555555555555555555550055555555555555555555555555555555555555005555555555555555555555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000141b1b16000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000141600000019151a1a17180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100001315171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050101010d05010101010d050101010d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0607010a0e060701010a0e0607010a0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0208090b02020810110b020208120b0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202080c0202020f0b0202020f0b020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202080c020f0b0202020f0b02020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101010101010101141b1b1601010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101141601010119151a1a1718010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101131517180101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101c0c1c2c3c4c5c6c7c8c9cacbcccdcecf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101d0d1d2d3d4d5d6d7d8d9dadbdcdddedf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101e0e1e2e3e4e5e6e7e8e9eaebecedeeef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050101010d05010101010d050101010d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0607010a0e060701010a0e0607010a0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0208090b02020810110b020208120b0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202080c0202020f0b0202020f0b020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202080c020f0b0202020f0b02020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
013d00200a6000f600156001c6002c6003160031600236001b6000d6000d6000c6000b6000a600096000860007600096000b6000160006600076000f600186001c60025600256001c60016600126000d60009600
0108080a1300014000180001800018000180001800018000180001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0809245001d5001c5001c5001c5001c5001c5001c5001c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0102002800000000000000000000000000f2000000000000000000c3000c400000000000000000000000c3000000000000000000c30000000000000740000000000000c2000000000000000000c3000000000000
010300280000000000246000000000000000000000000000246000000000000000000c30018600000000000018000180002430018000180001800024300180001800018000000000000000000000000000000000
011000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01090004180001a00015000160000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000000000000000000000000000000000
0109000418000160001300011000295002650029500265002d500295002950026500225001f5001d500215002e5002b50028500245002d5002d5002850028500265002e5002b5002850024500215001d50021500
0114000020700200001c7001c0001970019500157003950020700200001c7001c0001950019000147001500021700210001c7001c0001970019000237001700021700395001c7001c00019700195001770000000
011400000c000090002070009000246001970015500090000c000090001970009500207002460009000155000c000060002070006000246001670006000125000c00006000167000650020700246000600015500
011400000c000021001e7000200024600197000e7000c00002100020001e7001e7000250024600020000e50001100010001e7000c00024600167000b0000d0000c00001100197000b50020700246000100015500
0114000020700200001c7001c00025700287001570039500207002a7002c7002c7002c70019000147002a70028700287001c7001e7001e7001e700237001700021700395001c7001c00019700195001770017000
0114000020700200001c7001c00025700287001570039500207002a7002c7002c7002c70019000147002f7002d7002d7002d700217002170021700237001700021700395001c7001c00019700195001770017000
0116002006000061000d000061000d500061000d000061000d000060000610001100065000d10004000041000b000041000b500041000b000041000b0000b100040000b100045000b1000b000041000b0000b100
010b00201e4001e4001f4001e4001c4001c4001e4001e4001e4001e4001f4001e4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c4001c40010100101001010010100
011600001e4001e4001e4001e4000650000500065001a0001a000065001a0000650000500065001900019000045001700004500005000450000500045001e0001e000045001e0000450004500005000450004500
010b00201e4001e4001f4001e4001c4001c4001a4001c4001e4001f40021400234002640028400254002540019400194002540025400264002540023400234002140021400234002340025400234002140020400
01160000190001900006500135000650000500065001a0001a000065001a0000650006400065001900019000045001700004500005000450000500045001e0001e000045001e0000450004500005000450004500
010e000005400054003f50011400111000f4000c40011100034000340011100182001b200182001d2001110001400014002020011100111002020011100202000340020200224002320022400202001d4001b200
010e00000c0000c4001110018400306001420011200054000c0000a4003f50013400306001340018400054000c000111001b4003f500306001b4003f5001b4000c0001b4001d2001e400306001d2001840016200
010e00000140020200224002320022400202001d40003400034000340003400182001b400182001d400111000040020200224002320022400202001d4001b200014000140011100182001b400182001d40011100
010e00000c0001b4001d2001e400306001d200184000c00017200131003f50013400306001340018400014000c0001b4001d2001e400306001d200184001620011100111003f5001340030600134001840000400
010e0000004000040020400111001d100204001d1002910001400014002c400111001d1002c4001d10029100034002c2002e4002f2002e4002c2002940003400044002c2002e4002f2002e4002c200294001b200
010e00000c0000c0001b4001b200306001b4001b2000f4000c0000c00027400272003060027400272001b4000c0001b4001d2001e400306001d200184000c0000c0001b4001d2001e400306001d2001840000400
010d00000c0530445504255134453f6150445513245044550c0531344513245044553f6150445513245134450c0530445504255134453f6150445513245044550c0531344513245044553f615044551324513445
010d000028555234452d2352b5552a4452b2352f55532245395303725536540374353b2503954537430342553654034235325552f2402d5352b2502a4452b530284552624623530214551f24023535284302a245
010d00002b5552a4452823523555214451f2351e5551c4452b235235552a445232352d5552b4452a2352b555284452a235285552644523235215551f4451c2351a555174451e2351a5551c4451e2351f55523235
010d00000c0530045500255104453f6150045510245004550c0530044500245104553f6150045510245104450c0530045500255104453f6150045510245004550c0531044510245004553f615004551024500455
010d00000c0530245502255124453f6150245512245024550c0531244512245024553f6150245502255124450c0530245502255124453f6150245512245024550c0530244512245024553f615124550224512445
010d00002b5552a45528255235552b5452a44528545235452b5352a03528535235352b0352a03528735237352b0352a03528735237351f7251e7251c725177251f7151e7151c715177151371512715107150b715
010c00200c200004003a300004003c3003c3000c0003c6000c0000040000400002003e5003e5000c1000c0000f200034001b300034003700037500370003c6003e5000330003400032001b3000c0001b30000000
010c00200c00012200064003a300064003c3003c3000c0003c6000c0000640006400062003e5003e5000c1000c00011200054001b300054003a0002e5003a0003c6003e50003300054001320005400033001b300
010c00202200024200244002430022400243002430022300223002400022400242002220024400245002420022300222002440024300224002400024500220002450024500223002440022200244002430022300
010c0000224002b4002e40030400304003040033400304003040030200294002b2002e400302002b400272002a4002a4002a40027400274002740025400274002740027400274002720027400272002740027200
010c00002a4002a4002a400274002740027400272002740027400254002a2002e4002b2002a400252002a4002740027400274002440024200244002240024400244002440024400244002420024400182000c400
011100000c3000030000300003003c6000a3000a4000a3000c3000330003300033003c6001330013400133000c3000730007300073003c6001630016400163000c3000330003300033003c6001b3001b4001b300
01110000162001b400222003750027400375002b5002e2001b4002b2002940027200224001f400244002440024400244003a500222003a500274002e2003a400162001b4002e4002e20022400222002240022200
011100000c3000530005300053003c6000f3001f4000f3000c3000330003300033003c6001330016300133000c3000730007300073003c6001630026400163000c3000330003300033003c6000f3001b3000f300
011100001d20022400272003f50027400375002b5002e200322003320033200304003040030400375002e40037400372002c2002c2002c2002c4002c4003a400162001b4002b4002b4002b200224002240022200
011100001f2001f4001f2001f20027400375002b5002e200162001b5002e2003a5002b400375002b5002e200162001b400225003020033400375003340027200162001b400222003750027400373002b3002e300
01110000182001f500242003c5002b400335002b5002e200162001b5002e2003a5002b400375002b5002e200162001b400225003020033400375003340027200162001b400222003750027400373002b3002e300
011100000f20022400272003f50027400375002b5002e2002720027200272002440024400244002b500224002b4002b20020200202002020020400204003a400162001b4001f4001f4001f2001d4001d4001d200
007800000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c80018800188001880018800188001880018800188002480024800248002480024800248002480024800
01780000269002690026900185001870007500075000750007500000002490024900249001d5001d7000c5000c5002950000000000002b500000001d5001d5000a5000a5000a5000a5001a7001a7000a0000a000
017800000070000700007000070000700007000070000700007000070000000057000570005700057000570005700057000570003700037000370003700037000370003700037000370003700037000370003700
017800000a0001f700219002190024a0024a0024a00265001a5001a5000000026900269001ba001ba001ba000c5000c5000c5000c500000001f9001f9001f900225001f5001f50022a0022a0022a002b7002b700
0110002005b0008b0009b000ab0009b0008b0006b0002b0001b0006b0006b0003b0002b0003b0005b0007b0008b0009b000ab000ab000ab0009b0008b0007b0005b0003b0002b0002b0002b0002b0004b0007b00
0118042000c000cc000cc0000c0000c0000c000cc000cc000cc0000c0000c000cc000cc000cc0000c0000c000cc0000c0000c0000c000cc000cc000cc0000c000cc0000c000cc000cc0000c000cc000cc0005c00
012000200cb000fb0010b0011b0010b000fb000db0009b0008b000db000db000ab0009b000ab000cb000eb000fb0010b0011b0011b0011b0010b000fb000eb000cb000ab0015b0015b0015b0015b000bb000eb00
012c0020000000000000000000000000000000000001370013700137001370015700157001570015700137001870018700187001870018700187001870018700187001a7001c7001c7001c7001c7001c70000000
012800001c7001f7001f7001f7001f7001f700157001570015700157001570015700157001570015700000001c7001c7001c7001c7001c7001f7001f7001f7001f7001f700157001570015700157001570015700
012800001570015700000001f7001c7001c7001c7001c7001c7001c70015700137001370013700137001370013700137001870018700187001870018700187001870018700187001870018700187001870018700
012000000dd000dd000dd000dd001070010700107001070000c0017d0017d0017d0017d0017d0010700107000dd000dd000dd000dd001070010700107001070000c0017d0017d0017d0017d0017d000dd000dd00
011d0c201070019d0019d0019d0019d001000010000100001000017d000f7000f7000f7000f70010700107001070019d0019d0019d0019d000b0000b0000b7000b0000b7000b70017d0017d000f7000f7000f700
0120000012d0012d0012d0012d001570015700157001570000c0010d0010d0010d0010d0010d00157001570012d0012d0012d0012d00157001570000c00157001570019d0019d0019d0019d0019d000dd000dd00
011d0c20107001ed001ed001ed001ed001500015000150001500017d00147001470014700147001570015700157001ed001ed001ed001ed0015000150001570015000157001570019d0019d000f7000f7000f700
0120000019d0019d000dd0001d001400014000147001470023d0023d000bd000bd001500015000157001570019d0019d000dd0001d001700019000197001970023d0023d000bd000bd001c0001e0001e7001e700
012000001ed001ed0012d0006d002100021000217002170028d0028d0028d0020000200001e0001e7001e7001ed001ed0012d0006d002100021000257002570028d0028d0028d0028d001c0001e0001e7001e700
0112000024e0024e0021f001ff001ff001de0024f0024f0018e001de001fe001d70018e001de001fe001d7001ff0021f0024f002970029e002be002ee0024e0024e0024e0021f001ff001ff001de002470024f00
000100001b0701b0701d0701d0502100024000240002400026000260001f0001d00032000320002b000290002b0002b0002d0003500035000370003a0003000030000300002d0002b0002b000290003000030000
000100001e730217301e7302870028700267002d7002d7002170026700287002670021700267002870026700287002a7002d700327003270034700377002d7002d7002d7002a7002870028700267002d7002d700
00020000280772b0772b0771d07718077180072e0072e007110071100713007160071600707007070071600713007110070f0070c0070a0070700705007300073000730007300073000730007300073000730007
010100001d0201f0201d0200500005000050000500005000050000500005000000000500005000050000500005000000000500005000050000500005000000000500005000000000500005000000000500005000
010100001d7101f7101d7100770007700077000770007700077000770007700027000770007700077000770002700027000270002700027000270002700097000270002700097000270002700097000270002700
__music__
00 48494344
00 484a4344
00 4b494344
00 4c4a4344
00 4b4b4344
00 4c4a4344
00 52534344
00 52534344
00 52534344
00 52534344
00 54554344
00 54554344
00 56574344
01 18424344
00 1b424344
00 1c424344
00 18424344
00 181a4344
00 1b1a4344
00 1c194344
02 181d4344
00 5f424344
00 5f424344
00 5e604344
00 5f604344
00 5e604344
00 5f604344
00 5e614344
00 5f624344
00 5e614344
00 5f624344
00 63424344
00 63424344
00 63644344
00 63644344
00 65694344
00 65674344
00 63674344
00 63684344
00 6a6b6c6d
00 6e6f7071
00 6e6f7072
00 6e6f7073
00 74754344
00 74754344
00 76774344
00 74784344
00 74784344
00 76794344
00 4d517f44
00 4d517f44
00 4d4e7f44
00 4d4e7f44
00 4d507f44
00 4d507f44
00 4d4f7f44
00 7d7a4344
00 7e7a4344
00 7d7b4344
00 7e7a4344
00 7f7c5344
00 7f7c5344
00 7e7f5344
00 7e7f5344

