
------ jam.lua
---- Adds a new playable character.

local heretic = Survivor.new("Heretic")

-- Load all of our sprites into a table
local sprites = {
	idle = Sprite.load("heretic_idle", "heretic/idle", 1, 7, 8),
	walk = Sprite.load("heretic_walk", "heretic/walk", 8, 7, 8),
	jump = Sprite.load("heretic_jump", "heretic/jump", 1, 7, 8),
	climb = Sprite.load("heretic_climb", "heretic/climb", 2, 7, 8),
	death = Sprite.load("heretic_death", "heretic/death", 9, 7, 8),
	-- This sprite is used by the Crudely Drawn Buddy
	-- If the player doesn't have one, the Commando's sprite will be used instead
	decoy = Sprite.load("heretic_decoy", "heretic/decoy", 1, 9, 18),
}
-- Attack sprites are loaded separately as we'll be using them in our code
local sprExplode = Sprite.load("heretic_explode", "heretic/M1", 5, 7, 4)
local sprShoot1 = Sprite.load("heretic_shoot1", "heretic/shoot1", 1, 3, 3)
local sprShoot2 = Sprite.load("heretic_shoot2", "heretic/shoot2", 7, 7, 8)
local sprShoot3 = Sprite.load("heretic_shoot3", "heretic/shoot3", 4, 7, 8)
local sprShoot4 = Sprite.load("heretic_shoot4", "heretic/shoot4", 6, 7, 8)
local sprMael = Sprite.load("maelstrom", "heretic/Maelstrom", 6, 14, 2)
local sprRuinExplo = Sprite.load("ruin_explode", "heretic/RuinExplode", 6, 5, 6)
local sprMaelExplo = Sprite.load("maelstrom_explode", "heretic/MaelstromExplosion", 5, 17, 16)
local sprFeather = Sprite.load("feather_of_heresy", "heretic/Feather of Heresy", 6, 12, 5)
-- The hit sprite used by our X skill
local sprSparksHeretic = Sprite.load("heretic_sparks1", "heretic/bullet", 4, 10, 8)
-- The spikes creates by our V skill
local sprHereticSpike = Sprite.load("heretic_spike", "heretic/spike", 5, 12, 32)
local sprSparksSpike = Sprite.load("heretic_sparks2", "heretic/hitspike", 4, 8, 9)
-- The sprite used by the skill icons
local sprSkills = Sprite.load("heretic_skills", "heretic/skills", 5, 0, 0)

-- Get the sounds we'll be using 
local sndGazeShoot = Sound.load("heretic/shoot.ogg")
local sndMaelShoot = Sound.load("heretic/MaelWhoosh.ogg")
local sndMaelExplode = Sound.load("heretic/MaelExplode.ogg")
local sndBullet2 = Sound.find("Bullet2", "vanilla")
local sndBoss1Shoot1 = Sound.find("Boss1Shoot1", "vanilla")
local sndGuardDeath = Sound.find("GuardDeath", "vanilla")
local inherentJumps = 2


local root = Buff.new("Lunar Root")
root.sprite = Sprite.load("Root", "heretic/Rooted", 1, 3, 3)
root:addCallback("start", function(actor)
actor:set("pHmax", actor:get("pHmax") - 100 )
end)
root:addCallback("end", function(actor)
actor:set("pHmax", actor:get("pHmax") + 100 )
end)


local ruinStacks = {}
local ruinBuff = Buff.new("Ruin")
ruinBuff.sprite = Sprite.load("ruin", "heretic/ruin", 1, 3, 3)

local function endRuin(target) 
	target:removeBuff(ruinBuff)
	ruinStacks[target] = nil 
end

local function resetRuin()
	for actor, stack in pairs(ruinStacks) do
		actor:removeBuff(ruinBuff)
	end
	ruinStacks = {}
end

local function triggerRuin(player)
	for actor, stack in pairs(ruinStacks) do
		player:fireExplosion(actor.x, actor.y, 1/19, 1/4, 3 + stack*1.2, sprRuinExplo)
	end
	resetRuin()
