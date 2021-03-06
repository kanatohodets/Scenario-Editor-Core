MoveUnitCommand = AbstractCommand:extends{}
MoveUnitCommand.className = "MoveUnitCommand"

function MoveUnitCommand:init(modelUnitId, newX, newY, newZ)
    self.className = "MoveUnitCommand"
    self.modelUnitId = modelUnitId
    self.newX = newX
    self.newY = newY
    self.newZ = newZ
end

function MoveUnitCommand:execute()
    local unitId = SCEN_EDIT.model.unitManager:getSpringUnitId(self.modelUnitId)
    local unitX, unitY, unitZ = Spring.GetUnitPosition(unitId)
    self.oldX = unitX
    self.oldY = unitY
    self.oldZ = unitZ

    --FIXME: hack needed to set proper unit direction for buildings
    local dirX, dirY, dirZ = Spring.GetUnitDirection(unitId)

    Spring.SetUnitPosition(unitId, self.newX, self.newY, self.newZ)
    -- FIXME: hack needed to set proper unit direction for buildings
    Spring.SetUnitDirection(unitId, dirX, dirY, dirZ)
end

function MoveUnitCommand:unexecute()
    local unitId = SCEN_EDIT.model.unitManager:getSpringUnitId(self.modelUnitId)
    --FIXME: hack needed to set proper unit direction for buildings
    local dirX, dirY, dirZ = Spring.GetUnitDirection(unitId)
    Spring.SetUnitPosition(unitId, self.oldX, self.oldY, self.oldZ)
    -- FIXME: hack needed to set proper unit direction for buildings
    Spring.SetUnitDirection(unitId, dirX, dirY, dirZ)
end

function MoveUnitCommand:display()
    return "Moved unit: " .. tostring(UnitDefs[Spring.GetUnitDefID(SCEN_EDIT.model.unitManager:getSpringUnitId(self.modelUnitId))].name)
end