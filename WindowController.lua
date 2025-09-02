-- References
local ReplicatedStorage = game.ReplicatedStorage
local Assets = ReplicatedStorage.Assets

-- Audio
local PaperSound = game.SoundService.SFX.Paper

local WindowController = {}
WindowController.__index = WindowController


function WindowController.new(Title: string, WindowSize: UDim2, WindowContent: {}, Draggable: boolean)
	local BaseWindow: Frame = Assets.UI.WindowBaseFrame:Clone()
	BaseWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	BaseWindow.Size = WindowSize
	
	local self = setmetatable({}, WindowController)
	self.Title = Title
	self.BaseFrame = BaseWindow
	self.Content = {}
	self.Size = WindowSize
	self.Draggable = Draggable
	self.Dragging = false
	self.Connections = {}
	
	for _, Content in WindowContent do
		local NewContent = Content:Clone()
		NewContent.Parent = BaseWindow.Content
		self.Content[Content.Name] = NewContent
	end
	
	self.BaseFrame.Name = Title
	self:SetDraggable(Draggable)
	
	return self
end

function WindowController:SetDraggable(Value: boolean)
	self.Draggable = Value
	
	if Value then
		if not self.Connections.Drag then
			local RunService = game:GetService("RunService")
			
			local BaseFrame: Frame = self.BaseFrame
			
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local PositionOffset = Vector2.new()
			
			self.Connections.StartDragging = BaseFrame.TopBar.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.Dragging = true
					PositionOffset = Vector2.new(Mouse.X, Mouse.Y) - (BaseFrame.AbsolutePosition + BaseFrame.AbsoluteSize / 2)
				end
			end)
			
			self.Connections.StopDragging = BaseFrame.TopBar.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.Dragging = false
				end
			end)
			
			self.Connections.UpdateDragging = RunService.RenderStepped:Connect(function()
				if self.Dragging then
					local UpdatedPosition = Vector2.new(Mouse.X, Mouse.Y) - PositionOffset
					
					self.BaseFrame.Position = UDim2.fromOffset(UpdatedPosition.X, UpdatedPosition.Y)
				end
			end)
		end
	else
		if self.Connections.StartDragging then
			self.Connections.StartDragging:Disconnect()
			self.Connections.StopDragging:Disconnect()
			self.Connections.UpdateDragging:Disconnect()
		end
	end
end

function WindowController:Minimize()
	self.BaseFrame.Content.Visible = self.Minimized
	self.BaseFrame.TopBar.Buttons.Minimize.Text = self.Minimized and "^" or "v"
	self.Minimized = not self.Minimized
	
	PaperSound:Play()
end

function WindowController:Open(Windows: ScreenGui)
	self.BaseFrame.Parent = Windows
	
	local TopBar = self.BaseFrame.TopBar
	
	TopBar.Title.TextLabel.Text = self.Title
	
	self.Connections.Minimize = TopBar.Buttons.Minimize.MouseButton1Click:Connect(function()
		self:Minimize()
	end)

	self.Connections.Close = TopBar.Buttons.Close.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	PaperSound:Play()
end

function WindowController:Close()
	for _, Connection in self.Connections do
		if Connection then
			Connection:Disconnect()
		end
	end
	self.BaseFrame:Destroy()
	table.clear(self)
end

return WindowController
