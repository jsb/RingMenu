local function toboolean(value)
    return not not value
end

function CreateSettingsFrame(config)
    local frame = CreateFrame("Frame", config.name, UIParent)
    local frameWidth = 360.0
    frame:SetWidth(frameWidth)
    frame:SetHeight(240)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background", 
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)

    -- Title
    local titleTexture = frame:CreateTexture(config.name .. "TitleTexture", "ARTWORK")
    titleTexture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    titleTexture:SetWidth(280)
    titleTexture:SetHeight(64)
    titleTexture:SetPoint("TOP", frame, "TOP", 0, 12)

    local titleText = frame:CreateFontString(config.name .. "TitleText", "ARTWORK", "GameFontNormal")
    titleText:SetText(config.title)
    titleText:SetPoint("TOP", titleTexture, "TOP", 0, -14)
    
    local titleHandle = CreateFrame("Button", config.name .. "TitleHandle", frame)
    titleHandle:SetWidth(280 - 2 * 64)
    titleHandle:SetHeight(64 - 2 * 14)
    titleHandle:SetPoint("TOP", frame, "TOP", 0, 12)
    titleHandle:EnableMouse(true)
    titleHandle:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    titleHandle:SetScript("OnMouseDown", RingMenuSettings_StartDragging)
    titleHandle:SetScript("OnMouseUp", RingMenuSettings_StopDragging)

    -- Rows
    local framePadding = 24.0
    local rowPadding = 16.0
    local rowWidth = frameWidth - 2 * framePadding
    local columnPadding = 16.0
    local labelColumnX = framePadding
    local labelColumnWidth = 120.0
    local widgetColumnX = labelColumnX + labelColumnWidth + columnPadding
    local widgetColumnWidth = rowWidth - labelColumnWidth - columnPadding
    local currentY = framePadding + 18
    
    for i, row in ipairs(config.rows) do
        local label = frame:CreateFontString(config.name .. "Label" .. row.name, "ARTWORK", "GameFontNormal")
        label:SetText(row.text)
        label:SetPoint("LEFT", frame, "TOPLEFT", labelColumnX, -currentY)
        currentY = currentY + label:GetHeight() + rowPadding
        label:SetWidth(rowWidth)
        label:SetJustifyH("LEFT")
        
        if row.widget == "slider" then
            local widget = CreateFrame("Slider", config.name .. "Widget" .. row.name, frame, "OptionsSliderTemplate")
            widget:SetPoint("LEFT", frame, "TOPLEFT", widgetColumnX, -currentY + 27)
            widget:SetWidth(widgetColumnWidth)
            widget:SetHeight(17)
            widget:SetMinMaxValues(row.min, row.max)
            widget:SetValue(50)
            widget:SetValueStep(row.valueStep)
            local lowLabel = row.min
            local highLabel = row.max
            if row.labelSuffix then
                lowLabel = lowLabel .. row.labelSuffix
                highLabel = highLabel .. row.labelSuffix
            end
            getglobal(widget:GetName().."Low"):SetText(lowLabel)
            getglobal(widget:GetName().."High"):SetText(highLabel)
            widget:SetScript("OnValueChanged", row.updateFunc)
        end
        if row.widget == "checkbutton" then
            local widget = CreateFrame("CheckButton", config.name .. "Widget" .. row.name, frame, "OptionsCheckButtonTemplate")
            widget:SetPoint("LEFT", frame, "TOPLEFT", widgetColumnX - 4, -currentY + 25)
            widget:SetScript("OnClick", row.updateFunc)
        end
        if row.widget == "color" then
            local widget = CreateFrame("Button", config.name .. "Widget" .. row.name, frame, "SettingsColorSwatchTemplate")
            widget:SetPoint("LEFT", frame, "TOPLEFT", widgetColumnX, -currentY + 25)
            widget.updateFunc = row.updateFunc
        end
        if row.widget == "number" then
            local widget = CreateFrame("EditBox", config.name .. "Widget" .. row.name, frame, "InputBoxTemplate")
            widget:SetPoint("LEFT", frame, "TOPLEFT", widgetColumnX + 4, -currentY + 27)
            widget:SetWidth(40)
            widget:SetHeight(20)
            widget:SetAutoFocus(false)
            widget:SetNumeric(true)
            widget:SetMaxLetters(3)
            widget:SetScript("OnTextChanged", row.updateFunc)
        end
    end
    
    -- Buttons
    local numButtons = table.getn(config.buttons)
    local buttonPadding = 8
    local buttonWidth = (rowWidth - (numButtons - 1) * buttonPadding) / numButtons
    local buttonHeight = 18
    
    currentY = currentY + 0.5 * rowPadding
    
    for i, buttonConf in ipairs(config.buttons) do
        local button = CreateFrame("Button", config.name .. "Button" .. buttonConf.name, frame, "UIPanelButtonTemplate")
        local xOffset = (i - 1) * (buttonWidth + buttonPadding)
        button:SetPoint("LEFT", frame, "TOPLEFT", framePadding + xOffset, -currentY)
        button:SetWidth(buttonWidth)
        button:SetHeight(buttonHeight)
        button:SetText(buttonConf.text)
        button:SetScript("OnClick", buttonConf.func)
    end
    
    currentY = currentY + buttonHeight

    frame:SetHeight(currentY + 14)
    frame:SetScript("OnShow", config.showFunc)
    return frame