end

ruinBuff:addCallback("end", endRuin)

local function applyRuin(target, stacks)
	local data = target:getData()
	ruinStacks[target] = (ruinStacks[target] or 0) + stacks
	target:removeBuff(ruinBuff)
	target:applyBuff(ruinBuff, 10*60)
end

callback("onDraw", function()
	for actor, stack in pairs(ruinStacks) do
		if actor:isValid() then 
			local ruinCount = ruinStacks[actor]
			graphics.print(ruinCount, actor.x, actor.y - (actor.mask or actor:getAnimation("idle")).height/2 - 10, graphics.FONT_SMALL, graphics.ALIGN_MIDDLE, graphics.ALIGN_BOTTOM) 
		else
			ruinStacks[actor] = nil
		end
	end
end)

callback("onHit", function(damager,target,x, y)
	local p = damager:getParent()
	local data = damager:getData()
	if isa(p or misc.director, "PlayerInstance") and p:getSurvivor() == heretic then
		if damager:get("critical") > 0 then
			p:getData().timeSinceFire1 = p:getData().timeSinceFire1 + 60*p:get("skull_ring")
			p:getData().timeSinceFire2 = p:getData().timeSinceFire2 + 60*p:get("skull_ring")
			p:getData().timeSinceFire3 = p:getData().timeSinceFire3 + 60*p:get("skull_ring")
			p:getData().timeSinceFire4 = p:getData().timeSinceFire4 + 60*p:get("skull_ring")
		end
		if (p:get("scepter") or 0) > 0 then
			applyRuin(target, p:get("scepter"))
			data.done = true
		end
		if damager:getData().procsRuin and (damager:getParent():getData().timeSinceFire4 >= 480*(1-p:get("cdr"))) and not data.done then
			applyRuin(target, 1)
		end
	end
	if damager:getData().Rooting then
		target:applyBuff(root, 3 * 60)
	end
end)


callback("onNPCDeath",endRuin)
callback("onPlayerDeath",endRuin)
callback("onStageEntry",resetRuin)
callback("onGameEnd",resetRuin)




local function getAngle(x1, y1, x2, y2)
    return math.deg(math.atan2(y1 - y2, x2 - x1))
end

function angleDif(current, target)
  return ((((current - target) % 360) + 540) % 360) - 180
end
local myParticle = ParticleType.new("myParticle")
myParticle:life(20, 30)
myParticle:scale(0.15, 0.15)
myParticle:shape("disc")
myParticle:size(1, 1, -0.02, 0)
myParticle:alpha(1, 0)
myParticle:color(Color.fromRGB(81, 0, 128), Color.fromRGB(45, 0, 69))

maelstrom = Object.new("maelstrom")
maelstrom:addCallback("step", function(self)
	local data = self:getData()
	if data.start ~= nil then
		if data.start then
			data.start = false
			data.direction = (data.parent:getFacingDirection() / 90) - 1
			data.speed = (data.charge/15 * data.direction + (data.direction * 5)) * 0.5
		end
		playerdata = data.parent:getData()
		self.spriteSpeed = 0.2
		self.x = self.x - data.speed
		if data.speed > 0.4 then data.speed = data.speed - 0.2
		elseif data.speed < -0.4 then data.speed = data.speed + 0.2
		elseif data.speed < 0.4 and data.speed > -0.4 then data.speed = 0 end
		data.count = (data.count or 0) + 1
		if data.count >= 30 then
			data.parent:fireExplosion(self.x, self.y, self.sprite.width/19, self.sprite.height/4, 0.875):getData().procsRuin = true
			data.count = 0
		end
		data.age = (data.age or 0) + 1
		if data.age >= 180 then
			sndMaelExplode:play(1.2 + math.random() * 0.3, 0.2)
			rootExplo = data.parent:fireExplosion(self.x, self.y, 40/19, 20/4, 7, sprMaelExplo)
			rootExplo:getData().Rooting = true
			rootExplo:getData().procsRuin = true
			self:destroy()
		end
	end
	
end)

