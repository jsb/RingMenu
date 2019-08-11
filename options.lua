local RingMenu_AddonName, RingMenu = ...

local options = {
    panelName = "RingMenuOptions",
    tableName = "RingMenu_globalConfig",
    rows = {
        {
            settingsField = "radius",
            label = "Radius",
            widgetType = "slider",
            min = 0, max = 300, labelSuffix = " px", valueStep = 1,
            updateFunc = nil,
            refreshFunc = nil,
        },
        {
            settingsField = "firstSlot",
            label = "First Button Slot",
            widgetType = "number",
            tooltip = "The action button slot that is used for the first button in the RingMenu.",
            updateFunc = nil,
            refreshFunc = nil,
        },
        {
            settingsField = "numSlots",
            label = "Number of Buttons",
            widgetType = "slider",
            min = 1, max = 24, labelSuffix = "", valueStep = 1,
            updateFunc = nil,
            refreshFunc = nil,
        },
    },
}

local function makeOptionsPanel(options)
    local function appendWidget(parent, child, rowPadding)
        child:SetParent(parent)
        if parent.lastWidget then
            child:SetPoint("TOPLEFT", parent.lastWidget, "BOTTOMLEFT", 0, -rowPadding)
        else
            child:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        end
        parent.lastWidget = child
    end
    
    local panel = CreateFrame("Frame", options.panelName)
    
    local labelWidth = 120
    local widgetWidth = 180
    local columnPadding = 10
    local rowPadding = 20
    
    local function refreshText(self)
        local entry = self.optionsEntry
        local settingsTable = _G["RingMenu_ringConfig"][1]
        local settingsField = entry.settingsField
        local value = settingsTable[settingsField]
        self:SetText(value)
    end
    
    local function refreshValue(self)
        local entry = self.optionsEntry
        local settingsTable = _G["RingMenu_ringConfig"][1]
        local settingsField = entry.settingsField
        local value = settingsTable[settingsField]
        self:SetValue(value)
    end
    
    local function defaultOnValueChanged(self, value, isUserInput)
        if not isUserInput then
            return
        end
        local entry = self.optionsEntry
        local settingsTable = _G["RingMenu_ringConfig"][1]
        local settingsField = entry.settingsField
        settingsTable[settingsField] = value
        
        RingMenu_UpdateRing(1)
    end
    
    local function defaultOnTextChanged(self, isUserInput)
        if not isUserInput then
            return
        end
        local entry = self.optionsEntry
        local settingsTable = _G["RingMenu_ringConfig"][1]
        local settingsField = entry.settingsField
        local value = tonumber(self:GetText())
        settingsTable[settingsField] = value
        
        RingMenu_UpdateRing(1)
    end
    
    for _, row in ipairs(options.rows) do
        local label = panel:CreateFontString(options.panelName .. "Label" .. row.settingsField, "ARTWORK", "GameFontNormal")
        label:SetText(row.label)
        label:SetWidth(labelWidth)
        label:SetJustifyH("LEFT")
        appendWidget(panel, label, rowPadding)
    
        local widget = nil
        
        if row.widgetType == "slider" then
            widget = CreateFrame("Slider", options.panelName .. "Widget" .. row.settingsField, panel, "OptionsSliderTemplate")
            widget:SetPoint("LEFT", label, "RIGHT", columnPadding, 0)
            widget:SetWidth(widgetWidth)
            widget:SetHeight(17)
            widget:SetMinMaxValues(row.min, row.max)
            if row.valueStep then
                widget:SetValueStep(row.valueStep)
                widget:SetObeyStepOnDrag(true)
            end
            widget:SetValue(row.min)
            local lowLabel = row.min
            local highLabel = row.max
            if row.labelSuffix then
                lowLabel = lowLabel .. row.labelSuffix
                highLabel = highLabel .. row.labelSuffix
            end
            _G[widget:GetName().."Low"]:SetText(lowLabel)
            _G[widget:GetName().."High"]:SetText(highLabel)

            widget:SetScript("OnValueChanged", row.updateFunc or defaultOnValueChanged)
        elseif row.widgetType == "number" then
            widget = CreateFrame("EditBox", options.panelName .. "Widget" .. row.settingsField, panel, "InputBoxTemplate")
            widget:SetPoint("LEFT", label, "RIGHT", columnPadding, 0)
            widget:SetWidth(40)
            widget:SetHeight(20)
            widget:SetAutoFocus(false)
            widget:SetNumeric(true)
            widget:SetMaxLetters(3)
            
            widget:SetScript("OnTextChanged", row.updateFunc or defaultOnTextChanged)
        else
            print("RingMenu: Unrecognized widget type: " .. row.widgetType)
        end
        if widget then
            widget.optionsEntry = row
            if row.tooltip then
                widget.tooltipText = row.tooltip
            end
        end
    end
    
    return panel
end

local oldWidgets = {
    { name = "AutoClose", text = "Auto-close on click", widget = "checkbutton", updateFunc = RingMenuSettings_AutoClose_OnUpdate },
    { name = "NumButtons", text = "Number of Buttons", widget = "slider", min = 1, max = 24, valueStep = 1, updateFunc = RingMenuSettings_NumButtons_OnUpdate },
    { name = "FirstButtonIndex", text = "First Button Slot", widget = "number", updateFunc = RingMenuSettings_FirstButtonIndex_OnUpdate },
    { name = "BackgroundColor", text = "Background Color", widget = "color", updateFunc = RingMenuSettings_BackgroundColor_OnUpdate },
    { name = "Radius", text = "Radius", widget = "slider", min = 0, max = 300, labelSuffix = " px", valueStep = 1, updateFunc = RingMenuSettings_Radius_OnUpdate },
    { name = "Angle", text = "Angle", widget = "slider", min = 0, max = 360, labelSuffix = "°", valueStep = 1, updateFunc = RingMenuSettings_Angle_OnUpdate },
    { name = "Blank", text = "", widget = "none" },
    { name = "Description", text = "|cffccccccSelect a button to show / hide the RingMenu under \"Main Menu\" > \"Key Bindings\" > \"Open / Close RingMenu\"", widget = "none" },
}

RingMenu.optionsFrame = makeOptionsPanel(options)

RingMenu.optionsFrame.name = RingMenu_AddonName
--RingMenu.optionsFrame.refresh = ...
--RingMenu.optionsFrame.okay = ...
--RingMenu.optionsFrame.cancel = ...
--RingMenu.optionsFrame.default = ...
InterfaceOptions_AddCategory(RingMenu.optionsFrame)
