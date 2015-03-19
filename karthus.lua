--[[

	Script Name: DP Karthus
    	Author: lovehoppang
	Version: 0.1
	19.03.2015
]]--

if myHero.charName ~= "Karthus" then print("~please use with Karthus~") return end
require "DivinePred"

local version = "0.1"

local processTime  = os.clock()*1000
local enemyChamps = {}
local dp = DivinePred()
local karthusQ = CircleSS(math.huge,945,75,600,math.huge)
local karthusW = CircleSS(math.huge,1000,10,160,math.huge)
local predictionCD = 200 
local lastTimeStamp = os.clock()*1000
local ts = nil
local target = nil
local check = 0
local enemyChampsCount = 0
local MMA,SAC,SXO = false, false, false
local JungleMinions = nil

function OnLoad()
	Menu()
	if _G.MMA_LOADED then
		print("DP Karthus: MMA Loaded")
		MMA = true
		elseif _G.Reborn_Loaded then
			print("DP Karthus: SAC:R Loaded")
			SAC = true
		else
			require "Sxorbwalk"
			SXO = true
		end
		if SXO then
			cfg:addSubMenu("Orbwalking Settings","orbWalking")
			SxOrb:LoadToMenu(cfg.orbWalking)
		end
		cfg:addParam("arg","",5,"")
		cfg:addParam("Author","Author: lovehoppang",5,"")
		cfg:addParam("Version","Version: "..version,5,"")
		initialize()

		JungleMinions = minionManager(MINION_JUNGLE, karthusQ.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	end

	function Menu()
		cfg = scriptConfig("DP Karthus", "karthus")

		cfg:addSubMenu("Combo Settings", "combo")
		cfg.combo:addParam("combo","Combo Key",SCRIPT_PARAM_ONKEYDOWN, false, 32)
		cfg.combo:addParam("useQ","Use In Combo Q",SCRIPT_PARAM_ONOFF, true)	
		cfg.combo:addParam("useW","Use In Combo W",SCRIPT_PARAM_ONOFF, true)	
		cfg.combo:addParam("useE","Use In Combo E",SCRIPT_PARAM_ONOFF, true)
		cfg.combo:addParam("eMana","Min. Mana To Use E", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
		cfg:addSubMenu("Harass Settings", "harass")
		cfg.harass:addParam("harass","Harass Key",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
		cfg.harass:addParam("toggle","Auto Harass",SCRIPT_PARAM_ONOFF, false)
		cfg.harass:addParam("mana", "Min. Mana To Harass", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
		cfg.combo:permaShow("combo")
		cfg.harass:permaShow("harass")
		cfg:addSubMenu("JungleFarm Settings", "jungleFarm")
		cfg.jungleFarm:addParam("jungle","Farm Key",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
		cfg.jungleFarm:addParam("toggle","Farm toggle",SCRIPT_PARAM_ONOFF, false)
		cfg.jungleFarm:addParam("useQ","Use Q in Farm",SCRIPT_PARAM_ONOFF,true)
		cfg.jungleFarm:addParam("useE","Use E in Farm",SCRIPT_PARAM_ONOFF,true)
		cfg:addSubMenu("Draw Settings","draw")
		cfg.draw:addParam("qDraw","Draw Q Range",SCRIPT_PARAM_ONOFF, true)
		cfg.draw:addParam("qColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		cfg.draw:addParam("wDraw","Draw W Range",SCRIPT_PARAM_ONOFF, false)
		cfg.draw:addParam("wColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})	
		cfg.draw:addParam("eDraw","Draw E Range",SCRIPT_PARAM_ONOFF, false)
		cfg.draw:addParam("eColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		cfg:addSubMenu("Karthus: Target Selector","TS")
		ts = TargetSelector(8, karthusQ.range, DAMAGE_MAGIC, 1, true)
		ts.name = "Karthus"
		cfg.TS:addTS(ts)
	end

	function initialize()
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team then enemyChamps[""..hero.networkID] = DPTarget(hero)
				enemyChampsCount = enemyChampsCount + 1
			end
		end
	end

	function OnTick()

		ts:update()
		if ts.target ~= nil then
			SxOrb:ForceTarget(ts.target) 
			target = DPTarget(ts.target)
			else if ts.target == nil then target = nil end
		end

		if cfg.combo.combo and (os.clock()*1000 - lastTimeStamp >= predictionCD) then combo(target)
			lastTimeStamp = os.clock()*1000
		end 
		if cfg.harass.harass and (os.clock()*1000 - lastTimeStamp >= predictionCD) and myHero:GetSpellData(_Q).currentCd <= 0 then harass(target)
			lastTimeStamp = os.clock()*1000
		end
		if cfg.harass.toggle and (os.clock()*1000 - lastTimeStamp >= predictionCD) and myHero:GetSpellData(_Q).currentCd <= 0 then harass(target)
			lastTimeStamp = os.clock()*1000
		end

		
		if cfg.jungleFarm.jungle or cfg.jungleFarm.toggle then
			JungleMinions:update()
			JungleCreep = JungleMinions.objects[1]
			if ValidTarget(JungleCreep) then
				if myHero:GetSpellData(_Q).currentCd <= 0 and cfg.jungleFarm.useQ then
					CastSpell(_Q,JungleCreep)
				end
				if myHero:GetSpellData(_E).currentCd <= 0 and myHero:GetSpellData(_E).toggleState == 1 and cfg.jungleFarm.useE then
					if(GetDistance(myHero,JungleCreep) <= 550) then CastSpell(_E) end
				end
			end
		end
	end

		function combo(target)
			if target and target ~= nil then

				if cfg.combo.useW and myHero:GetSpellData(_W).currentCd <= 0 then
					local state,hitPos,perc = dp:predict(target,karthusW)
					if state == SkillShot.STATUS.SUCCESS_HIT then CastSpell(_W,hitPos.x,hitPos.z) end
				end
				if cfg.combo.useQ and myHero:GetSpellData(_Q).currentCd <= 0 then
					local state,hitPos,perc = dp:predict(target,karthusQ)
					if state == SkillShot.STATUS.SUCCESS_HIT then CastSpell(_Q,hitPos.x,hitPos.z)   end
				end

			end
			comboE()
		end

		function harass(target)
			if target and target ~= nil and harassManaManager() then
				local state,hitPos,perc = dp:predict(target,karthusQ)
				if state == SkillShot.STATUS.SUCCESS_HIT then CastSpell(_Q,hitPos.x,hitPos.z) end
			end
		end

		function OnDraw()
			if cfg.draw.qDraw then
				DrawCircle(myHero.x,myHero.y,myHero.z,875,RGB(cfg.draw.qColor[2], cfg.draw.qColor[3], cfg.draw.qColor[4]))
			end
			if cfg.draw.wDraw then
				DrawCircle(myHero.x,myHero.y,myHero.z,1000,RGB(cfg.draw.qColor[2], cfg.draw.qColor[3], cfg.draw.qColor[4]))
			end
			if cfg.draw.eDraw then
				DrawCircle(myHero.x,myHero.y,myHero.z,550,RGB(cfg.draw.qColor[2], cfg.draw.qColor[3], cfg.draw.qColor[4]))
			end
		end

		function eManaManager()
			if myHero.mana < (myHero.maxMana * ( cfg.combo.eMana / 100)) then
				return false
			else
				return true
			end
		end

		function harassManaManager()
			if myHero.mana < (myHero.maxMana * ( cfg.harass.mana / 100)) then
				return false
			else
				return true
			end
		end

		function comboE()
			if myHero:GetSpellData(_E).toggleState == 2 and eManaManager() == false then
				CastSpell(_E)
			end
			if cfg.combo.useE and myHero:GetSpellData(_E).currentCd <= 0 and myHero:GetSpellData(_E).toggleState == 1 and eManaManager() then
				for i, val in pairs(enemyChamps) do
					local dist = GetDistance(myHero,val.unit)
					if dist <= 550 then CastSpell(_E)
						break
					end 
				end
			end

			if cfg.combo.useE and myHero:GetSpellData(_E).currentCd <= 0 and myHero:GetSpellData(_E).toggleState == 2 then
				check = 0
				for i, val in pairs(enemyChamps) do
					local dist = GetDistance(myHero,val.unit)
					if dist <= 550 then break end
					check = check + 1
				end
				if check >= enemyChampsCount then
					CastSpell(_E)
				end
			end
		end