local ball = Object.new("ball")
ball:addCallback("step", function(self)
	local data = self:getData()
	local enemies = ParentObject.find("enemies")
	if not(data.target and data.target:isValid()) then
		if data.stuck then
			data.stuck = false
			data.moveDir = math.random(0,360)
		end
	else
		if not data.stuck then
			data.targetAngle = getAngle(self.x,self.y,data.target.x, data.target.y)
			
			data.moveDir = data.moveDir - angleDif(data.moveDir, data.targetAngle) * 0.3
		elseif data.stuck then
			if data.target then
				self.x , self.y = data.target.x + data.xoff, data.target.y + data.yoff
			else
				data.stuck = false
				data.moveDir = math.random(0,360)
			end
			if data.start then
				data.parent:fireExplosion(self.x,self.y,1,1,0.000001, nil, nil, DAMAGER_NO_PROC)
				data.start = false
			end
		end
		if self:collidesWith(data.target, self.x, self.y) then
			data.stuck, data.xoff, data.yoff = true, self.x - data.target.x, self.y - data.target.y
		end
	end
	if data.moveDir then
		self.x = self.x + math.sin(math.rad(data.moveDir + 90)) * 5
		self.y = self.y + math.cos(math.rad(data.moveDir + 90)) * 5
	else
		data.start = true
		data.moveDir = 90 + math.random(-10,10)
		self.x = self.x + math.sin(math.rad(data.moveDir + 90)) * 5
		self.y = self.y + math.cos(math.rad(data.moveDir + 90)) * 5
	end
	
	data.target = enemies:findNearest(self.x,self.y)
	if not data.stuck then
		myParticle:burst("middle", self.x, self.y, 1)
	end
	data.age = (data.age or 0) + 1
	if data.age >= 90 then
		ballkaboom = data.parent:fireExplosion(self.x,self.y,1,1,1.2,sprExplode,nil)
		ballkaboom:getData().procsRuin = true
		self:destroy()
	end
	
end)



local function drawTimer(cur, max, x, y ,x1)
	if cur <= max then
		local diff = cur/max
		graphics.color(Color.fromHex(0x1C1A22))
		graphics.alpha(0.7)
		graphics.rectangle(x, y, x+x1, math.floor(y+18-18*diff))
		graphics.color(Color.fromRGB(255,255,255))
		graphics.alpha(0.5)
		graphics.rectangle(x, math.floor(y+18-18*diff), x+x1, math.floor(y+18-18*diff))
	end
end
local function drawCharge(cur, max, x, y ,x1)
	if cur > 0 then
		if cur >= max then cur = max end
		local diff = cur/max
		graphics.color(Color.fromRGB(187, 0, 255))
		graphics.alpha(0.7)
		graphics.rectangle(x, y+18, x+x1, math.floor(y+18-18*diff))
		graphics.color(Color.fromRGB(255,255,255))
		graphics.alpha(1)
		graphics.rectangle(x, math.floor(y+18-18*diff), x+x1, math.floor(y+18-18*diff))
	end
end
callback.register("onDraw", function()

end)
callback("onPlayerHUDDraw", function(player,x,y)
	if player:getSurvivor() == heretic then
		local data = player:getData()
		graphics.print(data.gazeCharges, x+9, y+25, graphics.FONT_SMALL, graphics.ALIGN_MIDDLE, graphics.ALIGN_BOTTOM)
		--graphics.print(player.x, x-30, y, graphics.FONT_SMALL, graphics.ALIGN_MIDDLE, graphics.ALIGN_BOTTOM)
		--graphics.print(player.y, x-30, y-5, graphics.FONT_SMALL, graphics.ALIGN_MIDDLE, graphics.ALIGN_BOTTOM)
		drawTimer(data.timeSinceFire1, 120*(1-player:get("cdr")), x, y , 17)
		drawTimer(data.timeSinceFire2, 180*(1-player:get("cdr")), x+46, y, 17)
		drawTimer(data.timeSinceFire3, 300*(1-player:get("cdr")), x+23, y, 17)
		drawTimer(data.timeSinceFire4, 480*(1-player:get("cdr")), x+69, y, 17)
		drawCharge((data.chargeTime or 0), 180, x+23, y, 17)
		--drawTimer(data.timeSinceFire2, 120, x, y)
	end
end)
-- Set the description of the character and the sprite used for skill icons
heretic:setLoadoutInfo(
[[This is Kur-Skan the Lunar Heretic from Risk of Rain 2]], sprSkills)

