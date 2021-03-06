SCEN_EDIT.classes = {}
-- include this dir
SCEN_EDIT.classes[SCEN_EDIT_DIR .. "util.lua"] = true

function MakeComponentPanel(parentPanel)
    local componentPanel = Control:New {
        parent = parentPanel,
        width = "100%",
        height = SCEN_EDIT.conf.B_HEIGHT + 8,
        orientation = "horizontal",
        padding = {0, 0, 0, 0},
        itemMarging = {0, 0, 0, 0},
        margin = { 0, 0, 0, 0},
        resizeItems = false,
    }
    return componentPanel
end

--non recursive file include
function SCEN_EDIT.IncludeDir(dirPath)
    local files = VFS.DirList(dirPath)
    local context = Script.GetName()
    for i = 1, #files do
        local file = files[i]
        -- don't load files ending in _gadget.lua in LuaUI nor _widget.lua in LuaRules
        if file:sub(-string.len(".lua")) == ".lua" and 
            (context ~= "LuaRules" or file:sub(-string.len("_widget.lua")) ~= "_widget.lua") and
            (context ~= "LuaUI" or file:sub(-string.len("_gadget.lua")) ~= "_gadget.lua") then

            SCEN_EDIT.Include(file)
        end
    end
end

function SCEN_EDIT.Include(path)
    if not SCEN_EDIT.classes[path] then
        VFS.Include(path)
        SCEN_EDIT.classes[path] = true
    end
end