end

function RingMenuSettings_StartDragging()
    if arg1 == "LeftButton" then
        RingMenuSettingsFrame:StartMoving()
    end
end

function RingMenuSettings_StopDragging()
    if arg1 == "LeftButton" then
        RingMenuSettingsFrame:StopMovingOrSizing()
    end
end

function SettingsColorSwatch_OpenColorPicker(button)
    local swatchTexture = getglobal(button:GetName().."NormalTexture")
    ColorPickerFrame.func = function()
        swatchTexture:SetVertexColor(ColorPickerFrame:GetColorRGB())
        button:updateFunc()
    end
    ColorPickerFrame.opacityFunc = function()
        swatchTexture:SetAlpha(1.0 - OpacitySliderFrame:GetValue())
        button:updateFunc()
    end
    ColorPickerFrame.cancelFunc = function(previousValues)
        swatchTexture:SetVertexColor(previousValues.r, previousValues.g, previousValues.b)
        swatchTexture:SetAlpha(1.0 - previousValues.opacity)
        button:updateFunc()
    end
    
    local currentR, currentG, currentB = swatchTexture:GetVertexColor()
    local currentOpacity = 1.0 - swatchTexture:GetAlpha()
    
    ColorPickerFrame:SetColorRGB(currentR, currentG, currentB)
    ColorPickerFrame.hasOpacity = true
	ColorPickerFrame.opacity = currentOpacity
	ColorPickerFrame.previousValues = {r = currentR, g = currentG, b = currentB, opacity = currentOpacity}
    
    ShowUIPanel(ColorPickerFrame)
end

function RingMenuSettings_CopyTable(source)
    local result = {}
    for k, v in pairs(source) do
        result[k] = v
    end
    return result
end

function RingMenuSettings_SetupSettingsFrame()
    local settingsFrameConfig = {
        name = "RingMenuSettingsFrame",
        title = "RingMenu Settings",
        showFunc = RingMenuSettings_OnShow,
        rows = {
            { name = "AutoClose", text = "Auto-close on click", widget = "checkbutton", updateFunc = RingMenuSettings_AutoClose_OnUpdate },
            { name = "NumButtons", text = "Number of Buttons", widget = "slider", min = 1, max = 24, valueStep = 1, updateFunc = RingMenuSettings_NumButtons_OnUpdate },
            { name = "FirstButtonIndex", text = "First Button Slot", widget = "number", updateFunc = RingMenuSettings_FirstButtonIndex_OnUpdate },
            { name = "BackgroundColor", text = "Background Color", widget = "color", updateFunc = RingMenuSettings_BackgroundColor_OnUpdate },
            { name = "Radius", text = "Radius", widget = "slider", min = 0, max = 300, labelSuffix = " px", valueStep = 1, updateFunc = RingMenuSettings_Radius_OnUpdate },
            { name = "Angle", text = "Angle", widget = "slider", min = 0, max = 360, labelSuffix = "°", valueStep = 1, updateFunc = RingMenuSettings_Angle_OnUpdate },
            { name = "Blank", text = "", widget = "none" },
            { name = "Description", text = "|cffccccccSelect a button to show / hide the RingMenu under \"Main Menu\" > \"Key Bindings\" > \"Open / Close RingMenu\"", widget = "none" },
        },
        buttons = {
            { name = "Okay", text = "Okay", func = RingMenuSettings_CloseOkay },
            { name = "Cancel", text = "Cancel", func = RingMenuSettings_CloseCancel },
            { name = "Default", text = "Reset", func = RingMenuSettings_Reset },
        },
    }

    -- Only show 'zoom buttons' options if cyCircled AddOn is present
    if cyCircled_RingMenu then
        table.insert(settingsFrameConfig.rows, 2, {name = "ZoomButtonIcons", text = "Enlarge icons", widget = "checkbutton", updateFunc = RingMenuSettings_ZoomButtonIcons_OnUpdate})
    end

    RingMenuSettingsFrame = CreateSettingsFrame(settingsFrameConfig)
    RingMenuSettingsFrame:Hide()
end

RingMenuSettings_previousSettings = {}
function RingMenuSettings_OnShow()
    PlaySound("GAMEDIALOGOPEN", "master")
    RingMenuSettings_previousSettings = RingMenuSettings_CopyTable(RingMenu_settings)
    RingMenuSettings_UpdateAllWidgets()
end

