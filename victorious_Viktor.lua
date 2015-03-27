if myHero.charName ~= "Viktor" then return end

require "SxOrbWalk"
require "DivinePred"

_G.AUTOUPDATE = true


local version = "1.0"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/lovehoppang/DPkarthus/master/victorious_Viktor.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
function AutoupdaterMsg(msg) print("<font color=\"#FF0000\"><b>victorious_Viktor:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if _G.AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/lovehoppang/DPkarthus/master/victorious_Viktor.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available "..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local TsQ = TargetSelector(8, 740, DAMAGE_MAGIC, 1, true)
local TsW = TargetSelector(8, 700, DAMAGE_MAGIC, 1, true)
local TsE = TargetSelector(8, 1200, DAMAGE_MAGIC, 1, true)
local TsR = TargetSelector(8, 700, DAMAGE_MAGIC, 1, true)


local viktorE = LineSS(750,760,75,125,math.huge)
local dp = DivinePred()
local dpCD = 30
local lastTimeStamp = os.clock()*100
local lastStormStamp = os.clock()*100

-------Orbwalk info-------
local lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
local myTrueRange = 0
local myTarget = nil
local tsa = TargetSelector(8, 700, DAMAGE_MAGIC, 1, true)
-------/Orbwalk info-------

local erange = 540
local damage = nil
local cfg = nil

function OnLoad()
	SxO = SxOrbWalk()
	
	cfg = scriptConfig("victorious_Viktor","Viktor")
	cfg:addSubMenu("Combo Setting","Combo")
	cfg:addSubMenu("Harass Setting","Harass")
	-- cfg:addSubMenu("KillSteal","KillSteal")
	cfg:addSubMenu("ULT Setting","RSetting")
	cfg:addSubMenu("Draw Setting","Draw")
	cfg:addSubMenu("SxOrbwalk Setting","sxo")
	cfg.Combo:addParam("Combo", "Combo Binding Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	cfg.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
	cfg.Combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	cfg.Combo:addParam("useR", "Smart ult on", SCRIPT_PARAM_ONOFF, true)
	cfg.Combo:addParam("orbkey", "orbwalk", SCRIPT_PARAM_ONOFF, true)
	cfg.Harass:addParam("Harass", "Harass Binding Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('Z'))
	cfg.Harass:addParam("toggleHarass", "Harass toggle on/off", SCRIPT_PARAM_ONOFF, false)
	cfg.RSetting:addParam("RHealth", "Enemy Health % before R", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	cfg.RSetting:addParam("RCount", "Enemy Count", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	cfg.Draw:addParam("enabled", "Draw enabled", SCRIPT_PARAM_ONOFF, true)
	cfg.Draw:addParam("lfc", "Use Lag Free Circles", SCRIPT_PARAM_ONOFF, true)
	cfg.Draw:addParam("drawAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
	cfg.Draw:addParam("drawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
	cfg.Draw:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, false)
	cfg.Draw:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
	cfg.Draw:addParam("drawR", "Draw R Range", SCRIPT_PARAM_ONOFF, false)
	SxO:LoadToMenu(cfg.sxo)
	myTrueRange = myHero.range + GetDistance(myHero.minBBox)
	tsa.range = myTrueRange
end

function OnTick()
	if cfg == nil then return
	end

	if cfg.Combo.orbkey and cfg.Combo.Combo then
		_OrbWalk()
	end

	TsQ:update()
	TsW:update()
	TsE:update()
	TsR:update()

	if cfg.Combo.Combo and dpCD < os.clock() * 100 - lastTimeStamp then
		Combo()
		lastTimeStamp = os.clock() * 100
	end
	if (cfg.Harass.Harass or cfg.Harass.toggleHarass) and dpCD < os.clock() * 100 - lastTimeStamp then
		Harass()
		lastTimeStamp = os.clock() * 100
	end
	if TsR.target ~= nil and 30 < os.clock() * 100 - lastStormStamp and myHero:CanUseSpell(_R) == READY then
		StormControl(TsR.target)
	end

end

function Combo()
	if cfg.Combo.useR and (myHero:GetSpellData(_R).name == "ViktorChaosStorm" and TsR.target ~= nil and myHero:CanUseSpell(_R) == READY) then
		if TsR.target.health < (TsR.target.maxHealth * (cfg.RSetting.RHealth / 100)) or (CountEnemyHeroInRange(700) >= cfg.RSetting.RCount) or (myHero.health < myHero.maxHealth * 0.2) then
			CastR(TsR.target)
		end
	end

	if cfg.Combo.useE and TsE.target ~= nil and myHero:CanUseSpell(_E) == READY then
		CastE(TsE.target)
	end

	if TsQ.target ~= nil and myHero:CanUseSpell(_Q) == READY then
		CastQ(TsQ.target)
		if tsa.target ~= nil then
		myHero:Attack(tsa.target)
		end
	end

	if cfg.Combo.useW and TsW.target ~= nil and myHero:CanUseSpell(_W) == READY then
		CastW(TsW.target)
	end

end

function Harass()
	if TsE.target ~= nil and myHero:CanUseSpell(_E) == READY then
		if cfg.Harass.toggleHarass or cfg.Harass.Harass then
			CastE(TsE.target)
		end
	end
end


function CastQ(target)
	if GetDistance(myHero,target) <= 740 then
		Packet("S_CAST", {spellId = _Q, targetNetworkId = target.networkID}):send()
	end
end

function CastW(target)
	local dptarget = DPTarget(target)
	local state,hitPos,perc = dp:predict(dptarget,CircleSS(math.huge,700,250,200,math.huge))
	
	if GetDistance(myHero,target) <= 700 and state==SkillShot.STATUS.SUCCESS_HIT then
		Packet("S_CAST", {spellId = _W, toX = hitPos.x, toY = hitPos.z, fromX = hitPos.x, fromY = hitPos.z}):send()
	end
end

function CastE(target)
	local dist = GetDistance(myHero,target)

	if dist<=erange then
		Packet("S_CAST", {spellId = _E, toX = target.x, toY = target.z, fromX = target.x, fromY = target.z}):send()
		
		elseif dist>erange and dist<1200 then
			local dptarget = DPTarget(target)
			local castPosX = (erange*target.x+(dist - erange)*myHero.x)/dist
			local castPosZ = (erange*target.z+(dist - erange)*myHero.z)/dist
			local state,hitPos,perc = dp:predict(dptarget,viktorE,2,Vector(castPosX,0,castPosZ))
			if state == SkillShot.STATUS.SUCCESS_HIT then
				if GetDistance(myHero,hitPos) > erange then					
					local dist2 = GetDistance(myHero,hitPos)
					local hitPosX = (erange*hitPos.x+(dist2 - erange)*myHero.x)/dist2
					local hitPosZ = (erange*hitPos.z+(dist2 - erange)*myHero.z)/dist2
					Packet("S_CAST", {spellId = _E, toX = hitPosX, toY = hitPosZ, fromX = hitPosX, fromY = hitPosZ}):send()
				else
					Packet("S_CAST", {spellId = _E, toX = hitPos.x, toY = hitPos.z, fromX = hitPos.x, fromY = hitPos.z}):send()
				end
			end
		end
	end

	function CastR(target)
		Packet("S_CAST", {spellId = _R, toX = target.x, toY = target.z, fromX = target.x, fromY = target.z}):send()
	end

	function StormControl(target)
		if myHero:GetSpellData(_R).name == "viktorchaosstormguide" then
			Packet("S_CAST", {spellId = _R, toX = target.x, toY = target.z, fromX = target.x, fromY = target.z}):send()
		end
	end

function OnDraw()
__draw()
end


	function OnProcessSpell(object, spell)
		if object == myHero then
			if spell.name:lower():find("attack") or spell.name:lower():find("viktorqbuff") then
				lastAttack = GetTickCount() - GetLatency()/2
				lastWindUpTime = spell.windUpTime*1000
				lastAttackCD = spell.animationTime*1000

			end
		end
	end
	function _OrbWalk()
		tsa:update()
		if tsa.target ~=nil and GetDistance(tsa.target) <= myTrueRange then	
			if timeToShoot() then
				myHero:Attack(tsa.target)
				elseif heroCanMove() then
					moveToCursor()
				end
			else	
				moveToCursor()
			end
		end
		function heroCanMove()
			return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
		end
		function timeToShoot()
			return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
		end
		function moveToCursor()
			if GetDistance(mousePos) > 1 then
				local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
				myHero:MoveTo(moveToPos.x, moveToPos.z)
			end
		end



function __draw()

    DrawCircles()

end

function DrawCircles()

    if cfg and cfg.Draw and cfg.Draw.enabled then

        if cfg.Draw.lfc then

            if cfg.Draw.drawAA then DrawCircleLFC(myHero.x, myHero.y, myHero.z, myTrueRange, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawQ then DrawCircleLFC(myHero.x, myHero.y, myHero.z, 740, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawW then DrawCircleLFC(myHero.x, myHero.y, myHero.z, 700, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawE then DrawCircleLFC(myHero.x, myHero.y, myHero.z, 1200, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawR then DrawCircleLFC(myHero.x, myHero.y, myHero.z, 700, ARGB(255,255,255,255)) end 


        else -- NORMAL CIRCLES

            if cfg.Draw.drawAA then DrawCircle(myHero.x, myHero.y, myHero.z, myTrueRange, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, 740, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, 700, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, 1200, ARGB(255,255,255,255)) end 

            if cfg.Draw.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, 700, ARGB(255,255,255,255)) end 

        end

    end

end


function DrawCircleLFC(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 75) 
    end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
   radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end