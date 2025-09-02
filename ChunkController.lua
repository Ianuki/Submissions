local Chunk = {}
Chunk.__index = Chunk

local Errors = require(game.ReplicatedStorage.Modules.Shared.Errors)
local MathEssentials = require(game.ReplicatedStorage.Modules.Shared.MathEssentials)
local Settings = require(game.ServerScriptService.Modules.WorldGeneration.Settings)
local PerlinNoise = require(game.ServerScriptService.Modules.WorldGeneration.PerlinNoise)
local Biomes = require(game.ServerScriptService.Modules.WorldGeneration.Biomes)

function Chunk.new(GridPosition : Vector2, BiomeBias : number)
	local BasePart = Instance.new("Part") do
		BasePart.Anchored = true
		BasePart.Name = "BasePart"
	end
	
	local self = {
		["GridPosition"] = GridPosition,
		["WorldPosition"] = nil,
		["Biome"] = nil,
		["BiomeBias"] = BiomeBias,
		["BasePart"] = BasePart,
		["Model"] = Instance.new("Model")
	}
	
	return setmetatable(self, Chunk)
end

function Chunk:GetBiome()
	if self.BiomeBias > -0.2 then
		self.Biome = "Plains"
	else
		self.Biome = "Desert"
	end
	
	return self.Biome
end

function Chunk:UpdateWorldPosition()
	local BiomeData = Biomes[self.Biome]
	if not BiomeData then return error(Errors.BAD_ARGUMENT:format(self.Biome, "Biome")) end
	
	local Amplitude = BiomeData["Amplitude"]
	PerlinNoise.setAmplitude(Amplitude)
	
	self.WorldPosition = Vector3.new(
		self.GridPosition.X * Settings.CHUNK_SIZE, 
		PerlinNoise.get(self.GridPosition.X, self.GridPosition.Y) * (self.BiomeBias + 1) / 2, 
		self.GridPosition.Y * Settings.CHUNK_SIZE
	)
end

function Chunk:Render(ChunkFolder : Folder)
	local BiomeData = Biomes[self.Biome]
	if not BiomeData then return error(Errors.BAD_ARGUMENT:format(self.Biome, "Biome")) end
	
	self.BasePart.Position = self.WorldPosition:Lerp(
		Vector3.new(
			self.WorldPosition.X, 
			Settings.BASE_LEVEL, 
			self.WorldPosition.Z
		), 
		0.5
	)
	self.BasePart.Size = Vector3.new(
		Settings.CHUNK_SIZE, 
		self.WorldPosition.Y - Settings.BASE_LEVEL, 
		Settings.CHUNK_SIZE
	)
	self.BasePart.Color = BiomeData.Color
	self.BasePart.Parent = self.Model
	self.Model.Parent = ChunkFolder
end

function Chunk:Destroy()
	self.BasePart:Destroy()
	self = nil
end

return Chunk
