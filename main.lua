local RingMenu_AddonName, RingMenu = ...

local RingMenu_globalConfigDefault = {
    numRings = 1,
}

local RingMenu_ringConfigDefault = {
    radius = 120,
    firstSlot = 1,
    numSlots = 12,
}

local RingMenu_globalStateDefault = {
}

local RingMenu_ringStateDefault = {
}

RingMenu_globalConfig = shallow_copy(RingMenu_globalConfigDefault)
RingMenu_ringConfig = {}
RingMenu_ringConfig[1] = shallow_copy(RingMenu_ringConfigDefault)

RingMenu.globalState = shallow_copy(RingMenu_globalStateDefault)
RingMenu.ringState = {}
RingMenu.ringState[1] = shallow_copy(RingMenu_ringStateDefault)

function RingMenu_UpdateRing(ringID)
    -- Lazy-init of the ringFrame array
    RingMenu.ringFrame = RingMenu.ringFrame or {}
    
    local config = RingMenu_ringConfig[ringID] -- required for further setup
    
    if not RingMenu.ringFrame[ringID] then
        -- Lazy-init of the ringFrame itself
        RingMenu.ringFrame[ringID] = CreateFrame("Frame", "RingMenuRingFrame" .. ringID, UIParent)
        local rf = RingMenu.ringFrame[ringID]
        rf.ringID = ringID
        
        -- An invisible button used as a secure handler for
        -- (a) responding to CLICK RingMenuToggleRing*:LeftButton binding events on a secure path
        -- (b) running secure event responses for the ring button OnClick event
        rf.toggleButton = CreateFrame("Button", "RingMenuToggleRing" .. ringID, rf, "SecureHandlerMouseUpDownTemplate")
        rf.toggleButton:SetAttribute("downbutton", "")
        rf.toggleButton:SetFrameRef("UIParent", UIParent)
        rf.toggleButton:SetAttribute("_onmousedown", [[ -- (self, button)
            local rf = self:GetParent()
            local UIParent = self:GetFrameRef("UIParent")
            if rf:IsShown() then
                rf:Hide()
            else
                local relx, rely = UIParent:GetMousePosition()
                local x = relx * UIParent:GetWidth()
                local y = rely * UIParent:GetHeight()
                rf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
                rf:Show()
            end
        ]])
        
        rf:Hide()
    end
    local rf = RingMenu.ringFrame[ringID]
    
    rf:SetSize(config.radius, config.radius)
    
    -- Lazy-init this ringFrame's buttons
    rf.button = rf.button or {}
    for buttonID = 1, (config.numSlots or 1) do
        if not rf.button[buttonID] then
            rf.button[buttonID] = CreateFrame("CheckButton", "RingMenuRingFrame" .. ringID .. "Button" .. buttonID, rf, "ActionBarButtonTemplate")
            local button = rf.button[buttonID]
            button.ringID = ringID
            button.buttonID = buttonID
            
            rf.toggleButton:WrapScript(button, "OnClick", [[ -- (self, button, down)
                local rf = self:GetParent()
                rf:Hide()
            ]])
        end
        local button = rf.button[buttonID]
        
        local angle = 2 * math.pi * (0.25 - (buttonID - 1) / config.numSlots)
        local posX = config.radius * math.cos(angle)
        local posY = config.radius * math.sin(angle)
        button:SetPoint("CENTER", rf, "CENTER", posX, posY)
        button:SetAttribute("type", "action")
        button:SetAttribute("action", config.firstSlot + buttonID - 1)
    end
    -- Hide unused buttons
    for id, button in ipairs(rf.button) do
        if id > config.numSlots then
            button:Hide()
        end
    end
end

function RingMenu_UpdateAllRings()
    for ringID = 1, RingMenu_globalConfig.numRings do
        RingMenu_UpdateRing(ringID)
    end
end

-- The main frame is used only to respond to global events
RingMenu.mainFrame = CreateFrame("Frame")
RingMenu.mainFrame.OnEvent = function (self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == RingMenu_AddonName then
        print("RingMenu ADDON_LOADED")
        -- TODO: integrate default settings with saved settings
        RingMenu_UpdateAllRings()
    end
end
RingMenu.mainFrame:RegisterEvent("ADDON_LOADED")
RingMenu.mainFrame:SetScript("OnEvent", RingMenu.mainFrame.OnEvent)