-- Set the character select skill descriptions
heretic:setLoadoutSkill(1, "Hungering Gaze",
[[Fire &p&6 homing projectiles&!& for &y&120&!& damage each&!&.]])

heretic:setLoadoutSkill(2, "Slicing Maelstrom",
[[&y&Charge&!& a &p&whirlwind&!& that deals &y&87.5% damage 2 times a second&!&
and then explodes for &y&700% damage&!& after &p&3 seconds&!& ]])

heretic:setLoadoutSkill(3, "Shadowfade",
[[&p&Fade away&!&, becoming &y&intangible&!& and gaining &y&full vertical control&!&. 
&p&Heal&!& for a &y&quarter(-ish)&!& of your health. Lasts &y&3 seconds&!&.]])

heretic:setLoadoutSkill(4, "Ruin",
[[&y&Some hits&!& will inflict a stack of &p&Ruin&!& 
&y&(unless the ability is on cooldown)&!&. 
Activating the skill &y&detonates all &p&Ruin&!& stacks at &p&unlimited range&!&, 
dealing &y&300% damage plus 120%&!& damage &p&per stack of Ruin&!&.]])

-- The color of the character's skill names in the character select
heretic.loadoutColor = Color(0xA23EE0)

-- The character's sprite in the selection pod
heretic.loadoutSprite = Sprite.load("heretic_select", "heretic/select", 4, 2, 0)

-- The character's walk animation on the title screen when selected
heretic.titleSprite = sprites.walk

-- Quote displayed when the game is beat as the character
heretic.endingQuote = "..and so she left, on a quest to end the royal bloodline"

-- Called when the player is created
heretic:addCallback("init", function(player)
	-- Set the player's sprites to those we previously loaded
	local data = player:getData()
	data.gazeCharges = 6
	player:setAnimations(sprites)
	-- Set the player's starting stats
	player:survivorSetInitialStats(150, 18, 0)
	-- Set the player's skill icons
	player:setSkill(1,
		"Hungering Gaze",
		"Fire 6 homing projectiles for 120% damage each.",
		sprSkills, 1,
		5
	)
	player:setSkill(2,
		"Slicing Maelstrom",
		"Shoot a whirlwind that deals 87.5% damage every half a second and then explodes for 700% damage after 3 seconds (Charge to shoot further)",
		sprSkills, 2,
		5
	)
	player:setSkill(3,
		"Shadowfade",
		"Fade away, becoming intangible and gaining full vertical control. Heal as fast as you would normally take damage while in this form. Lasts 3 seconds.",
		sprSkills, 3,
		5
	)
	player:setSkill(4,
		"Ruin",
		"Some hits will inflict a stack of Ruin (unless the ability is on cooldown). Activating the skill detonates all Ruin stacks at unlimited range, dealing 300% damage plus 120% damage per stack of Ruin.",
		sprSkills, 4,
		5
	)
end)

-- Called when the player levels up
heretic:addCallback("levelUp", function(player)
	player:survivorLevelUpStats(40, 3.6, 0, 0)
end)

-- Called when the player picks up the Ancient Scepter
heretic:addCallback("scepter", function(player)
	player:setSkill(4,
		"Ruin",
		"Everything that comes out of you will inflict an amount of ruin stacks equal to the amount of Scepters you have per hit. Activating the skill detonates all Ruin stacks at unlimited range, dealing 300% damage plus 120% damage per stack of Ruin.",
		sprSkills, 5,
		5
	)
end)
hereticFeather = Object.new("hereticFeather")
hereticFeather:addCallback("step", function(self)
	self.spriteSpeed = 0.2
	if self.subimage > 6 then
		self:destroy()
	end
end)

