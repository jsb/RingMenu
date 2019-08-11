local RingMenu_AddonName, RingMenu = ...

local RingMenu_globalConfigDefault = {
    numRings = 1,
}

local RingMenu_ringConfigDefault = {
    radius = 100,
    firstSlot = 13,
    numSlots = 12,
    backdropScale = 1.5,
}

local RingMenu_globalStateDefault = {
}

local RingMenu_ringStateDefault = {
}

-- Global variables for settings and ring state.
-- These will be updated with actual values in ADDON_LOADED.
RingMenu_globalConfig = {}
RingMenu_ringConfig = {}
RingMenu.globalState = {}
RingMenu.ringState = {}

function RingMenu_UpdateRing(ringID)
    -- Lazy-init of the ringFrame array
    RingMenu.ringFrame = RingMenu.ringFrame or {}
    
    local config = RingMenu_ringConfig[ringID] -- required for further setup
    
    if not RingMenu.ringFrame[ringID] then
        -- Lazy-init of the ringFrame itself
        RingMenu.ringFrame[ringID] = CreateFrame("Frame", "RingMenuRingFrame" .. ringID, UIParent)
        local rf = RingMenu.ringFrame[ringID]
        rf.ringID = ringID
        
        -- Backdrop texture
        rf.backdrop = rf:CreateTexture(rf:GetName() .. "Backdrop", "BACKGROUND")
        rf.backdrop:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT")
        rf.backdrop:SetPoint("TOPRIGHT", rf, "TOPRIGHT")
        rf.backdrop:SetTexture("Interface\\AddOns\\RingMenu\\RingMenuBackdrop.tga")
        rf.backdrop:SetVertexColor(0, 0, 0, 0.5)
        
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
    
    local frameSize = 2 * config.radius * config.backdropScale
    rf:SetSize(frameSize, frameSize)
    
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
        -- Update empty fields in settings with default values
        RingMenu_globalConfig = RingMenu_globalConfig or {}
        update_with_defaults(RingMenu_globalConfig, RingMenu_globalConfigDefault)
        for ringID = 1, RingMenu_globalConfig.numRings do
            RingMenu_ringConfig[ringID] = RingMenu_ringConfig[ringID] or {}
            update_with_defaults(RingMenu_ringConfig[ringID], RingMenu_ringConfigDefault)
        end
        
        -- Init state
        RingMenu.globalState = shallow_copy(RingMenu_globalStateDefault)
        for ringID = 1, RingMenu_globalConfig.numRings do
            RingMenu.ringState[ringID] = shallow_copy(RingMenu_ringStateDefault)
        end
        
        RingMenu_UpdateAllRings()
    end
end
RingMenu.mainFrame:RegisterEvent("ADDON_LOADED")
RingMenu.mainFrame:SetScript("OnEvent", RingMenu.mainFrame.OnEvent)
