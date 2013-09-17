if myHero.charName ~= "Ahri" then return end
require "Collision"
function OnLoad()
	LoadMenu()
	LoadVariables()
	LoadSkillRanges()
	LoadVIPPrediction()
	LoadMinions()
	LoadSummonerSpells()
	LoadEnemies()
	LoadCollisionValues()
end
function OnUnload()
	PrintFloatText(myHero,2,"Ahri WomboCombo UnLoaded!")
end
function LoadMenu()
	Config = scriptConfig("Ahri WomboCombo", " WomboCombo")
	Config:addParam("harass", "Harass (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
	Config:addParam("teamFight", "TeamFight (SpaceBar)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("farm", "Farm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
	Config:addParam("DrawCircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("DrawArrow", "Draw Arrow", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("creeps", "Creeps (J)", SCRIPT_PARAM_ONKEYDOWN, false, 74)
	Config:permaShow("harass")
	Config:permaShow("teamFight")
	Config:permaShow("farm")
	PrintFloatText(myHero,2,"Ahri WomboCombo Loaded!")
end
function LoadVariables()
	ignite = nil
	enemyHeros = {}
	enemyHerosCount = 0
	NextShot = 0
	aaTime = 0
	minionRange = false
	tick = 0
	igniteTick = 0
	ksDamages = {}
	newTarget = nil
end
function LoadCollisionValues()
	ecol = Collision(rangeE, 1250, 0.25, 90)
end
function LoadSkillRanges()
	rangeQ = 950
	rangeW = 550
	rangeE = 1000
	rangeR = 1000
	killRange = 1000
end
function LoadVIPPrediction()
	tpQ = TargetPredictionVIP(rangeQ, 1600, 0.25)
	tpE = TargetPredictionVIP(rangeE, 1250, 0.25)
	tpR = TargetPredictionVIP(rangeR, 2000, 0.25)
end
function LoadMinions()
	enemyMinion = minionManager(MINION_ENEMY, rangeQ, player, MINION_SORT_HEALTH_ASC)
	jungleMinion = minionManager(MINION_JUNGLE, rangeQ, player, MINION_SORT_HEALTH_ASC)
end
function LoadSummonerSpells()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	else 
		ignite = nil
  	end
end
function LoadEnemies()
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= player.team then
			local enemyCount = enemyHerosCount + 1
			enemyHeros[enemyCount] = {object = hero, waittxt = 0, killable = 0 }
			enemyHerosCount = enemyCount
		end
	end
end
function OnTick()
	if not myHero.dead then
		QREADY = (myHero:CanUseSpell(_Q) == READY)
		WREADY = (myHero:CanUseSpell(_W) == READY)
		EREADY = (myHero:CanUseSpell(_E) == READY)
		RREADY = (myHero:CanUseSpell(_R) == READY)
		IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
		checkKillRange()
		execute()
		orbWalk()
		jungleFarm()
		if Config.farm and not Config.teamFight and not Config.harass then
			farmKey()
		end
		if Config.harass then
			harassKey()
		end
	end
end
function checkKillRange()
	if EREADY or RREADY then
		killRange = 1000
	elseif QREADY then
		killRange = 950
	else
		killRange = 550
	end
end
function Target()
	local currentTarget = nil
	local killMana = 0
	if ValidTarget(newTarget) then
		if GetDistance(newTarget)>killRange then
			newTarget = nil
		end
	else
		newTarget = nil
	end
	for i = 1, enemyHerosCount do
		local Enemy = enemyHeros[i].object
		if ValidTarget(Enemy) then
			local pdmg = getDmg("P", Enemy, myHero, 3)
			local qdmg = getDmg("Q", Enemy, myHero, 3)
			local wdmg = getDmg("W", Enemy, myHero, 3)
			local edmg = getDmg("E", Enemy, myHero, 3)
			local rdmg = getDmg("R", Enemy, myHero, 3)
			local ADdmg = getDmg("AD", Enemy, myHero, 3)
			local dfgdamage = (GetInventoryItemIsCastable(3128) and getDmg("DFG",Enemy,myHero) or 0) -- Deathfire Grasp
			local hxgdamage = (GetInventoryItemIsCastable(3146) and getDmg("HXG",Enemy,myHero) or 0) -- Hextech Gunblade
			local bwcdamage = (GetInventoryItemIsCastable(3144) and getDmg("BWC",Enemy,myHero) or 0) -- Bilgewater Cutlass
			local botrkdamage = (GetInventoryItemIsCastable(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0) --Blade of the Ruined King
			local onhitdmg = (GetInventoryHaveItem(3057) and getDmg("SHEEN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY",Enemy,myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE",Enemy,myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK",Enemy,myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD",Enemy,myHero) or 0)
			local onspelldamage = (GetInventoryHaveItem(3151) and getDmg("LIANDRYS",Enemy,myHero) or 0) + (GetInventoryHaveItem(3188) and getDmg("BLACKFIRE",Enemy,myHero) or 0)
			local sunfiredamage = (GetInventoryHaveItem(3068) and getDmg("SUNFIRE",Enemy,myHero) or 0)
			local comboKiller = pdmg + qdmg + wdmg + edmg + rdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			local killHim = pdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			if IREADY then
				local idmg = getDmg("IGNITE",Enemy,myHero, 3)
				comboKiller = comboKiller + idmg
				killHim = killHim + idmg
				if GetDistance(Enemy)< 600 then
					if idmg>=Enemy.health then
						CastSpell(ignite, Enemy)
					end
				end
			end
			if QREADY then	
				killMana = killMana + myHero:GetSpellData(_Q).mana
				if GetDistance(Enemy)<=rangeQ then
					killHim = killHim + qdmg
					if qdmg >=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, qdmg)
						ksQDmg = qdmg
					end
				end
			end
			if WREADY then
				killMana = killMana + myHero:GetSpellData(_W).mana	
				if GetDistance(Enemy)<=rangeW then
					killHim = killHim + wdmg
					if wdmg >=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, wdmg)
						ksWDmg = wdmg
					end
				end
			end
			if EREADY then
				killMana = killMana + myHero:GetSpellData(_E).mana
				if GetDistance(Enemy)<=rangeE then
					killHim = killHim + edmg
					if edmg>=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, edmg)
						ksEDmg = edmg
					end
				end
			end
			if RREADY then
				killMana = killMana + myHero:GetSpellData(_R).mana
				if GetDistance(Enemy)<=rangeR then
					killHim = killHim + rdmg
					if rdmg>=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, rdmg)
						ksRDmg = rdmg
					end
				end
			end
			if next(ksDamages)~=nil then
				table.sort(ksDamages, function (a, b) return a<b end)
				local lowestKSDmg = ksDamages[1]
				if qdmg == lowestKSDmg then
					CastQ(Enemy)
				elseif wdmg == lowestKSDmg then
					CastW(Enemy)
				elseif edmg == lowestKSDmg then
					CastE(Enemy)
				elseif rdmg == lowestKSDmg then
					CastR(Enemy)
				end
				table.clear(ksDamages)
			end
			if GetInventoryItemIsCastable(3128) then  -- DFG      
				comboKiller = comboKiller + dfgdamage + (comboKiller*0.2)
				killHim = killHim + dfgdamage + (killHim*0.2) 
				if GetInventoryItemIsCastable(3146) then -- Hxg
					comboKiller = comboKiller + (hxgdamage*0.2)
					killHim = killHim + (hxgdamage*0.2)
				end
				if GetInventoryItemIsCastable(3144) then -- bwc
					comboKiller = comboKiller + (bwcdamage*0.2)
					killHim = killHim + (bwcdamage*0.2)
				end
				if GetInventoryItemIsCastable(3153) then -- botrk
					comboKiller = comboKiller + (botrkdamage*0.2)
					killHim = killHim + (botrkdamage*0.2)
				end
			end
			currentTarget = Enemy
			if killHim >= currentTarget.health and killMana<= myHero.mana then
				enemyHeros[i].killable = 3
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif GetDistance(myHero, newTarget) > GetDistance(myHero, currentTarget) then
						newTarget = currentTarget
					end
					if ValidTarget(newTarget) then
						killTarget(newTarget)
					end
				end
			elseif comboKiller >= currentTarget.health then
				enemyHeros[i].killable = 2
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif GetDistance(myHero, newTarget) > GetDistance(myHero, currentTarget) then
						newTarget = currentTarget
					end
					if ValidTarget(newTarget) then
						comboTarget(newTarget)
					end
				end
			else
				enemyHeros[i].killable = 1
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif GetDistance(myHero, newTarget) > GetDistance(myHero, currentTarget) then
						newTarget = currentTarget
					end
					if ValidTarget(newTarget) then
						harassTarget(newTarget)
					end
				end	
			end
		else
			killable = 0
		end
	end
end

function execute()
	Target()
end
function IsIgnited(target)
	if TargetHaveBuff("SummonerDot", target) then
		igniteTick = GetTickCount()
		return true
	elseif igniteTick == nil or GetTickCount()-igniteTick>500 then
		return false
	end
end
function farmKey()
	enemyMinion:update()
	if next(enemyMinion.objects)~= nil then
		for j, minion in pairs(enemyMinion.objects) do
			if minion.valid then
				
				local ADdmg = getDmg("AD", minion, myHero, 3)
				local Qdmg = 0
				if QREADY then
					Qdmg = getDmg("Q", minion, myHero, 3)
				end
				if GetDistance(minion)<=myHero.range +65 and ADdmg>=minion.health then
					if GetTickCount() > NextShot then
						myHero:Attack(minion)
					end
				elseif GetDistance(minion)<=rangeQ and Qdmg>=minion.health and QREADY then
					CastQ(minion)	
				end
			end
		end
	end
end
function jungleFarm()
	if not ValidTarget(newTarget) then
		jungleMinion:update()
		if next(jungleMinion.objects)~= nil then
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if Config.creeps then
						
					end
				end
			end
		end
	else
		return
	end
end
function harassKey()
	if ValidTarget(newTarget) then
		if Config.harass then
			CastQ(newTarget)
		end
	end
end
function killTarget(target)
	if ValidTarget(target) and not IsIgnited() then
		if Config.teamFight then
			CastItems(target, true)
			CastQ(target)
			CastW(target)
			CastE(target)
			CastR(target)
		end
	end
end
function comboTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target, true)
			CastQ(target)
			CastW(target)
			CastE(target)
			CastR(target)
		end
	end
end
function harassTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target)
			CastQ(target)
			CastW(target)
			CastE(target)
		end
	end
