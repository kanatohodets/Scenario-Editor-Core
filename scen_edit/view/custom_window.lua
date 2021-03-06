CustomWindow = LCS.class{}

function CustomWindow:init(parentWindow, mode, dataType, parentObj, condition, cbExpressions, btnExpressions)
    self.mode = mode
    self.parentWindow = parentWindow
    while self.parentWindow.classname ~= "window" do
        self.parentWindow = self.parentWindow.parent
    end
    self.dataType = dataType
    self.parentObj = parentObj
    self.condition = condition
    self.cbExpressions = cbExpressions
    self.btnExpressions = btnExpressions

    self.btnOk = Button:New {
        caption = "OK",
        height = SCEN_EDIT.conf.B_HEIGHT,
        width = "40%",
        x = 10,
        y = 20,
        backgroundColor = SCEN_EDIT.conf.BTN_OK_COLOR,
    }
    self.btnCancel = Button:New {
        caption = "Cancel",
        height = SCEN_EDIT.conf.B_HEIGHT,
        width = "40%",
        x = "55%",
        y = 20,
        backgroundColor = SCEN_EDIT.conf.BTN_CANCEL_COLOR,
    }

    self.customTypes = SortByName(SCEN_EDIT.metaModel.functionTypesByOutput[self.dataType], "humanName")
    -- group by tags
    if #self.customTypes > 10 then
        self.tagGroups = {}
        for _, func in pairs(self.customTypes) do
            if func.tags ~= nil then
                for _, tag in pairs(func.tags) do
                    if self.tagGroups[tag] == nil then
                        self.tagGroups[tag] = {}
                    end
                    table.insert(self.tagGroups[tag], func)
                end
            else
                if self.tagGroups["Other"] == nil then
                    self.tagGroups["Other"] = {}
                end
                table.insert(self.tagGroups["Other"], func)
            end
        end
        self.cmbTagGroups = ComboBox:New {
            items = GetKeys(self.tagGroups),
            height = SCEN_EDIT.conf.B_HEIGHT,
            width = "40%",
            y = self.btnOk.y + self.btnOk.height + 10,
            x = 10,
        }
        self.cmbTagGroups.OnSelect = {
            function(object, itemIdx, selected)
                if selected and itemIdx > 0 then
                    self.customTypes = self.tagGroups[self.cmbTagGroups.items[itemIdx]]
                    self.cmbCustomTypes.items = GetField(self.customTypes, "humanName")
                    self.cmbCustomTypes.conditionTypes = GetField(self.customTypes, "name")
                    self.cmbCustomTypes:Invalidate()
                    self.cmbCustomTypes:Select(0)
                    self.cmbCustomTypes:Select(1)
                end
            end
        }
    end

    local cmbCustomTypesX = "20%"
    local cmbCustomTypesWidth = "60%"
    if self.cmbTagGroups ~= nil then
        cmbCustomTypesWidth = "40%"
        cmbCustomTypesX = "55%"
    end
    self.cmbCustomTypes = ComboBox:New {
        items = GetField(self.customTypes, "humanName"),
        conditionTypes = GetField(self.customTypes, "name"),
        height = SCEN_EDIT.conf.B_HEIGHT,
        width = cmbCustomTypesWidth,
        y = self.btnOk.y + self.btnOk.height + 10,
        x = cmbCustomTypesX,
    }

    self.conditionPanel = StackPanel:New {
        itemMargin = {0, 0, 0, 0},
        x = 1,
        y = 1,
        right = 1,
        autosize = true,
        resizeItems = false,
        padding = {0, 0, 0, 0}
    }
    self.cmbCustomTypes.OnSelect = {
        function(object, itemIdx, selected)
            if selected and itemIdx > 0 then
                self.conditionPanel:ClearChildren()
--                local cndName = self.cmbCustomTypes.conditionTypes[itemIdx]
                local exprType = self.customTypes[itemIdx]
                for i = 1, #exprType.input do
                    local dataType = exprType.input[i]                    
                    local subPanelName = dataType.name
                    local subPanel = SCEN_EDIT.createNewPanel(dataType.type, self.conditionPanel, dataType.sources)
                    if subPanel then
                        self.conditionPanel[subPanelName] = subPanel
                        if i ~= #exprType.input then
                            SCEN_EDIT.MakeSeparator(self.conditionPanel)
                        end
                    end
                end
            end
        end
    }

    self.window = Window:New {
        resizable = false,
        width = 350,
        height = 400,
        x = 500,
        y = 300,
        parent = screen0,
        children = {
            self.cmbCustomTypes,
            self.btnOk,
            self.btnCancel,
            ScrollPanel:New {
                x = 1,
                y = self.cmbCustomTypes.y + self.cmbCustomTypes.height + 10,
                bottom = 1,
                right = 5,
                children = {
                    self.conditionPanel,
                },
            },
            self.cmbTagGroups
        }
    }
    SCEN_EDIT.SetControlEnabled(self.parentWindow, false)

    self.btnCancel.OnClick = {
        function() 
            SCEN_EDIT.SetControlEnabled(self.parentWindow, true) 
            self.window:Dispose()
        end
    }
    
    self.btnOk.OnClick = {
        function()            
            local success, subPanels = false, nil
            if self.mode == 'edit' then
                success, subPanels = self:EditCondition()
            elseif self.mode == 'add' then
                success, subPanels = self:AddCondition()
            end
            if success then
                self.btnExpressions.tooltip = SCEN_EDIT.humanExpression(self.btnExpressions.data[1], "condition")
                SCEN_EDIT.SetControlEnabled(self.parentWindow, true)
                self.window:Dispose()
            else
                if subPanels ~= nil and #subPanels > 0 then
                    for _, subPanel in pairs(subPanels) do
                        SCEN_EDIT.HintControl(subPanel)
                    end
                end
            end
        end
    }    

    if self.cmbTagGroups ~= nil then
        self.cmbTagGroups:Select(0)
        self.cmbTagGroups:Select(1)
    end

    self.cmbCustomTypes:Select(0)
    self.cmbCustomTypes:Select(1)

    local sw = self.window
    local tw = self.parentWindow
    if self.mode == 'add' then
        sw.caption = "New expression of type " .. self.dataType
        sw.x = tw.x
        sw.y = tw.y + tw.height + 5
        if tw.parent.height <= sw.y + sw.height then
