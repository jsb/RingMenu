local RingMenu_AddonName, RingMenu = ...

local function getRingBindingCommand(ringID)
    local ringFrame = RingMenu.ringFrame[ringID]
    local toggleButton = ringFrame.toggleButton
    return "CLICK " .. toggleButton:GetName() .. ":LeftButton"
end

local function getRingBindingKeyBinds(ringID)
    local command = getRingBindingCommand(ringID)
    return { GetBindingKey(command) }
end

local function unbindAllRingBindingKeyBinds(ringID)
    local keyBinds = getRingBindingKeyBinds(ringID)
    for _, keyBind in ipairs(keyBinds) do
        SetBinding(keyBind)
    end
end

local function getRingBindingKeyBindsText(ringID)
    local keyBinds = getRingBindingKeyBinds(ringID)
    if #keyBinds > 0 then
        return GetBindingText(keyBinds[1])
    else
        return "(not bound)"
    end
end

local function getRingDropdownText(ringID)
    local ringName = RingMenu_ringConfig[ringID].name
    local bindingText = getRingBindingKeyBindsText(ringID)
    if ringName and strlen(ringName) > 0 then
        return bindingText .. ": " .. ringName
    else
        return bindingText
    end
end

local function restoreAllSavedKeyBinds()
    for ringID = 1, RingMenu_globalConfig.numRings do
        local ringConfig = RingMenu_ringConfig[ringID]
        if ringConfig.keyBind then
            SetBinding(ringConfig.keyBind, getRingBindingCommand(ringID))
        end
    end
    AttemptToSaveBindings(GetCurrentBindingSet())
end

function RingMenuOptionsPanel_AddRing()
    PlaySound(624) -- GAMEGENERICBUTTONPRESS
    local ringPanel = _G["RingMenuOptionsPanelRingConfig"]
    local ringID = RingMenu_AddRing()
    RingMenuOptionsPanel.currentRingID = ringID
    RingMenu_UpdateAllRings()
    ringPanel.refresh()
end

function RingMenuOptionsPanel_RemoveRing()
    PlaySound(624) -- GAMEGENERICBUTTONPRESS
    if RingMenu_globalConfig.numRings <= 1 then
        PlaySound(847) -- igQuestFailed
        return
    end

    local ringPanel = _G["RingMenuOptionsPanelRingConfig"]
    
    unbindAllRingBindingKeyBinds(RingMenuOptionsPanel.currentRingID)
    RingMenu_RemoveRing(RingMenuOptionsPanel.currentRingID)
    if RingMenuOptionsPanel.currentRingID > RingMenu_globalConfig.numRings then
        RingMenuOptionsPanel.currentRingID = RingMenu_globalConfig.numRings
    end
    
    restoreAllSavedKeyBinds()
    RingMenu_UpdateAllRings()
    ringPanel.refresh()
end

RingMenu.ringConfigWidgets = {
    {
        name = "keyBind",
        label = "Key Binding",
        widgetType = "keyBind",
    },
    {
        name = "name",
        label = "Name",
        widgetType = "text",
    },
    {
        name = "firstSlot",
        label = "First Button Slot",
        widgetType = "number",
        tooltip = "The action button slot that is used for the first button in the RingMenu.",
    },
    {
        name = "numSlots",
        label = "Number of Buttons",
        widgetType = "slider",
        min = 1, max = 24, labelSuffix = "", valueStep = 1,
    },
    {
        name = "closeOnClick",
        label = "Close on Click",
        widgetType = "checkbox",
    },
    {
        name = "backdropColor",
        label = "Backdrop Color",
        widgetType = "color",
    },
    {
        name = "radius",
        label = "Radius",
        widgetType = "slider",
        min = 0, max = 300, labelSuffix = " px", valueStep = 1,
    },
    {
        name = "angle",
        label = "Angle",
        widgetType = "slider",
        min = 0, max = 360, labelSuffix = " °", valueStep = 1,
    },
}