function SCEN_EDIT.ZlibCompress(str)
    return tostring(#str) .. "|" .. VFS.ZlibCompress(str)
end

function SCEN_EDIT.ZlibDecompress(str)
    local compressedSize = 0
    local strStart = 0
    for i = 1, #str do
        local substr = str:sub(1, i)
        if str:sub(i,i) == '|' then
            compressedSize = tonumber(str:sub(1, i - 1))
            strStart = i + 1
            break
        end
    end
    if compressedSize == 0 then
        error("string is not of valid format")
    end
    return VFS.ZlibDecompress(str:sub(strStart, #str), compressedSize)
end

function CallListeners(listeners, ...)
    for i = 1, #listeners do
        local listener = listeners[i]
        listener(...)
    end
end

function SCEN_EDIT.MakeConfirmButton(dialog, btnConfirm)
    dialog.OnConfirm = {}
    btnConfirm.OnClick = {
        function()
            CallListeners(dialog.OnConfirm)
            dialog:Dispose()
        end
    }
end

function SCEN_EDIT.MakeRadioButtonGroup(checkBoxes)
    for i = 1, #checkBoxes do
        local checkBox = checkBoxes[i]
        table.insert(checkBox.OnChange,
            function(cbToggled, checked)
                if checked then
                    for j = 1, #checkBoxes do
                        if i ~= j then
                            local cb = checkBoxes[j]
                            if cb.checked then
                                cb:Toggle()
                            end
                        end
                    end
                end
            end
        )
    end
end

function SCEN_EDIT.checkAreaIntersections(x, z)
    local areas = SCEN_EDIT.model.areaManager:getAllAreas()
    local selected, dragDiffX, dragDiffZ
    for id, area in pairs(areas) do
        if x >= area[1] and x < area[3] and z >= area[2] and z < area[4] then
            selected = id
            dragDiffX = area[1] - x
            dragDiffZ = area[2] - z
        end
    end
    return selected, dragDiffX, dragDiffZ
end

SCEN_EDIT.assignedCursors = {}
function SCEN_EDIT.SetMouseCursor(name)
    SCEN_EDIT.cursor = name
    if SCEN_EDIT.cursor ~= nil then
        if SCEN_EDIT.assignedCursors[name] == nil then
            Spring.AssignMouseCursor(name, name, false)
            SCEN_EDIT.assignedCursors[name] = true
        end
        Spring.SetMouseCursor(SCEN_EDIT.cursor)
    end
end

function SCEN_EDIT.MakeSeparator(panel)
    local lblSeparator = Line:New {
        parent = panel,
        height = SCEN_EDIT.conf.B_HEIGHT + 10,
        width = "100%",
    }
    return lblSeparator
end


function SCEN_EDIT.CreateNameMapping(origArray)
    local newArray = {}
    for i = 1, #origArray do
        local item = origArray[i]
        newArray[item.name] = item
    end
    return newArray
end

function SCEN_EDIT.GroupByField(origArray, field)
    local newArray = {}
    for i = 1, #origArray do
        local item = origArray[i]
        local fieldValue = item[field]
        if newArray[fieldValue] then
            table.insert(newArray[fieldValue], item)
        else
            newArray[fieldValue] = { item }
        end
    end
    return newArray
end

function GetKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function GetField(origArray, field)
    local newArray = {}
    for k, v in pairs(origArray) do
        table.insert(newArray, v[field])
    end
    return newArray
end

function GetIndex(table, value)
    for i = 1, #table do
        if table[i] == value then
            return i
        end
    end
end

-- basically does origTable = newTableValues but instead uses the old table reference
function SetTableValues(origTable, newTable)
    for k in pairs(origTable) do
        origTable[k] = nil
    end
    for k in pairs(newTable) do
        origTable[k] = newTable[k]
    end
end

function SortByName(t, name)
    local i = 1
    local sortedTable = {}
    for k, v in pairs(t) do
        sortedTable[i] = v
        i = i + 1
    end
    table.sort(sortedTable,
        function(a, b)
            return a[name] < b[name]
        end
    )
    return sortedTable
end

function PassToGadget(prefix, tag, data)
    newTable = { tag = tag, data = data }
    local msg = prefix .. "|table" .. table.show(newTable)    
    Spring.SendLuaRulesMsg(msg)
end

SCEN_EDIT.humanExpressionMaxLevel = 3
function SCEN_EDIT.humanExpression(data, exprType, dataType, level)
    local success, data = pcall(function()

    if level == nil then
        level = 1
    end
    if SCEN_EDIT.humanExpressionMaxLevel < level then
        return "..."
    end
    if exprType == "condition" and data.conditionTypeName:find("compare_") then
        local firstExpr = SCEN_EDIT.humanExpression(data.first, "value", nil, level + 1)
        local relation
        if data.conditionTypeName == "compare_number" then
            relation = SCEN_EDIT.humanExpression(data.relation, "numeric_comparison", nil, level + 1)
        else
            relation = SCEN_EDIT.humanExpression(data.relation, "identity_comparison", nil, level + 1)
        end
        local secondExpr = SCEN_EDIT.humanExpression(data.second, "value", nil, level + 1)
        local condHumanName = SCEN_EDIT.metaModel.functionTypes[data.conditionTypeName].humanName
        return condHumanName .. " (" .. firstExpr .. " " .. relation .. " " .. secondExpr .. ")"
    elseif exprType == "action" then
        local action = SCEN_EDIT.metaModel.actionTypes[data.actionTypeName]
        local humanName = action.humanName .. " ("
        for i = 1, #action.input do
            local input = action.input[i]
            humanName = humanName .. SCEN_EDIT.humanExpression(data[input.name], "value", nil, level + 1)
            if i ~= #action.input then
                humanName = humanName .. ", "
            end
        end
        return humanName .. ")"
    elseif (exprType == "value" and data.type == "expr") or exprType == "condition" then
        local expr = nil
        if data.expr then
            expr = data.expr[1]
        else
            expr = data
        end
        local exprHumanName = SCEN_EDIT.metaModel.functionTypes[expr.conditionTypeName].humanName
        
        local paramsStr = ""
        local first = true
        for k, v in pairs(expr) do
            if k ~= "conditionTypeName" then
                if not first then
                    paramsStr = paramsStr .. ", "
                end
                first = false
                paramsStr = paramsStr .. SCEN_EDIT.humanExpression(v, "value", k, level + 1)
            end
        end
        return exprHumanName .. " (" .. paramsStr .. ")"		
    elseif exprType == "value" then 
        if data.type == "pred" then
            if dataType == "unitType" then
                local unitDef = UnitDefs[data.id]
                local dataIdStr = "(id=" .. tostring(data.id) .. ")"
                if unitDef then
                    return tostring(unitDef.name) .. " " .. dataIdStr
                else
                    return dataIdStr
                end
            elseif dataType == "unit" then
                local unitId = SCEN_EDIT.model.unitManager:getSpringUnitId(data.id)
                local dataIdStr = "(id=" .. tostring(data.id) .. ")"
                if Spring.ValidUnitID(unitId) then
                    local unitDef = UnitDefs[Spring.GetUnitDefID(unitId)]
                    if unitDef then
                        return tostring(unitDef.name) .. " " .. dataIdStr
                    else
                        return dataIdStr
                    end
                else
                    return dataIdStr
                end
            elseif dataType == "trigger" then
                return data.name
            else
                return tostring(data.id)
            end
        elseif data.type == "spec" then
            return data.name
        elseif data.type == "var" then
            return SCEN_EDIT.model.variableManager:getVariable(data.id).name
        elseif data.orderTypeName then
            local orderType = SCEN_EDIT.metaModel.orderTypes[data.orderTypeName]
            local humanName = orderType.humanName
            for i = 1, #orderType.input do
                local input = orderType.input[i]
                humanName = humanName .. " " .. SCEN_EDIT.humanExpression(data[input.name], "value", nil, level + 1)
            end
            return humanName
        end
        return "nothing"
    elseif exprType == "numeric_comparison" then
        return SCEN_EDIT.metaModel.numericComparisonTypes[data.cmpTypeId]
    elseif exprType == "identity_comparison" then
        return SCEN_EDIT.metaModel.identityComparisonTypes[data.cmpTypeId]
	end	
    return data.humanName
    end)
    if success then
        return data
    else
        return "Err."
    end
end

function SCEN_EDIT.GenerateTeamColor()
    return 1, 1, 1, 1 --yeah, ain't it great
end

function SCEN_EDIT.GetTeams(widget)
    local teams = {}
    
    local gaiaTeamId = Spring.GetGaiaTeamID()
    for _, teamId in pairs(Spring.GetTeamList()) do
        local team = { id = teamId }
        table.insert(teams, team)

        team.name = tostring(team.id)

        local aiID, _, _, name = Spring.GetAIInfo(team.id)
        if aiID ~= nil then
            team.name = team.name .. ": " .. name
            team.ai = true -- TODO: maybe get the exact AI as well?
        end

        local r, g, b, a = SCEN_EDIT.GenerateTeamColor()--Spring.GetTeamColor(teamId)
        if widget then
            r, g, b, a = Spring.GetTeamColor(team.id)
        end
        team.color = { r = r, g = g, b = b, a = a }

        local _, _, _, _, side, allyTeam = Spring.GetTeamInfo(team.id)
        team.allyTeam = allyTeam
        team.side = side
        
        team.gaia = gaiaTeamId == team.id
        if team.gaia then
            team.ai = true
        end
		
		if not widget then
			local metal, metalMax = Spring.GetTeamResources(team.id, "metal")
			team.metal = metal
			team.metalMax = metalMax
			
			local energy, energyMax = Spring.GetTeamResources(team.id, "energy")
			team.energy = energy
			team.energyMax = energyMax
		end
    end
    return teams 
end

local function filterControls(ctrl)
    if ctrl.classname == "button" or ctrl.classname == "combobox" or ctrl.classname == "editbox" or ctrl.classname == "checkbox" or ctrl.classname == "label" or ctrl.classname == "editbox" then
        return {ctrl}
    end
    local childRets = {}
    for _, childCtrl in pairs(ctrl.childrenByName) do
        childRet = filterControls(childCtrl)
        if childRet ~= nil and type(childRet) == "table" then
            for _, v in pairs(childRet) do
                table.insert(childRets, v)
            end
        end
    end
    return childRets
end

local function hintCtrlFunction(ctrl, startTime, timeout, color)
    local deltaTime = os.clock() - startTime
    local newColor = SCEN_EDIT.deepcopy(color)
    newColor[4] = 0.2 + math.abs(math.sin(deltaTime * 6) / 3.14)
    
    if ctrl.classname == "label" or ctrl.classname == "checkbox" or ctrl.classname == "editbox" then
        ctrl.font.color = newColor
    else
        ctrl.backgroundColor = newColor
    end
    ctrl:Invalidate()
    SCEN_EDIT.delay(
        function()
            if os.clock() - startTime < timeout then
                hintCtrlFunction(ctrl, startTime, timeout, color)
            else
                if ctrl.classname == "label" or ctrl.classname == "checkbox" or ctrl.classname == "editbox" then
                    ctrl.font.color = ctrl._originalColor
                else
                    ctrl.backgroundColor = ctrl._originalColor
                end
                ctrl._originalColor = nil
                ctrl:Invalidate()
            end
        end
    )
end


function SCEN_EDIT.HintControl(control, color, timeout)
    timeout = timeout or 1
    color = color or {1, 0, 0, 1}
    local childControls = filterControls(control)
    local startTime = os.clock()
    for _, childControl in pairs(childControls) do
        if childControl._originalColor == nil then
            if childControl.classname == "label" or childControl.classname == "checkbox" or childControl.classname == "editbox" then
                childControl._originalColor = SCEN_EDIT.deepcopy(childControl.font.color)
            else
                childControl._originalColor = SCEN_EDIT.deepcopy(childControl.backgroundColor)
            end
            hintCtrlFunction(childControl, startTime, timeout, color)
        end
    end
end

function SCEN_EDIT.Error(msg)
    Spring.Echo(msg)
end

function SCEN_EDIT.SetClassName(class, className)
    class.className = className
    if SCEN_EDIT.commandManager:getCommandType(className) == nil then
        SCEN_EDIT.commandManager:addCommandType(className, class)
    end
end

function SCEN_EDIT.resolveCommand(cmdTable)
    local cmd = {}
    if cmdTable.className then
        local env = getfenv(1)
        cmd = env[cmdTable.className]()
    end
    for k, v in pairs(cmdTable) do
        if type(v) == "table" then
            cmd[k] = SCEN_EDIT.resolveCommand(v)
        else
            cmd[k] = v
        end
    end--[[
    if cmd.className == "CompoundCommand" then
        for i = 1, #cmd.commands do
            cmd.commands[i] = SCEN_EDIT.resolveCommand(cmd.commands[i])
        end
    end--]]
    return cmd
end

function SCEN_EDIT.deepcopy(t)
    if type(t) ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = SCEN_EDIT.deepcopy(v)
        end
        res[k] = v
    end
    setmetatable(res,mt)
    return res
end

function SCEN_EDIT.GiveOrderToUnit(unitId, orderType, params)
    Spring.GiveOrderToUnit(unit, CMD.INSERT,
        { -1, orderType, CMD.OPT_SHIFT, unpack(params) }, { "alt" })
end

function SCEN_EDIT.createNewPanel(input, ...)
    if input == "unit" then
        return UnitPanel(...)
    elseif input == "area" then
        return AreaPanel(...)
    elseif input == "trigger" then
        return TriggerPanel(...)
    elseif input == "unitType" then
        return UnitTypePanel(...)
    elseif input == "team" then
        return TeamPanel(...)
    elseif input == "number" then
        return NumberPanel(...)
    elseif input == "string" then
        return StringPanel(...)
    elseif input == "bool" then
        return BoolPanel(...)
    elseif input == "numericComparison" then
        return NumericComparisonPanel(...)
    elseif input == "order" then
        return OrderPanel(...)
    elseif input == "identityComparison" then
        return IdentityComparisonPanel(...)
    elseif input == "position" then
        return PositionPanel(...)
    elseif input:find("_array") then
        return GenericArrayPanel(input, ...)
    end
    Spring.Echo("No panel for this input: " .. tostring(input))
end

SCEN_EDIT.delayedGL = {}
function SCEN_EDIT.delayGL(func, params)
    table.insert(SCEN_EDIT.delayedGL, {func, params or {}})
end

function SCEN_EDIT.executeDelayedGL()
    local delayedGL = SCEN_EDIT.delayedGL
    SCEN_EDIT.delayedGL = {}
    for i, call in pairs(delayedGL) do
        success, msg = pcall(call[1], unpack(call[2]))
        if not success then
            Spring.Echo(msg)
        end
    end
end

SCEN_EDIT.delayed = {}
function SCEN_EDIT.delay(func, params)
    table.insert(SCEN_EDIT.delayed, {func, params or {}})
end

function SCEN_EDIT.executeDelayed()
    local delayed = SCEN_EDIT.delayed
    SCEN_EDIT.delayed = {}
    for i, call in pairs(delayed) do
        success, msg = pcall(call[1], unpack(call[2]))
        if not success then
            Spring.Echo(msg)
        end
    end
end

function SCEN_EDIT.glToFontColor(color)
    return "\255" ..
        string.char(math.ceil(255 * color.r)) .. 
        string.char(math.ceil(255 * color.g)) .. 
        string.char(math.ceil(255 * color.b))
end

function SCEN_EDIT.SetControlEnabled(control, enabled)
    control.disableChildrenHitTest = not enabled
    control:Invalidate()
    for _, childCtrl in pairs(control.childrenByName) do
        SCEN_EDIT.SetControlEnabled(childCtrl, enabled)
    end
end

function SCEN_EDIT.DirExists(path, ...)
    return (#VFS.SubDirs(path, "*", ...) + #VFS.DirList(path, "*", ...)) ~= 0
end

local warningsIssued = {}

function SCEN_EDIT.MinVersion(versionNumber, feature)
    if Script.IsEngineMinVersion == nil or not Script.IsEngineMinVersion(versionNumber) then
        if warningsIssued[feature] == nil then
            Spring.Echo(feature .. " requires a minimum Spring version of " .. tostring(versionNumber))
            warningsIssued[feature] = true
        end
        return false
    end
    return true
end

function SCEN_EDIT.FunctionExists(fun, feature)
    if fun ~= nil then
        if warningsIssued[feature] == nil then
            Spring.Echo(feature .. " requires a minimum Spring version of " .. tostring(versionNumber))
            warningsIssued[feature] = true
        end
        return false
    end
    return true
end

function boolToNumber(bool)
    if bool then
        return 1
    else
        return 0
    end
end