end
function CastQ(target)
	if not QREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeQ and QREADY then
			local QPos = tpQ:GetPrediction(target)
			if QPos and GetDistance(QPos)<=rangeQ then
				CastSpell(_Q, QPos.x, QPos.z)
			end
		end
	else
		return
	end
end
function CastW(target)
	if not WREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeW and WREADY then
			CastSpell(_W)
		end
	else
		return
	end
end
function CastE(target)
	if not EREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeE and EREADY then
			local EPos = tpE:GetPrediction(target)
			if EPos and GetDistance(EPos)<=rangeE and not ecol:GetMinionCollision(myHero, EPos) then
				CastSpell(_E, EPos.x, EPos.z)
			end
		end
	else
		return
	end
end
function CastR(target)
	if not RREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeR and RREADY then
			local RPos = target
			if RPos then
				EnemyPos = Vector(RPos.x, RPos.y, RPos.z)
				HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				Pos = EnemyPos + (EnemyPos-HeroPos)*(-450/GetDistance(target))
				if GetDistance(Pos)<=450 then
					CastSpell(_R, Pos.x, Pos.z)
				else
					EnemyPos2 = Vector(RPos.x, RPos.y, RPos.z)
					HeroPos2 = Vector(myHero.x, myHero.y, myHero.z)
					Pos2 = HeroPos2 + (HeroPos2-EnemyPos2 )*(-400/GetDistance(target))
					CastSpell(_R, Pos.x, Pos.z)
				end
			end
		end
	else
		return
	end
