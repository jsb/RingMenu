local RingMenu_AddonName, RingMenu = ...
local Masque, MasqueVersion = LibStub("Masque", true)

local RingMenu_globalConfigDefault = {
    numRings = 1,
    allowMultipleOpenRings = false,
}

local RingMenu_ringConfigDefault = {
    name = nil,
    keyBind = nil,
    closeOnClick = true,
    radius = 100,
    angle = 0,
    firstSlot = 13,
    numSlots = 12,
    backdropScale = 1.5,
    backdropColor = {
        r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.5,
    },
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

function RingMenu_AddRing()
    RingMenu_globalConfig.numRings = RingMenu_globalConfig.numRings + 1
    local ringID = RingMenu_globalConfig.numRings
    RingMenu_ringConfig[ringID] = RingMenu.deep_copy(RingMenu_ringConfigDefault)
    RingMenu.ringState = RingMenu.deep_copy(RingMenu_ringStateDefault)
    RingMenu_UpdateAllRings()
    return ringID
end

function RingMenu_RemoveRing(ringID)
    table.remove(RingMenu_ringConfig, ringID)
    table.remove(RingMenu.ringState, ringID)
    RingMenu_globalConfig.numRings = RingMenu_globalConfig.numRings - 1
    RingMenu_UpdateAllRings()
end

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
        
        -- An invisible button used as a secure handler for
        -- (a) responding to CLICK RingMenuToggleRing*:LeftButton binding events on a secure path
        -- (b) running secure event responses for the ring button OnClick event
        rf.toggleButton = CreateFrame("Button", "RingMenuToggleRing" .. ringID, rf, "SecureHandlerMouseUpDownTemplate")
        rf.toggleButton:SetAttribute("downbutton", "")
        rf.toggleButton:SetFrameRef("UIParent", UIParent)
        rf.toggleButton:SetAttribute("_onmousedown", [[ -- (self, button)
            local rf = self:GetParent()
            local numRings = self:GetAttribute("numRings")
            local allowMultipleOpenRings = self:GetAttribute("allowMultipleOpenRings")
            local UIParent = self:GetFrameRef("UIParent")
            
            if rf:IsShown() then
                rf:Hide()
            else
                 if not allowMultipleOpenRings then
                    for ringID = 1, numRings do
                        local rfOther = self:GetFrameRef("ringFrame" .. ringID)
                        if rfOther then
                            rfOther:Hide()
                        end
                    end
                end
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
    rf.backdrop:SetVertexColor(config.backdropColor.r, config.backdropColor.g, config.backdropColor.b, config.backdropColor.a)
    rf.toggleButton:SetAttribute("allowMultipleOpenRings", RingMenu_globalConfig.allowMultipleOpenRings)
    rf:SetAttribute("closeOnClick", config.closeOnClick)
    
    -- Lazy-init this ringFrame's buttons
    rf.button = rf.button or {}
    for buttonID = 1, (config.numSlots or 1) do
        if not rf.button[buttonID] then
            rf.button[buttonID] = CreateFrame("CheckButton", "RingMenuRingFrame" .. ringID .. "Button" .. buttonID, rf, "ActionBarButtonTemplate")
            if Masque then
                local masqueRing = Masque:Group("RingMenu")
                masqueRing:AddButton(rf.button[buttonID])
            end
            local button = rf.button[buttonID]
            button.ringID = ringID
            button.buttonID = buttonID
            
            rf.toggleButton:WrapScript(button, "OnClick", [[ -- (self, button, down)
                local rf = self:GetParent()
                local closeOnClick = rf:GetAttribute("closeOnClick")
                if closeOnClick then
                    rf:Hide()
                end
            ]])
        end
        local button = rf.button[buttonID]
        
        local angle = 2 * math.pi * (0.25 - (buttonID - 1) / config.numSlots - config.angle / 360.0)
        local posX = config.radius * math.cos(angle)
        local posY = config.radius * math.sin(angle)
        button:SetPoint("CENTER", rf, "CENTER", posX, posY)
        button:SetAttribute("type", "action")
        local firstSlot = config.firstSlot or 1
        local buttonSlot = firstSlot + buttonID - 1
        button:SetAttribute("action", buttonSlot)
    end
    -- Hide unused buttons
    for id, button in ipairs(rf.button) do
        if id > config.numSlots then
            button:Hide()
        end
    end
end

function RingMenu_UpdateRingCrossReferences()
    for ringID = 1, RingMenu_globalConfig.numRings do
        local rf = RingMenu.ringFrame[ringID]
        for ringIDOther = 1, RingMenu_globalConfig.numRings do
            local rfOther = RingMenu.ringFrame[ringIDOther]
            if rfOther then
                rf.toggleButton:SetFrameRef("RingFrame" .. ringIDOther, rfOther)
            end
        end
        rf.toggleButton:SetAttribute("numRings", RingMenu_globalConfig.numRings)
    end
end

function RingMenu_UpdateAllRings()
    for ringID = 1, RingMenu_globalConfig.numRings do
        RingMenu_UpdateRing(ringID)
    end
    RingMenu_UpdateRingCrossReferences()
end

-- The main frame is used only to respond to global events
RingMenu.mainFrame = CreateFrame("Frame")
RingMenu.mainFrame.OnEvent = function (self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == RingMenu_AddonName then
        -- Update empty fields in settings with default values
        RingMenu_globalConfig = RingMenu_globalConfig or {}
        RingMenu.update_with_defaults(RingMenu_globalConfig, RingMenu_globalConfigDefault)
        for ringID = 1, RingMenu_globalConfig.numRings do
            RingMenu_ringConfig[ringID] = RingMenu_ringConfig[ringID] or {}
            RingMenu.update_with_defaults(RingMenu_ringConfig[ringID], RingMenu_ringConfigDefault)
        end
        
        -- Init state
        RingMenu.globalState = RingMenu.deep_copy(RingMenu_globalStateDefault)
        for ringID = 1, RingMenu_globalConfig.numRings do
            RingMenu.ringState[ringID] = RingMenu.deep_copy(RingMenu_ringStateDefault)
        end
        
        RingMenu_UpdateAllRings()
        
        -- Init options panel
        RingMenuOptions_SetupPanel()
    end
end
RingMenu.mainFrame:RegisterEvent("ADDON_LOADED")
RingMenu.mainFrame:SetScript("OnEvent", RingMenu.mainFrame.OnEvent)

SLASH_RINGMENU1 = '/ringmenu'
function SlashCmdList.RINGMENU(msg, editBox)
    -- Workaround: this function has to be called twice
    InterfaceOptionsFrame_OpenToCategory("RingMenu")
    InterfaceOptionsFrame_OpenToCategory("RingMenu")
end