function RingMenuSettings_UpdateAllWidgets()
    getglobal("RingMenuSettingsFrameWidgetAutoClose"):SetChecked(RingMenu_settings.autoClose)
    getglobal("RingMenuSettingsFrameWidgetNumButtons"):SetValue(RingMenu_settings.numButtons)
    getglobal("RingMenuSettingsFrameWidgetFirstButtonIndex"):SetText(RingMenu_settings.startPageID)
    local colorSwatch = getglobal("RingMenuSettingsFrameWidgetBackgroundColorNormalTexture")
    colorSwatch:SetVertexColor(RingMenu_settings.colorR, RingMenu_settings.colorG, RingMenu_settings.colorB)
    colorSwatch:SetAlpha(RingMenu_settings.colorAlpha)
    getglobal("RingMenuSettingsFrameWidgetRadius"):SetValue(RingMenu_settings.radius)
    getglobal("RingMenuSettingsFrameWidgetAngle"):SetValue(RingMenu_settings.angleOffset)

    local widgetZoomButtonIcons = RingMenuSettingsFrameWidgetZoomButtonIcons
    if widgetZoomButtonIcons then
        widgetZoomButtonIcons:SetChecked(RingMenu_settings.zoomButtonIcons)
    end
    
    RingMenuSettings_UpdateSliderLabels()
end

function RingMenuSettings_UpdateSliderLabels()
    getglobal("RingMenuSettingsFrameWidgetNumButtonsText"):SetText(RingMenu_settings.numButtons)
    local angleRounded = math.ceil(RingMenu_settings.angleOffset - 0.5)
    getglobal("RingMenuSettingsFrameWidgetAngleText"):SetText(angleRounded .. "°")
    local radiusRounded = math.ceil(RingMenu_settings.radius - 0.5)
    getglobal("RingMenuSettingsFrameWidgetRadiusText"):SetText(radiusRounded .. " px")
end

function RingMenuSettings_AutoClose_OnUpdate()
    local checkButton = getglobal("RingMenuSettingsFrameWidgetAutoClose")
    RingMenu_settings.autoClose = toboolean(checkButton:GetChecked())
end

function RingMenuSettings_NumButtons_OnUpdate()
    local slider = getglobal("RingMenuSettingsFrameWidgetNumButtons")
    RingMenu_settings.numButtons = math.floor(slider:GetValue())
    RingMenuSettings_UpdateSliderLabels()
    RingMenuFrame_ConfigureButtons()
end

function RingMenuSettings_FirstButtonIndex_OnUpdate()
    local editBox = getglobal("RingMenuSettingsFrameWidgetFirstButtonIndex")
    local buttonIndex = tonumber(editBox:GetText())
    RingMenu_settings.startPageID = buttonIndex
    RingMenuFrame_ConfigureButtons()
end

function RingMenuSettings_BackgroundColor_OnUpdate()
    local colorSwatch = getglobal("RingMenuSettingsFrameWidgetBackgroundColorNormalTexture")
    local r, g, b = colorSwatch:GetVertexColor()
    local alpha = colorSwatch:GetAlpha()
    
    RingMenu_settings.colorR = r
    RingMenu_settings.colorG = g
    RingMenu_settings.colorB = b
    RingMenu_settings.colorAlpha = alpha
    RingMenu_UpdateButtonPositions()
end

function RingMenuSettings_Radius_OnUpdate()
    local slider = getglobal("RingMenuSettingsFrameWidgetRadius")
    RingMenu_settings.radius = slider:GetValue()
    RingMenuSettings_UpdateSliderLabels()
    RingMenu_UpdateButtonPositions()
end

function RingMenuSettings_Angle_OnUpdate()
    local slider = getglobal("RingMenuSettingsFrameWidgetAngle")
    RingMenu_settings.angleOffset = slider:GetValue()
    RingMenuSettings_UpdateSliderLabels()
    RingMenu_UpdateButtonPositions()
end

function RingMenuSettings_ZoomButtonIcons_OnUpdate()
    local checkButton = getglobal("RingMenuSettingsFrameWidgetZoomButtonIcons")
    RingMenu_settings.zoomButtonIcons = toboolean(checkButton:GetChecked())
    RingMenuFrame_ConfigureButtons()
end

function RingMenuSettings_CloseOkay()
    PlaySound("GAMEDIALOGCLOSE", "master")
    RingMenuSettingsFrame:Hide()
end

function RingMenuSettings_CloseCancel()
    PlaySound("GAMEDIALOGCLOSE", "master")
    RingMenu_settings = RingMenuSettings_CopyTable(RingMenuSettings_previousSettings)
    RingMenuFrame_ConfigureButtons()
    RingMenuSettingsFrame:Hide()
end

function RingMenuSettings_Reset()
    PlaySound("GAMEGENERICBUTTONPRESS", "master")
    RingMenu_ResetDefaultSettings()
    RingMenuSettings_UpdateAllWidgets()
    RingMenuFrame_ConfigureButtons()
end