end
function CastItems(target, allItems)
	if not ValidTarget(target) then 
		return
	else
		if GetDistance(target) <=800 and allItems == true then
			CastItem(3144, target) --Bilgewater Cutlass
			CastItem(3153, target) --Blade Of The Ruin King
			CastItem(3128, target) --Deathfire Grasp
			CastItem(3146, target) --Hextech Gunblade
			CastItem(3188, target) --Blackfire Torch  
		end
		if GetDistance(target) <= 275 then
			CastItem(3184, target) --Entropy
			CastItem(3143, target) --Randuin's Omen
			CastItem(3074, target) --Ravenous Hydra
			CastItem(3131, target) --Sword of the Devine
			CastItem(3077, target) --Tiamat
			CastItem(3142, target) --Youmuu's Ghostblade
		end
		if GetDistance(target) <= 1000 then
			CastItem(3023, target) --Twin Shadows
		end
	end
end
function orbWalk()		
	if GetTickCount() > NextShot then
		if ValidTarget(newTarget) then
			if GetDistance(newTarget)<=myHero.range +65 and Config.teamFight then
				myHero:Attack(newTarget)
			else
				if Config.teamFight and Config.moveToMouse then
					local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
					local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
					local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
					myHero:MoveTo(movePos.x, movePos.z)
				end
			end
		elseif not ValidTarget(newTarget) then
			minionRange = false
			enemyMinion:update()
			jungleMinion:update()
			for i, minion in pairs(enemyMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+65 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+65 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
		end
		if not minionRange and not ValidTarget(newTarget) and Config.moveToMouse then
			if Config.teamFight then
				local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
				local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
				myHero:MoveTo(movePos.x, movePos.z)
			end
		end
	elseif GetTickCount() > aaTime then
		if Config.teamFight and Config.moveToMouse then
			local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
			local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
			local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
			myHero:MoveTo(movePos.x, movePos.z)
		end
	end
end
function OnDraw()
	if not myHero.dead then
		if ValidTarget(newTarget) and Config.DrawArrow then
			DrawArrows(myHero, newTarget, 30, 0x099B2299, 50)
		end
		if Config.DrawCircles then
			DrawCircle(myHero.x, myHero.y, myHero.z, killRange, ARGB(87,183,60,244))
		end
		for i = 1, enemyHerosCount do
			local Enemy = enemyHeros[i].object
			local killable = enemyHeros[i].killable
			if ValidTarget(Enemy) then
				if killable == 4 then
					DrawText3D(tostring("Ks him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,10,20), true)
				elseif killable == 3 then
					DrawText3D(tostring("killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,143,20), true)
				elseif killable == 2 then
					DrawText3D(tostring("Combo killer"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,248,255,20), true) 
				elseif killable == 1 then
					DrawText3D(tostring("Harass Him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,10,255,20), true)
				else
					DrawText3D(tostring("Not killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(244,66,155,255), true)
				end
			end
		end 
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("attack") and spell.animationTime then
		aaTime = GetTickCount() + spell.windUpTime * 1000 - GetLatency() / 2 + 10 + 50
		NextShot = GetTickCount() + spell.animationTime * 1000
	end
end