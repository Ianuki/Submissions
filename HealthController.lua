-- Remotes
local Replicate = game.ReplicatedStorage.Remotes.Replicate

local HealthController = {}
HealthController.__index = HealthController

function HealthController.new(Player)
	local self = {
		Parts = {
			Head = {
				Health = 100,
				DamageMultiplier = 5
			},
			
			Torso = {
				Health = 100,
				DamageMultiplier = 5
			},
			
			LeftArm = {
				Health = 100,
				DamageMultiplier = 5
			},
			
			RightArm = {
				Health = 100,
				DamageMultiplier = 5
			},
			
			LeftLeg = {
				Health = 100,
				DamageMultiplier = 5
			},
			
			RightLeg = {
				Health = 100,
				DamageMultiplier = 5
			}
		}
	}
	
	self.Player = Player
	self.MinHealth = 0
	self.MaxHealth = 100
	
	return setmetatable(self, HealthController)
end

function HealthController:RestoreHealth()
	for _, V in self.Parts do
		V.Health = self.MaxHealth
	end
	
	self:UpdateAndReplicate()
end

function HealthController:TakeDamage(Part: string, Damage: number)
	if Part == "All" then
		for _, V in self.Parts do
			V.Health = math.clamp(V.Health - Damage * V.DamageMultiplier, self.MinHealth, self.MaxHealth)
		end
	else
		if not self.Parts[Part] then return end
		self.Parts[Part].Health = math.clamp(self.Parts[Part].Health - Damage * self.Parts[Part].DamageMultiplier, self.MinHealth, self.MaxHealth)
	end
	
	self:UpdateAndReplicate()
end

function HealthController:Heal(Part: string, Value: number)
	self:TakeDamage(Part, -Value)
end

function HealthController:GetOverallHealth()
	local OverallHealth = 0
	
	for _, V in self.Parts do
		OverallHealth += V.Health
	end
	
	OverallHealth /= 6
	
	return OverallHealth
end

function HealthController:GetHealth(Part: string)
	if self.Parts[Part] then
		return self.Parts[Part].Health
	else
		return nil
	end
end

function HealthController:UpdateAndReplicate()
	local Character = self.Player.Character or self.Player.CharacterAdded:Wait()
	local Humanoid = Character:FindFirstChild("Humanoid")

	local OverallLegHealth = (self.Parts.LeftLeg.Health + self.Parts.RightLeg.Health) / 2
	if OverallLegHealth < 50 then
		Humanoid.WalkSpeed = math.lerp(4, 16, OverallLegHealth / 50)
	else
		Humanoid.WalkSpeed = 16
	end

	local OverallHealth = self:GetOverallHealth()
	Replicate:FireClient(self.Player, "HealthUpdate", self.Parts, OverallHealth)
end

function HealthController:Destroy()
	print("Health controller destroyed.")
end

return HealthController
