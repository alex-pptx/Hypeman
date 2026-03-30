local api = require("api")


local hypeman = {
	name = "Hypeman",
	author = "Powerpoint",
	version = "0.1",
	desc = "Pipe it up."
}

local killCounterWindow 
local killBarWindow
local killBar

local currentSession

local killStage = 0
local killMultiplier = 0

local flavorText = {
    "DESTRUCTION",
    "DOMINATION",
    "CALAMITY",
    "CHAOTIC",
    "BRUTAL",
    "GODLIKE"
}

--labor tracking variables
local laborUsedTimer = 0
local laborUsed = false
local LABOR_USED_TIMER_RATE = 300

local function updateKillBar()
    killStage = killStage + 1
    if killStage > 9 then 
        killStage = 0
        killMultiplier = killMultiplier + 1
        killBarWindow.killMultiplierLabel:SetText("x" .. tostring(killMultiplier))
        killBarWindow.killMultiplierLabel:Show(true)

        killBarWindow.flavorTextLabel:SetText(flavorText[killMultiplier])
        killBarWindow.flavorTextLabel:Show(true)
    end
    killBar:SetValue(killStage)

end

local function trackKill(unitId, expAmount, expString)
    local playerId = api.Unit:GetUnitId("player")
    if playerId == unitId and laborUsed == false then 
        if currentSession ~= nil then 
            currentSession["kills"] = currentSession["kills"] + 1
            updateKillBar()
        end 
    end
end 

local function laborPointsChanged(diff, laborPoints)
    -- If labor is spent, start the labor used timer for accurate kill tracking
    if diff < 0 then 
        laborUsedTimer = 0
        laborUsed = true
    end
    
    if diff < 0 and currentSession ~= nil then 
        currentSession["laborSpent"] = currentSession["laborSpent"] + (diff*-1)
    end 
end




local function OnUpdate(dt)
	-- --slowing down OnUpdate to only run every 100ms (10 times per second)
	-- lastUpdate = lastUpdate + dt
    -- if lastUpdate < 100 then
    --     return
    -- end

    -- lastUpdate = dt
	-- -----------------------------

	-- Labor used timer for excluding from kill count
    if laborUsedTimer + dt > LABOR_USED_TIMER_RATE then 
        laborUsedTimer = 0
        laborUsed = false
        -- api.Log:Info("Labor used timer reset")
    end
    laborUsedTimer = laborUsedTimer + dt



	killCounterWindow.killsLabel:SetText("Kills: " .. tostring(currentSession["kills"]))

	
end

local function OnLoad()
    -- kill counter bar
    killBarWindow = api.Interface:CreateEmptyWindow("killcounter")
    killBarWindow:Show(true)
    killBarWindow:SetExtent(255, 20)
    killBarWindow:AddAnchor("TOP", "UIParent", "TOP", 10, 88)


    killBar = api.Interface:CreateStatusBar("killo", killBarWindow, "item_evolving_material")
    killBar:SetBarColor({
    ConvertColor(160),
    ConvertColor(0),
    ConvertColor(204),
    1
    })
    killBar.bg:SetColor(ConvertColor(76), ConvertColor(45), ConvertColor(8), 0.4)
    killBar:SetMinMaxValues(0, 9)
    killBar:AddAnchor("TOPLEFT", killBarWindow, 25, 1)
    killBar:AddAnchor("BOTTOMRIGHT", killBarWindow, -1, 1)
    killBar:SetValue(0)

    local killMultiplierLabel = killBarWindow:CreateChildWidget("label", "killMultiplierLabel", 0, true)
    killMultiplierLabel:AddAnchor("CENTER", killBar, 130, 0)
    killMultiplierLabel.style:SetFontSize(24)
    ApplyTextColor(killMultiplierLabel, {1, 0, 0.85, 1})
    killMultiplierLabel:Show(false)

    local flavorTextLabel = killBarWindow:CreateChildWidget("label", "flavorTextLabel", 0, true)
    flavorTextLabel:AddAnchor("TOP", killBar, 0, -40)
    flavorTextLabel.style:SetFontSize(24)
    ApplyTextColor(flavorTextLabel, {1, 0, 0.85, 1})
    flavorTextLabel:Show(false)
    ------ end kill counter bar




    currentSession = {}
    currentSession["localTimestamp"] = api.Time:GetLocalTime()
    currentSession["kills"] = 0
    currentSession["laborSpent"] = 0


	killCounterWindow = api.Interface:CreateEmptyWindow("killCounterWindow", "UIParent")

    local function calledOnExpChange(unitId, expAmount, expString)
        -- api.Log:Info("Hello world, I have found the EXP string: " .. expString)
        api.Log:Info("anotha one...")
    end


    
	function killCounterWindow:OnEvent(event, ...)
		if event == "LABORPOWER_CHANGED" then
            laborPointsChanged(unpack(arg))
        end
        if event == "EXP_CHANGED" then
            calledOnExpChange(unpack(arg))
            trackKill(unpack(arg))
        end
    end

    killCounterWindow:SetHandler("OnEvent", killCounterWindow.OnEvent)
	-- killCounterWindow:RegisterEvent("LABORPOWER_CHANGED")
    killCounterWindow:RegisterEvent("EXP_CHANGED")
	killCounterWindow:Show(true)


	local killsLabel = killCounterWindow:CreateChildWidget("label", "killsLabel", 0, true)
    killsLabel.style:SetShadow(true)
    killsLabel.style:SetAlign(ALIGN.LEFT)
    killsLabel:AddAnchor("TOPLEFT", killCounterWindow, "TOPLEFT", 15, 50)
    killsLabel.style:SetFontSize(FONT_SIZE.SMALL)
    killsLabel:SetText("Kills: 0")

	
  	api.On("UPDATE", OnUpdate)
end

local function OnUnload()
    killCounterWindow:ReleaseHandler("EXP_CHANGED")
    api.Interface:Free(killCounterWindow)
	if killCounterWindow ~= nil then
		killCounterWindow:Show(false)
		killCounterWindow = nil
	end
    if killBarWindow ~= nil then
		killBarWindow:Show(false)
		killBarWindow = nil
	end
    if killBar ~= nil then
		killBar:Show(false)
		killBar = nil
	end
    
    api.On("UPDATE", function() return end)
end

hypeman.OnLoad = OnLoad
hypeman.OnUnload = OnUnload

return hypeman