shadow = Object.new("shadow")
shadow:addCallback("step", function(self)
	data = self:getData()
	player = data.parent
	playerData = player:getData()
	vars = player:getAccessor()
	myParticle:burst("middle", self.x, self.y, 1)
	playerData.shadowFade = true
	player:getAccessor().turbinecharge = player:getAccessor().turbinecharge + 0.05
	if self.subimage > 4 then
		self.subimage = 1
	end
	if data.start then
		playerData.timeSinceFire2 = 0
		data.normalGrav1 = vars.pGravity1
		vars.pGravity1 = 0
		data.normalGrav2 = vars.pGravity2
		vars.pGravity2 = 0
		data.start = false
	end
	if input.checkControl("down", player) == input.HELD and not player:collidesMap(player.x,player.y+3) then
		vars.pVspeed = vars.pVspeed + 0.1
	end
	if input.checkControl("up", player) == input.HELD and not player:collidesMap(player.x,player.y-3) then
		vars.pVspeed = vars.pVspeed - 0.1
	end
	if player:collidesMap(player.x,player.y+3) then
		player.y = player.y - 3
		vars.pVspeed = math.clamp(vars.pVspeed, -20 , -0.1)
	elseif player:collidesMap(player.x,player.y-3) then
		player.y = player.y + 3
		vars.pVspeed = math.clamp(vars.pVspeed, 0.1 , 20)
	end
	vars.pVspeed = math.clamp(vars.pVspeed, -3, 3)
	if player:get("invincible") < 5 then
		player:set("invincible", 5)
	end
	playerData.timeSinceFire2 = 0
	--vars.pVspeed = 0
	data.age = (data.age or 0) + 1
	self.x, self.y = player.x, player.y
	self.spriteSpeed = 0.2
	--vars.hp = vars.hp + -vars.hp_regen * 3
	if data.age >= 180 or player:get("activity") ~= 0 then
		if player:get("invincible") <= 5 then
			player:set("invincible", 0)
		end	
		playerData.timeSinceFire2 = 0
		vars.pGravity1 = data.normalGrav1
		vars.pGravity2 = data.normalGrav2
		player.visible = true
		playerData.shadowFade = false
		self:destroy()
	end
end)
-- Called when the player tries to use a skill
heretic:addCallback("useSkill", function(player, skill)
	local data = player:getData()
	local vars = player:getAccessor()
	-- Make sure the player isn't doing anything when pressing the button
	if player:get("activity") == 0 and not data.shadowFade then
		-- Set the player's state
		
		if skill == 1 then
			-- Z skill
			if data.timeSinceFire1 and data.gazeCharges then
				if data.gazeCharges > 0 then
					player:survivorFireHeavenCracker()
					vars.turbinecharge = vars.turbinecharge + 1
					sndGazeShoot:play(0.9 + math.random() * 0.2)
					data.timeSinceFire1 = 0
					data.gazeCharges = data.gazeCharges - 1
					local thing = ball:create(player.x, player.y)
					thing:getData().parent = player
					thing.sprite = sprShoot1
					if player:getAccessor().sp>0 then
						local thing1 = ball:create(player.x, player.y)
						thing1:getData().parent = player
						thing1.sprite = sprShoot1
						if player:getAccessor().sp>1 then
							local thing2 = ball:create(player.x, player.y)
							thing2:getData().parent = player
							thing2.sprite = sprShoot1
						end
					end
				end
			end
		elseif skill == 3 then
			-- C skill
			if data.timeSinceFire2 >= 180*(1-player:get("cdr")) then
				local thing = shadow:create(player.x, player.y)
				thing:getData().parent = player
				thing:getData().start = true
				thing.sprite = sprShoot3
				player.visible = false
			end
		elseif skill == 4 and data.timeSinceFire4 >= 480*(1-player:get("cdr")) then
			-- V skill
			data.timeSinceFire4 = 0
			player:survivorActivityState(4, sprShoot4, 0.15, true, true)
		end
		
		-- Put the skill on cooldown
		player:activateSkillCooldown(skill)
	end
end)

