local MaidUtil = require(game.ReplicatedStorage.Modules.Utilities.Maid)
local RemoteWrapper = require(game.ReplicatedStorage.Modules.Utilities.RemoteWrapper)
local Pooler = require(game.ReplicatedStorage.Modules.Utilities.Packages.PoolerPlus)
local Enums = require(game.ReplicatedStorage.Modules.Values.Enums)
local Colors = require(game.ReplicatedStorage.Modules.Values.Colors)

local MAX_HEALTH = 100
local MIN_HEALTH = 0

local Assets = game.ReplicatedStorage.Assets
local UnitModel = Assets.Unit

local UnitModelPool = Pooler:CreatePool("UnitModels", function()
	return UnitModel:Clone()
end)

local Unit = {}
Unit.__index = Unit

export type Unit = {
	__index: Unit,

	_Maid: MaidUtil.Maid,
	_Owner: Player,
	_Model: Model,
	_ClickDetector: ClickDetector,
	_CanMove: boolean,
	
	ID: number,
	Name: string,
	Occupation: number,
	MaestryLevel: number,
	Dead: boolean,
	Health: number,
	
	new: (Name: string, ID: number) -> (Unit),
	GetPivot: (self: Unit) -> (CFrame),
	Destroy: (self: Unit) -> (Unit),
	StartMoving: (self: Unit) -> (Unit),
	StopMoving: (self: Unit) -> (Unit),
	SetOccupation: (self: Unit, Occupation: string) -> (Unit),
	PivotTo: (self: Unit, CFrame: CFrame) -> (Unit),
	MoveTo: (self: Unit, Position: Vector3) -> (Unit),
	Serialize: (self: Unit) -> (SerializedUnit),
	SetOwnership: (self: Unit, Owner: Player) -> (Unit)
}

function Unit.new(Owner: Player, Name: string, ID: number): Unit
	local self = {} :: Unit
	self._Maid = MaidUtil.new()
	self._Model = UnitModelPool:Get() :: Model
	self._MainPart = self._Model:FindFirstChild("MainPart")
	self._CanMove = true
	self._Owner = Owner
	self.ID = ID or -1
	self.MaestryLevel = 0
	self.Name = Name
	self.Occupation = "Unemployed"
	self.Health = MAX_HEALTH
	self.Dead = false

	return setmetatable(self, Unit)
end

type SerializedUnit = {
	Type: string, 
	Data: {
		ID: number, 
		Name: string, 
		Occupation: string, 
		MaestryLevel: number
	}
}

function Unit.Serialize(self: Unit): SerializedUnit
	return {
		["Type"] = "Unit",
		["Data"] = {
			["ID"] = self.ID,
			["Name"] = self.Name,
			["Occupation"] = self.Occupation,
			["MaestryLevel"] = self.MaestryLevel,
			["Dead"] = self.Dead
		}
	}
end

function Unit.Spawn(self: Unit)
	self._Model.Parent = workspace.Units
	self._Model.Name = self.ID
	
	RemoteWrapper.fireClient(self._Owner, "UNIT_UPDATE", self:Serialize())
end

function Unit.SetOccupation(self: Unit, Occupation: string): Unit
	local TorsoColor = Colors.Occupations[Occupation] or Colors.Occupations.Unemployed
	
	self.Occupation = Occupation
	self._Model.Model.Torso.Color = TorsoColor
	
	return self
end

function Unit.GetPivot(self: Unit): CFrame
	return self._Model:GetPivot()
end

function Unit.PivotTo(self: Unit, CFrame: CFrame): Unit
	self._Model:PivotTo(CFrame)
	
	return Unit
end

function Unit.MoveTo(self: Unit, Position: Vector3): Unit
	if not self._CanMove then return end
	
	local Humanoid: Humanoid = self._Model.Model:FindFirstChild("Humanoid")
	if not Humanoid then return end
	
	Humanoid:MoveTo(Position)
	
	return self
end

function Unit.StopMoving(self: Unit): Unit
	self:MoveTo(self:GetPivot().Position)
	self._CanMove = false
	
	return self
end

function Unit.StartMoving(self: Unit): Unit
	self._CanMove = true
	
	return self
end

function Unit.SetOwnership(self: Unit, Owner: Player): Unit
	self._Owner = Owner
	
	return self
end

function Unit.Destroy(self: Unit): ()
	self.Dead = true
	print("====== DEAD SERIALIZE ======")
	print(self:Serialize())
	RemoteWrapper.fireClient(self._Owner, "UNIT_UPDATE", self:Serialize())
	
	self._Maid:Destroy()
	self._Model:Destroy()
	table.clear(self :: any)
	setmetatable(self, nil)
	self = nil
end

return Unit	