function RingMenuOptions_SetupPanel()
    local panel = _G["RingMenuOptionsPanel"]
    local ringPanel = _G["RingMenuOptionsPanelRingConfig"]
    local ringDropdown = _G["RingMenuOptionsPanelRingDropDown"]
    
    -- Setup the drop down menu
    
    panel.currentRingID = 1
    
    function ringDropdown.Clicked(self, ringID, arg2, checked)
        RingMenuOptionsPanel.currentRingID = ringID
        ringPanel.refresh()
    end
    
    function ringDropdown.Menu()
        for ringID = 1, RingMenu_globalConfig.numRings do
            local info = UIDropDownMenu_CreateInfo()
            info.text = getRingDropdownText(ringID)
            info.value = ringID
            info.checked = (ringID == RingMenuOptionsPanel.currentRingID)
            info.func = ringDropdown.Clicked
            info.arg1 = ringID
            UIDropDownMenu_AddButton(info)
        end
    end
    UIDropDownMenu_Initialize(ringDropdown, ringDropdown.Menu)
    UIDropDownMenu_SetWidth(ringDropdown, 200)
    UIDropDownMenu_JustifyText(ringDropdown, "LEFT")
    UIDropDownMenu_SetText(ringDropdown, getRingDropdownText(RingMenuOptionsPanel.currentRingID))
    
    -- Setup the per-ring configuration panel
    
    local function appendWidget(parent, child, rowPadding)
        child:SetParent(parent)
        if parent.lastWidget then
            child:SetPoint("TOPLEFT", parent.lastWidget, "BOTTOMLEFT", 0, -rowPadding)
        else
            child:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        end
        parent.lastWidget = child
    end
    
    local labelWidth = 160
    local widgetWidth = 180
    local columnPadding = 0
    local rowPadding = 24
    
    local function refreshWidget(widget)
        local widgetFrame = widget.widgetFrame
        if widgetFrame then
            local settingsTable = RingMenu_ringConfig[RingMenuOptionsPanel.currentRingID]
            local settingsField = widget.name
            local value = settingsTable[settingsField]
            if widget.widgetType == "slider" then
                widgetFrame:SetValue(value)
            elseif widget.widgetType == "checkbox" then
                widgetFrame:SetChecked(value)
            elseif widget.widgetType == "text" then
                widgetFrame:SetText(value or "")
                widgetFrame:SetCursorPosition(0) -- Fix to scroll the text field to the left
                widgetFrame:ClearFocus()
            elseif widget.widgetType == "number" then
                widgetFrame:SetText(value or 0)
                widgetFrame:SetCursorPosition(0) -- Fix to scroll the text field to the left
                widgetFrame:ClearFocus()
            elseif widget.widgetType == "keyBind" then
                widgetFrame:SetText(getRingBindingKeyBindsText(RingMenuOptionsPanel.currentRingID))
            elseif widget.widgetType == "color" then
                local texture = widgetFrame.texture
                texture:SetVertexColor(value.r, value.g, value.b, value.a)
            else
                print("Unexpected widget type " .. widget.widgetType)
            end
        end
    end
    
    -- This is the method that actually updates the settings field in the RingMenu_ringConfig table
    local function widgetChanged(widget, value)
        local settingsTable = RingMenu_ringConfig[RingMenuOptionsPanel.currentRingID]
        local settingsField = widget.name
        settingsTable[settingsField] = value
        RingMenu_UpdateRing(RingMenuOptionsPanel.currentRingID)
        
        -- Some config panel changes that should take immediate effect
        UIDropDownMenu_SetText(ringDropdown, getRingDropdownText(RingMenuOptionsPanel.currentRingID))
    end
    
    local function sliderOnValueChanged(self, value, isUserInput)
        local widget = self.widget
        local label = _G[self:GetName() .. "Text"]
        local suffix = widget.labelSuffix or ""
        label:SetText(value .. suffix)
        
        if isUserInput then
            widgetChanged(widget, value)
        end
    end
    
    local function checkboxOnClick(self)
        local widget = self.widget
        local value = (not not self:GetChecked())
        widgetChanged(widget, value)
    end
    
    local function textOnValueChanged(self, isUserInput)
        if not isUserInput then
            return
        end
        local widget = self.widget
        local value = self:GetText()
        widgetChanged(widget, value)
    end
    
    local function numberOnValueChanged(self, isUserInput)
        if not isUserInput then
            return
        end
        local widget = self.widget
        local value = tonumber(self:GetText())
        widgetChanged(widget, value)
    end
    
    local keyBindHandler = CustomBindingHandler:CreateHandler("RingMenuToggle")
    
    local function keyBindOnBindingCompleted(self, completedSuccessfully, keys)
        if completedSuccessfully then
            if keys then
                unbindAllRingBindingKeyBinds(RingMenuOptionsPanel.currentRingID)
            
                -- Workaround: Sanitize modifier key names
                local metaKeyMap = {
                    ['LALT'] = 'ALT',
                    ['RALT'] = 'ALT',
                    ['LCTRL'] = 'CTRL',
                    ['RCTRL'] = 'CTRL',
                    ['LSHIFT'] = 'SHIFT',
                    ['RSHIFT'] = 'SHIFT',
                }
                for i, k in pairs(keys) do
                    keys[i] = metaKeyMap[k] or k
                end
                
                local keyBind = CreateKeyChordStringFromTable(keys)
                local command = getRingBindingCommand(RingMenuOptionsPanel.currentRingID)
                SetBinding(keyBind, command)
                AttemptToSaveBindings(GetCurrentBindingSet())
                
                widgetChanged(self.widget, keyBind)
            end
        end
        self:SetText(getRingBindingKeyBindsText(RingMenuOptionsPanel.currentRingID))
    end
    
    local function colorOnClick(self)
        local widget = self.widget
        local settingsTable = RingMenu_ringConfig[RingMenuOptionsPanel.currentRingID]
        local settingsField = widget.name
        local color = settingsTable[settingsField]
        
        ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = color.a
        ColorPickerFrame.previousValues = {color.r, color.g, color.b, color.a}
        local colorPickerCallback = function (restore)
            local value = {}
            if restore then
                value.r, value.g, value.b, value.a = unpack(restore)
            else
                value.r, value.g, value.b = ColorPickerFrame:GetColorRGB()
                value.a = OpacitySliderFrame:GetValue()
            end
            -- Color preview
            widget.widgetFrame.texture:SetVertexColor(value.r, value.g, value.b, value.a)
            widgetChanged(self.widget, value)
        end
        ColorPickerFrame.func = colorPickerCallback
        ColorPickerFrame.opacityFunc = colorPickerCallback
        ColorPickerFrame.cancelFunc = colorPickerCallback
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
    
    for _, widget in ipairs(RingMenu.ringConfigWidgets) do
        local label = ringPanel:CreateFontString(ringPanel:GetName() .. "Label" .. widget.name, "ARTWORK", "GameFontNormal")
        label:SetText(widget.label)
        label:SetWidth(labelWidth)
        label:SetJustifyH("LEFT")
        appendWidget(ringPanel, label, rowPadding)
    
        local widgetFrame = nil
        
        if widget.widgetType == "slider" then
            widgetFrame = CreateFrame("Slider", ringPanel:GetName() .. "Widget" .. widget.name, ringPanel, "OptionsSliderTemplate")
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding, 0)
            widgetFrame:SetWidth(widgetWidth)
            widgetFrame:SetHeight(17)
            widgetFrame:SetMinMaxValues(widget.min, widget.max)
            if widget.valueStep then
                widgetFrame:SetValueStep(widget.valueStep)
                widgetFrame:SetObeyStepOnDrag(true)
            end
            widgetFrame:SetValue(widget.min)
            local lowLabel = widget.min
            local highLabel = widget.max
            if widget.labelSuffix then
                lowLabel = lowLabel .. widget.labelSuffix
                highLabel = highLabel .. widget.labelSuffix
            end
            _G[widgetFrame:GetName().."Low"]:SetText(lowLabel)
            _G[widgetFrame:GetName().."High"]:SetText(highLabel)

            widgetFrame:SetScript("OnValueChanged", sliderOnValueChanged)
        elseif widget.widgetType == "checkbox" then
            widgetFrame = CreateFrame("CheckButton", ringPanel:GetName() .. "Widget" .. widget.name, ringPanel, "OptionsCheckButtonTemplate")
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding - 2, 0)
            
            widgetFrame:SetScript("OnClick", checkboxOnClick)
        elseif widget.widgetType == "text" then
            widgetFrame = CreateFrame("EditBox", ringPanel:GetName() .. "Widget" .. widget.name, ringPanel, "InputBoxTemplate")
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding + 6, 0)
            widgetFrame:SetWidth(widgetWidth - 6)
            widgetFrame:SetHeight(20)
            widgetFrame:SetAutoFocus(false)
            
            widgetFrame:SetScript("OnTextChanged", textOnValueChanged)
        elseif widget.widgetType == "number" then
            widgetFrame = CreateFrame("EditBox", ringPanel:GetName() .. "Widget" .. widget.name, ringPanel, "InputBoxTemplate")
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding + 6, 0)
            widgetFrame:SetWidth(40)
            widgetFrame:SetHeight(20)
            widgetFrame:SetAutoFocus(false)
            widgetFrame:SetNumeric(true)
            widgetFrame:SetMaxLetters(3)
            
            widgetFrame:SetScript("OnTextChanged", numberOnValueChanged)
        elseif widget.widgetType == "keyBind" then
            widgetFrame = CustomBindingManager:RegisterHandlerAndCreateButton(keyBindHandler, "CustomBindingButtonTemplateWithLabel", ringPanel)
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding - 1, 0)
            widgetFrame:SetWidth(widgetWidth + 2)
            
            keyBindHandler:SetOnBindingCompletedCallback(function (completedSuccessfully, keys)
                keyBindOnBindingCompleted(widgetFrame, completedSuccessfully, keys)
            end)
        elseif widget.widgetType == "color" then
            widgetFrame = CreateFrame("Button", ringPanel:GetName() .. "Widget" .. widget.name, ringPanel)
            widgetFrame:SetPoint("LEFT", label, "RIGHT", columnPadding + 2, 0)
            widgetFrame:SetSize(18, 18)
            
            local texture = widgetFrame:CreateTexture(nil, "BACKGROUND")
            texture:SetPoint("CENTER", widgetFrame, "CENTER")
            texture:SetSize(18, 18)
            texture:SetColorTexture(0.8, 0.8, 0.8, 1.0)
            
            widgetFrame:SetNormalTexture("Interface/ChatFrame/ChatFrameColorSwatch")
            local normalTexture = widgetFrame:GetNormalTexture()
            normalTexture:SetPoint("TOPLEFT", widgetFrame, "TOPLEFT")
            normalTexture:SetPoint("BOTTOMRIGHT", widgetFrame, "BOTTOMRIGHT")
            
            widgetFrame.texture = normalTexture
            widgetFrame:SetScript("OnClick", colorOnClick)
        else
            print("RingMenu: Unrecognized widget type: " .. widget.widgetType)
        end
        if widgetFrame then
            if widget.tooltip then
                widgetFrame.tooltipText = widget.tooltip
            end
            -- Establish cross-references
            widgetFrame.widget = widget
            widget.widgetFrame = widgetFrame
        end
    end
    
    function ringPanel.refresh()
        UIDropDownMenu_SetText(ringDropdown, getRingDropdownText(RingMenuOptionsPanel.currentRingID))
        for _, widget in ipairs(RingMenu.ringConfigWidgets) do
            refreshWidget(widget)
        end
    end
    
    -- Display the current version in the title
    local version = GetAddOnMetadata("RingMenu", "Version")
    local titleLabel = _G["RingMenuOptionsPanelTitle"]
    titleLabel:SetText("RingMenu |cFF888888v" .. version)
    
    panel.name = "RingMenu"
    panel.refresh = function (self)
        ringPanel.refresh()
    end
    -- panel.okay
    -- panel.cancel
    -- panel.default
    InterfaceOptions_AddCategory(panel)
end