callback("onPlayerStep", function(player,x,y)
	if player:getSurvivor() == heretic then
		local data = player:getData()
		local vars = player:getAccessor()
		if data.shadowFade then 
			vars.hp = vars.hp + vars.maxhp_base/60*0.08
		else
			vars.hp = vars.hp - vars.maxhp_base/60*0.035
		end
		if vars.jump_count >= vars.feather and input.checkControl("jump", player) == input.PRESSED and inherentJumps > 0 and vars.free == 1 then
			vars.pVspeed = -vars.pVmax * 0.8
			inherentJumps = inherentJumps - 1
			hereticFeather:create(player.x,player.y+5).sprite = sprFeather
			
		end
		if vars.free == 0 then
			inherentJumps = 2
		end
		data.timeSinceFire1 = (data.timeSinceFire1 or 120*(1-player:get("cdr"))) + 1
		data.timeSinceFire2 = (data.timeSinceFire2 or 180*(1-player:get("cdr"))) + 1
		data.timeSinceFire3 = (data.timeSinceFire3 or 300*(1-player:get("cdr"))) + 1
		data.timeSinceFire4 = (data.timeSinceFire4 or 480*(1-player:get("cdr"))) + 1
		if player:get("activity") == 0 and data.timeSinceFire3 >= 300*(1-player:get("cdr")) and not data.shadowFade then
			if input.checkControl("ability2") == input.HELD then
				data.chargeTime = (data.chargeTime or 0) + 1
				data.pressed = true
				if data.chargeTime >= 180 then
					player:survivorActivityState(2, sprShoot2, 0.25, true, true)
					data.timeSinceFire3 = 0
					data.pressed = false
				end
			elseif data.pressed then
				player:survivorActivityState(2, sprShoot2, 0.25, true, true)
				data.timeSinceFire3 = 0
				data.pressed = false
			end
		end
		if data.timeSinceFire1 >= 120*(1-player:get("cdr")) then
			data.gazeCharges = 6
		end
	end
end)
-- Called each frame the player is in a skill state
heretic:addCallback("onSkill", function(player, skill, relevantFrame)
	-- The 'relevantFrame' argument is set to the current animation frame only when the animation frame is changed
	-- Otherwise, it will be 0
	data = player:getData()
	
	if skill == 1 then 

		
		
	elseif skill == 2 then
		if relevantFrame == 1 then
			sndMaelShoot:play(1.2 + math.random() * 0.3, 0.2)
		elseif relevantFrame == 2 then
			player:survivorFireHeavenCracker()
			local proj = maelstrom:create(player.x, player.y)
			projData = proj:getData()
			projData.parent = player
			projData.direction = player:getFacingDirection()
			projData.charge = data.chargeTime
			proj.sprite = sprMael
			projData.start = true
			if player:getAccessor().sp>0 then
				local proj1 = maelstrom:create(player.x, player.y)
				projData = proj1:getData()
				projData.parent = player
				projData.direction = player:getFacingDirection()
				projData.charge = data.chargeTime + 40
				proj1.sprite = sprMael
				projData.start = true
				if player:getAccessor().sp>1 then
					local proj2 = maelstrom:create(player.x, player.y)
					projData = proj2:getData()
					projData.parent = player
					projData.direction = player:getFacingDirection()
					projData.charge = data.chargeTime + 80
					proj2.sprite = sprMael
					projData.start = true
			end
			end
			data.chargeTime = 0
		end
		
	elseif skill == 3 then
		
		
	elseif skill == 4 then
		-- V skill: jam spikes
		if relevantFrame == 2 then 
			player:survivorFireHeavenCracker()
			triggerRuin(player)
		end
		
	end
end)