--            if tw.x + tw.width + sw.width > tw.parent.width then
--                sw.x = tw.x - sw.width
--            else
                sw.x = tw.x + tw.width
--            end
            sw.y = tw.y
        end
    elseif self.mode == 'edit' then
        local cndTags = SCEN_EDIT.metaModel.functionTypesByOutput[self.dataType][self.condition.conditionTypeName].tags
        if cndTags ~= nil and self.cmbTagGroups ~= nil then
            local primaryTag = cndTags[1]
            self.cmbTagGroups:Select(GetIndex(GetKeys(self.tagGroups), primaryTag))
        end

        self.cmbCustomTypes:Select(GetIndex(self.cmbCustomTypes.conditionTypes, self.condition.conditionTypeName))
        self:UpdatePanel()
        self.window.caption = "Edit expression of type " .. self.dataType
--        if tw.x + tw.width + sw.width > tw.parent.width then
--            sw.x = tw.x - sw.width
--        else
            sw.x = tw.x + tw.width
--        end
        sw.y = tw.y
    end    
end

function CustomWindow:UpdatePanel()
    local cndName = self.condition.conditionTypeName
    local index = GetIndex(self.cmbCustomTypes.conditionTypes, cndName)
    local exprType = self.customTypes[index]
    for i = 1, #exprType.input do
        local dataType = exprType.input[i]
        local subPanelName = dataType.name
        local subPanel = self.conditionPanel[subPanelName]
        if subPanel then
            subPanel:UpdatePanel(self.condition[subPanelName])
        end
    end
end

function CustomWindow:UpdateModel()
    local cndName = self.condition.conditionTypeName
    local index = GetIndex(self.cmbCustomTypes.conditionTypes, cndName)
    local exprType = self.customTypes[index]

    local success = true
    local errorSubPanels = {}
    for i = 1, #exprType.input do
        local dataType = exprType.input[i]
        local subPanelName = dataType.name
        local subPanel = self.conditionPanel[subPanelName]
        if subPanel then
            self.condition[subPanelName] = {}
            if not self.conditionPanel[subPanelName]:UpdateModel(self.condition[subPanelName]) then
                success = false
                table.insert(errorSubPanels, subPanel.parent)
            end
        end
    end
    return success, errorSubPanels
end

function CustomWindow:EditCondition()
    local _condition = SCEN_EDIT.deepcopy(self.condition)
    self.condition.conditionTypeName = self.cmbCustomTypes.conditionTypes[self.cmbCustomTypes.selected]    
    local success, subPanels = self:UpdateModel()
    if not success then
        SetTableValues(self.condition, _condition)
        return false, subPanels
    end
    if self.cbExpressions and not self.cbExpressions.checked then
        self.cbExpressions:Toggle()
    end
    return true
end

function CustomWindow:AddCondition()
    self.condition = { conditionTypeName = self.cmbCustomTypes.conditionTypes[self.cmbCustomTypes.selected] }
    local success, subPanels = self:UpdateModel()
    if not success then
        self.condition = nil
        return false, subPanels
    end
    table.insert(self.parentObj, self.condition)    
    if self.cbExpressions and not self.cbExpressions.checked then
        self.cbExpressions:Toggle()
    end
    return true
end


