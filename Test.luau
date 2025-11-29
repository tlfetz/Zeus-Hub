--[[
	ZeusLib - Modern UI Library for Roblox
	Version: 2.0.0
	Features: Mobile Support, Drag System, Multiple Elements
	Compatible with: Desktop & Mobile
]]

local ZeusLib = {}
ZeusLib.Windows = {}

-- Platform Detection
local UserInputService = game:GetService("UserInputService")
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local IsDesktop = UserInputService.MouseEnabled

-- Theme Configuration
local Theme = {
	Background = Color3.fromRGB(7, 7, 7),
	Surface = Color3.fromRGB(15, 15, 15),
	SurfaceVariant = Color3.fromRGB(20, 20, 20),
	SurfaceHover = Color3.fromRGB(25, 25, 25),
	SurfaceActive = Color3.fromRGB(30, 30, 30),
	Border = Color3.fromRGB(25, 25, 25),
	BorderAccent = Color3.fromRGB(116, 116, 116),
	Primary = Color3.fromRGB(230, 230, 230),
	Success = Color3.fromRGB(76, 175, 80),
	Warning = Color3.fromRGB(255, 152, 0),
	Error = Color3.fromRGB(244, 67, 54),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(150, 150, 150),
	TextMuted = Color3.fromRGB(100, 100, 100)
}

local Timing = {
	Fast = 0.1,
	Normal = 0.2,
	Slow = 0.3,
	WindowOpen = 0.5
}

local Sizes = {
	WindowWidth = 652,
	WindowHeight = 400,
	TabHeight = 35,
	ElementHeight = 42,
	CornerRadius = UDim.new(0.02, 0),
	Spacing = 8,
	MinTouchSize = 44 -- Minimum touch target size for mobile
}

-- Service Cache
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Utility Functions
local function New(ClassName, Properties)
	local Object = Instance.new(ClassName)
	if Properties then 
		for Property, Value in next, Properties do
			pcall(function()
				Object[Property] = Value
			end)
		end 
	end
	return Object
end

local function CreateTween(object, duration, properties, style, direction)
	if not object or not object.Parent then return end
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	local tween = TweenService:Create(object, TweenInfo.new(duration, style, direction), properties)
	tween:Play()
	return tween
end

local function SafeCallback(callback, ...)
	if callback then
		local success, err = pcall(callback, ...)
		if not success then
			warn("ZeusLib Callback Error:", err)
		end
	end
end

-- Universal Input Handler (Mouse + Touch)
local function CreateInputHandler(element, callbacks)
	local connections = {}
	local pressing = false
	local hovering = false
	
	-- Mouse Support (Desktop)
	if IsDesktop then
		table.insert(connections, element.MouseEnter:Connect(function()
			hovering = true
			if callbacks.OnHoverStart then
				callbacks.OnHoverStart()
			end
		end))
		
		table.insert(connections, element.MouseLeave:Connect(function()
			hovering = false
			if callbacks.OnHoverEnd then
				callbacks.OnHoverEnd()
			end
		end))
		
		table.insert(connections, element.MouseButton1Down:Connect(function()
			pressing = true
			if callbacks.OnPressStart then
				callbacks.OnPressStart()
			end
		end))
		
		table.insert(connections, element.MouseButton1Up:Connect(function()
			if pressing then
				pressing = false
				if callbacks.OnPressEnd then
					callbacks.OnPressEnd()
				end
				if hovering and callbacks.OnClick then
					callbacks.OnClick()
				end
			end
		end))
	end
	
	-- Touch Support (Mobile)
		table.insert(connections, element.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				pressing = true
				if callbacks.OnPressStart then
					callbacks.OnPressStart()
				end
			end
		end))
		
		table.insert(connections, element.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch and pressing then
				pressing = false
				if callbacks.OnPressEnd then
					callbacks.OnPressEnd()
				end
				if callbacks.OnClick then
					callbacks.OnClick()
				end
			end
		end))
	end
	
	return connections
end

-- Drag System (Universal)
local function CreateDragSystem(element, dragHandle)
	dragHandle = dragHandle or element
	local connections = {}
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil
	local dragTween = nil
	
	-- Get screen boundaries
	local function getScreenBounds()
		local screenSize = workspace.CurrentCamera.ViewportSize
		return screenSize
	end
	
	-- Clamp position to screen
	local function clampToScreen(position)
		local screenSize = getScreenBounds()
		local elementSize = element.AbsoluteSize
		
		local minX = elementSize.X / 2
		local maxX = screenSize.X - elementSize.X / 2
		local minY = elementSize.Y / 2
		local maxY = screenSize.Y - elementSize.Y / 2
		
		local clampedX = math.clamp(position.X.Offset, minX, maxX)
		local clampedY = math.clamp(position.Y.Offset, minY, maxY)
		
		return UDim2.new(position.X.Scale, clampedX, position.Y.Scale, clampedY)
	end
	
	-- Start dragging
	local function startDrag(input)
		dragging = true
		dragStart = input.Position
		startPos = element.Position
		
		if dragTween then
			dragTween:Cancel()
		end
	end
	
	-- Update drag position
	local function updateDrag(input)
		if not dragging then return end
		
		local delta = input.Position - dragStart
		local newPosition = UDim2.new(
			startPos.X.Scale, 
			startPos.X.Offset + delta.X, 
			startPos.Y.Scale, 
			startPos.Y.Offset + delta.Y
		)
		
		newPosition = clampToScreen(newPosition)
		
		if dragTween then
			dragTween:Cancel()
		end
		
		dragTween = CreateTween(element, Timing.Fast, {Position = newPosition})
	end
	
	-- End dragging
	local function endDrag()
		dragging = false
		dragInput = nil
	end
	
	-- Mouse Support
	if IsDesktop then
		table.insert(connections, dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				startDrag(input)
			end
		end))
		
		table.insert(connections, dragHandle.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				dragInput = input
			end
		end))
		
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				updateDrag(input)
			end
		end))
		
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				endDrag()
			end
		end))
	end
	
	-- Touch Support
		local touchInput = nil
		
		table.insert(connections, dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				touchInput = input
				startDrag(input)
			end
		end))
		
		table.insert(connections, dragHandle.InputChanged:Connect(function(input)
			if input == touchInput and dragging then
				updateDrag(input)
			end
		end))
		
		table.insert(connections, dragHandle.InputEnded:Connect(function(input)
			if input == touchInput then
				endDrag()
			end
		end))
	end
	
	return connections
end

-- Window Creation
function ZeusLib:CreateWindow(title, subtitle)
	local Window = {}
	local windowIndex = #ZeusLib.Windows + 1
	local connections = {}
	local elementCache = {}

	title = title or "ZeusLib"
	subtitle = subtitle or "Modern UI Library"

	local ZeusUI = New("ScreenGui", {
		Name = "ZeusUI_" .. windowIndex,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true
	})

	local Background = New("Frame", {
		Name = "Background",
		Parent = ZeusUI,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0.5 + (windowIndex - 1) * 0.05, 0, 0.45, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	})

	New("UICorner", {
		CornerRadius = Sizes.CornerRadius,
		Parent = Background
	})

	local BackgroundStroke = New("UIStroke", {
		Color = Theme.Border,
		Thickness = 1,
		Transparency = 1,
		Parent = Background
	})

	-- Window Opening Animation
	CreateTween(Background, Timing.WindowOpen, {
		Size = UDim2.new(0, Sizes.WindowWidth, 0, Sizes.WindowHeight),
		BackgroundTransparency = 0
	}, Enum.EasingStyle.Back)

	task.wait(Timing.Slow)
	CreateTween(BackgroundStroke, Timing.Slow, {Transparency = 0})

	-- Title Bar (Drag Handle)
	local TitleBar = New("Frame", {
		Name = "TitleBar",
		Parent = Background,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 50),
		Active = true
	})

	-- Title Elements
	New("TextLabel", {
		Name = "title",
		Parent = TitleBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.03, 0, 0.2, 0),
		Size = UDim2.new(0.8, 0, 0, 21),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	New("TextLabel", {
		Name = "subtitle",
		Parent = TitleBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.03, 0, 0.55, 0),
		Size = UDim2.new(0.8, 0, 0, 21),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Theme.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- Close Button
	local CloseButton = New("TextButton", {
		Name = "CloseButton",
		Parent = TitleBar,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Error,
		BackgroundTransparency = 0.9,
		Position = UDim2.new(0.97, 0, 0.25, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Theme.TextPrimary,
		TextSize = 18,
		AutoButtonColor = false
	})

	New("UICorner", {
		CornerRadius = UDim.new(0.2, 0),
		Parent = CloseButton
	})

	local closeConnections = CreateInputHandler(CloseButton, {
		OnHoverStart = function()
			CreateTween(CloseButton, Timing.Fast, {BackgroundTransparency = 0.7})
		end,
		OnHoverEnd = function()
			CreateTween(CloseButton, Timing.Fast, {BackgroundTransparency = 0.9})
		end,
		OnPressStart = function()
			CreateTween(CloseButton, Timing.Fast, {BackgroundTransparency = 0.5})
		end,
		OnPressEnd = function()
			CreateTween(CloseButton, Timing.Fast, {BackgroundTransparency = 0.9})
		end,
		OnClick = function()
			Window:Toggle()
		end
	})

	for _, conn in pairs(closeConnections) do
		table.insert(connections, conn)
	end

	-- Drag System
	local dragConnections = CreateDragSystem(Background, TitleBar)
	for _, conn in pairs(dragConnections) do
		table.insert(connections, conn)
	end

	-- Content Background
	local ContentBackground = New("Frame", {
		Parent = Background,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(0.238, 0, 0.115, 0),
		Size = UDim2.new(0, 497, 0, 354)
	})

	New("UICorner", {
		CornerRadius = UDim.new(0.01, 0),
		Parent = ContentBackground
	})

	New("UIStroke", {
		Color = Theme.Border,
		Thickness = 1,
		Parent = ContentBackground
	})

	-- Tab Container
	local TabContainer = New("ScrollingFrame", {
		Name = "TabContainer",
		Parent = Background,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.019, 0, 0.141, 0),
		Size = UDim2.new(0, 135, 0, 324),
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		
	})

	local TabLayout = New("UIListLayout", {
		Parent = TabContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Sizes.Spacing),
		FillDirection = IsMobile and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	})

	table.insert(connections, TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			
		
			TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 20)
		end
	end))

	-- Content Container
	local ContentContainer = New("ScrollingFrame", {
		Name = "ContentContainer",
		Parent = Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.237, 0, 0.116, 0),
		Size = UDim2.new(0.763, 0, 0.884, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.BorderAccent
	})

	New("UIPadding", {
		Parent = ContentContainer,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10)
	})

	local ContentLayout = New("UIListLayout", {
		Parent = ContentContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Sizes.Spacing)
	})

	table.insert(connections, ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ContentContainer.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
	end))

	Window.Tabs = {}
	Window.CurrentTab = nil
	Window.Visible = true

	-- Tab Creation
	function Window:CreateTab(name)
		local Tab = {}
		local isFirstTab = #Window.Tabs == 0
		name = name or "New Tab"

		local TabButton = New("TextButton", {
			Name = "Tab_" .. name,
			Parent = TabContainer,
			BackgroundColor3 = Theme.Surface,
			BackgroundTransparency = isFirstTab and 0 or 1,
			BorderSizePixel = 0,
			Size = UDim2.new(0.983, 0, 0, Sizes.TabHeight),
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextColor3 = isFirstTab and Theme.TextPrimary or Theme.TextSecondary,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			AutoButtonColor = false
		})

		New("UIPadding", {
			Parent = TabButton,
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5)
		})

		New("UICorner", {
			CornerRadius = UDim.new(0.1, 0),
			Parent = TabButton
		})

		local TabStroke = New("UIStroke", {
			Color = Theme.BorderAccent,
			Thickness = 1,
			Transparency = isFirstTab and 0.8 or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = TabButton
		})

		-- Tab Input Handler
		local tabConnections = CreateInputHandler(TabButton, {
			OnHoverStart = function()
				if Window.CurrentTab ~= Tab then
					CreateTween(TabButton, Timing.Fast, {BackgroundTransparency = 0.5})
				end
			end,
			OnHoverEnd = function()
				if Window.CurrentTab ~= Tab then
					CreateTween(TabButton, Timing.Fast, {BackgroundTransparency = 1})
				end
			end,
			OnClick = function()
				if Window.CurrentTab == Tab then return end

				for _, tab in pairs(Window.Tabs) do
					CreateTween(tab.Button, Timing.Normal, {
						BackgroundTransparency = 1,
						TextColor3 = Theme.TextSecondary
					})

					local stroke = tab.Button:FindFirstChildOfClass("UIStroke")
					if stroke then
						CreateTween(stroke, Timing.Normal, {Transparency = 1})
					end
				end

				CreateTween(TabButton, Timing.Normal, {
					BackgroundTransparency = 0,
					TextColor3 = Theme.TextPrimary
				})

				CreateTween(TabStroke, Timing.Normal, {Transparency = 0.8})

				Window.CurrentTab = Tab
				Window:RefreshContent()
			end
		})

		for _, conn in pairs(tabConnections) do
			table.insert(connections, conn)
		end

		Tab.Button = TabButton
		Tab.Elements = {}
		Tab.Connections = {}

		table.insert(Window.Tabs, Tab)

		if isFirstTab then
			Window.CurrentTab = Tab
			Window:RefreshContent()
		end

		-- Element Creation Methods
		function Tab:AddParagraph(titleText, contentText)
			titleText = titleText or "Paragraph"
			contentText = contentText or ""

			local Paragraph = {
				Type = "Paragraph",
				Title = titleText,
				Content = contentText,
				Visible = true
			}

			table.insert(Tab.Elements, Paragraph)
			Window:RefreshContent()

			return {
				SetTitle = function(_, newTitle)
					Paragraph.Title = newTitle or Paragraph.Title
					Window:RefreshContent()
				end,
				SetContent = function(_, newContent)
					Paragraph.Content = newContent or Paragraph.Content
					Window:RefreshContent()
				end,
				Hide = function()
					Paragraph.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Paragraph.Visible = true
					Window:RefreshContent()
				end
			}
		end

		function Tab:AddButton(text, callback)
			text = text or "Button"

			local Button = {
				Type = "Button",
				Text = text,
				Callback = callback,
				Visible = true,
				Enabled = true
			}

			table.insert(Tab.Elements, Button)
			Window:RefreshContent()

			return {
				SetText = function(_, newText)
					Button.Text = newText or Button.Text
					Window:RefreshContent()
				end,
				SetCallback = function(_, newCallback)
					Button.Callback = newCallback
				end,
				SetEnabled = function(_, enabled)
					Button.Enabled = enabled
					Window:RefreshContent()
				end,
				Hide = function()
					Button.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Button.Visible = true
					Window:RefreshContent()
				end
			}
		end

		function Tab:AddToggle(text, default, callback)
			text = text or "Toggle"
			default = default or false

			local Toggle = {
				Type = "Toggle",
				Text = text,
				Value = default,
				Callback = callback,
				Visible = true,
				Enabled = true
			}

			table.insert(Tab.Elements, Toggle)
			Window:RefreshContent()

			return {
				Set = function(_, value)
					Toggle.Value = value
					Window:RefreshContent()
					SafeCallback(Toggle.Callback, value)
				end,
				SetText = function(_, newText)
					Toggle.Text = newText or Toggle.Text
					Window:RefreshContent()
				end,
				SetEnabled = function(_, enabled)
					Toggle.Enabled = enabled
					Window:RefreshContent()
				end,
				Hide = function()
					Toggle.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Toggle.Visible = true
					Window:RefreshContent()
				end,
				GetValue = function()
					return Toggle.Value
				end
			}
		end

		function Tab:AddSlider(text, min, max, default, callback)
			text = text or "Slider"
			min = min or 0
			max = max or 100
			default = math.clamp(default or min, min, max)

			local Slider = {
				Type = "Slider",
				Text = text,
				Min = min,
				Max = max,
				Value = default,
				Callback = callback,
				Visible = true,
				Enabled = true
			}

			table.insert(Tab.Elements, Slider)
			Window:RefreshContent()

			return {
				Set = function(_, value)
					Slider.Value = math.clamp(value, Slider.Min, Slider.Max)
					Window:RefreshContent()
					SafeCallback(Slider.Callback, Slider.Value)
				end,
				SetText = function(_, newText)
					Slider.Text = newText or Slider.Text
					Window:RefreshContent()
				end,
				SetEnabled = function(_, enabled)
					Slider.Enabled = enabled
					Window:RefreshContent()
				end,
				Hide = function()
					Slider.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Slider.Visible = true
					Window:RefreshContent()
				end,
				GetValue = function()
					return Slider.Value
				end
			}
		end

		function Tab:AddInput(text, placeholder, callback)
			text = text or "Input"
			placeholder = placeholder or "Enter text..."

			local Input = {
				Type = "Input",
				Text = text,
				Placeholder = placeholder,
				Value = "",
				Callback = callback,
				Visible = true,
				Enabled = true
			}

			table.insert(Tab.Elements, Input)
			Window:RefreshContent()

			return {
				Set = function(_, value)
					Input.Value = tostring(value)
					Window:RefreshContent()
				end,
				SetText = function(_, newText)
					Input.Text = newText or Input.Text
					Window:RefreshContent()
				end,
				SetPlaceholder = function(_, newPlaceholder)
					Input.Placeholder = newPlaceholder or Input.Placeholder
					Window:RefreshContent()
				end,
				SetEnabled = function(_, enabled)
					Input.Enabled = enabled
					Window:RefreshContent()
				end,
				Hide = function()
					Input.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Input.Visible = true
					Window:RefreshContent()
				end,
				GetValue = function()
					return Input.Value
				end
			}
		end

		function Tab:AddDropdown(text, options, default, callback)
			text = text or "Dropdown"
			options = options or {"Option 1", "Option 2", "Option 3"}
			default = default or options[1]

			local Dropdown = {
				Type = "Dropdown",
				Text = text,
				Options = options,
				Value = default,
				Callback = callback,
				Visible = true,
				Enabled = true,
				Open = false
			}

			table.insert(Tab.Elements, Dropdown)
			Window:RefreshContent()

			return {
				Set = function(_, value)
					Dropdown.Value = value
					Window:RefreshContent()
					SafeCallback(Dropdown.Callback, value)
				end,
				SetText = function(_, newText)
					Dropdown.Text = newText or Dropdown.Text
					Window:RefreshContent()
				end,
				SetOptions = function(_, newOptions)
					Dropdown.Options = newOptions or Dropdown.Options
					if not table.find(Dropdown.Options, Dropdown.Value) then
						Dropdown.Value = Dropdown.Options[1]
					end
					Window:RefreshContent()
				end,
				SetEnabled = function(_, enabled)
					Dropdown.Enabled = enabled
					Window:RefreshContent()
				end,
				Hide = function()
					Dropdown.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Dropdown.Visible = true
					Window:RefreshContent()
				end,
				GetValue = function()
					return Dropdown.Value
				end
			}
		end

		function Tab:AddDivider(text)
			local Divider = {
				Type = "Divider",
				Text = text or "",
				Visible = true
			}

			table.insert(Tab.Elements, Divider)
			Window:RefreshContent()

			return {
				SetText = function(_, newText)
					Divider.Text = newText or ""
					Window:RefreshContent()
				end,
				Hide = function()
					Divider.Visible = false
					Window:RefreshContent()
				end,
				Show = function()
					Divider.Visible = true
					Window:RefreshContent()
				end
			}
		end

		return Tab
	end

	-- Content Refresh (Optimized)
	function Window:RefreshContent()
		if not Window.CurrentTab then return end

		-- Clear old connections for current tab elements
		for _, conn in pairs(Window.CurrentTab.Connections or {}) do
			if conn and conn.Disconnect then
				conn:Disconnect()
			end
		end
		Window.CurrentTab.Connections = {}

		-- Remove old elements
		for _, child in pairs(ContentContainer:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then
				child:Destroy()
			end
		end

		-- Create elements
		for _, element in pairs(Window.CurrentTab.Elements) do
			if not element.Visible then continue end

			if element.Type == "Paragraph" then
				local Paragraph = New("Frame", {
					Name = "Paragraph",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 100)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.05, 0),
					Parent = Paragraph
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = Paragraph
				})

				New("UIPadding", {
					Parent = Paragraph,
					PaddingBottom = UDim.new(0, 12),
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
					PaddingTop = UDim.new(0, 12)
				})

				New("TextLabel", {
					Name = "Title",
					Parent = Paragraph,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					Font = Enum.Font.GothamBold,
					Text = element.Title,
					TextColor3 = Theme.TextPrimary,
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top
				})

				New("TextLabel", {
					Name = "Content",
					Parent = Paragraph,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 22),
					Size = UDim2.new(1, 0, 1, -22),
					Font = Enum.Font.Gotham,
					Text = element.Content,
					TextColor3 = Theme.TextSecondary,
					TextSize = 13,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top
				})

				-- Auto-resize paragraph
				RunService.RenderStepped:Wait()
				local titleSize = TextService:GetTextSize(
					element.Title, 
					14, 
					Enum.Font.GothamBold, 
					Vector2.new(Paragraph.AbsoluteSize.X - 24, math.huge)
				)
				local contentSize = TextService:GetTextSize(
					element.Content, 
					13, 
					Enum.Font.Gotham, 
					Vector2.new(Paragraph.AbsoluteSize.X - 24, math.huge)
				)
				Paragraph.Size = UDim2.new(1, 0, 0, titleSize.Y + contentSize.Y + 32)

			if element.Type == "Button" then
				local ButtonFrame = New("Frame", {
					Name = "Button",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, Sizes.ElementHeight)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = ButtonFrame
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = ButtonFrame
				})

				New("TextLabel", {
					Parent = ButtonFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.026, 0, 0, 0),
					Size = UDim2.new(0.95, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center
				})

				local ClickButton = New("TextButton", {
					Parent = ButtonFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					AutoButtonColor = false
				})

				if element.Enabled then
					local buttonConnections = CreateInputHandler(ClickButton, {
						OnHoverStart = function()
							CreateTween(ButtonFrame, Timing.Fast, {BackgroundColor3 = Theme.SurfaceHover})
						end,
						OnHoverEnd = function()
							CreateTween(ButtonFrame, Timing.Fast, {BackgroundColor3 = Theme.SurfaceVariant})
						end,
						OnPressStart = function()
							CreateTween(ButtonFrame, Timing.Fast, {BackgroundColor3 = Theme.SurfaceActive})
						end,
						OnPressEnd = function()
							CreateTween(ButtonFrame, Timing.Fast, {BackgroundColor3 = Theme.SurfaceVariant})
						end,
						OnClick = function()
							SafeCallback(element.Callback)
						end
					})

					for _, conn in pairs(buttonConnections) do
						table.insert(Window.CurrentTab.Connections, conn)
					end
				end

			if element.Type == "Toggle" then
				local ToggleFrame = New("Frame", {
					Name = "Toggle",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, Sizes.ElementHeight)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = ToggleFrame
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = ToggleFrame
				})

				New("TextLabel", {
					Parent = ToggleFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.026, 0, 0, 0),
					Size = UDim2.new(0.8, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local Indicator = New("Frame", {
					Parent = ToggleFrame,
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = element.Value and Theme.Success or Theme.SurfaceActive,
					BorderSizePixel = 0,
					Position = UDim2.new(0.975, 0, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
					Parent = Indicator
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = Indicator
				})

				local ClickButton = New("TextButton", {
					Parent = ToggleFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					AutoButtonColor = false
				})

				if element.Enabled then
					local toggleConnections = CreateInputHandler(ClickButton, {
						OnClick = function()
							element.Value = not element.Value

							CreateTween(Indicator, Timing.Normal, {
								BackgroundColor3 = element.Value and Theme.Success or Theme.SurfaceActive
							})

							SafeCallback(element.Callback, element.Value)
						end
					})

					for _, conn in pairs(toggleConnections) do
						table.insert(Window.CurrentTab.Connections, conn)
					end
				end

			if element.Type == "Slider" then
				local SliderFrame = New("Frame", {
					Name = "Slider",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 56)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = SliderFrame
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = SliderFrame
				})

				local TextLabel = New("TextLabel", {
					Parent = SliderFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.026, 0, 0, 5),
					Size = UDim2.new(0.8, 0, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local ValueLabel = New("TextLabel", {
					Parent = SliderFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.8, 0, 0, 5),
					Size = UDim2.new(0.15, 0, 0, 20),
					Font = Enum.Font.GothamBold,
					Text = tostring(math.floor(element.Value)),
					TextColor3 = Theme.Primary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right
				})

				local SliderBar = New("Frame", {
					Parent = SliderFrame,
					BackgroundColor3 = Theme.SurfaceActive,
					BorderSizePixel = 0,
					Position = UDim2.new(0.026, 0, 0.5, 5),
					Size = UDim2.new(0.948, 0, 0, 6)
				})

				New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = SliderBar
				})

				local SliderFill = New("Frame", {
					Parent = SliderBar,
					BackgroundColor3 = Theme.Primary,
					BorderSizePixel = 0,
					Size = UDim2.new((element.Value - element.Min) / (element.Max - element.Min), 0, 1, 0)
				})

				New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = SliderFill
				})

				if element.Enabled then
					local dragging = false

					local function updateSlider(input)
						local relativeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						local value = element.Min + (element.Max - element.Min) * relativeX
						element.Value = math.floor(value)
						
						ValueLabel.Text = tostring(element.Value)
						CreateTween(SliderFill, Timing.Fast, {
							Size = UDim2.new(relativeX, 0, 1, 0)
						})
						
						SafeCallback(element.Callback, element.Value)
					end

					-- Mouse Support
					if IsDesktop then
						local conn1 = SliderBar.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								dragging = true
								updateSlider(input)
							end
						end)

						local conn2 = SliderBar.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								dragging = false
							end
						end)

						local conn3 = UserInputService.InputChanged:Connect(function(input)
							if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
								updateSlider(input)
							end
						end)

						table.insert(Window.CurrentTab.Connections, conn1)
						table.insert(Window.CurrentTab.Connections, conn2)
						table.insert(Window.CurrentTab.Connections, conn3)
					end

					-- Touch Support
						local touchInput = nil

						local conn1 = SliderBar.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.Touch then
								dragging = true
								touchInput = input
								updateSlider(input)
							end
						end)

						local conn2 = SliderBar.InputChanged:Connect(function(input)
							if dragging and input == touchInput then
								updateSlider(input)
							end
						end)

						local conn3 = SliderBar.InputEnded:Connect(function(input)
							if input == touchInput then
								dragging = false
								touchInput = nil
							end
						end)

						table.insert(Window.CurrentTab.Connections, conn1)
						table.insert(Window.CurrentTab.Connections, conn2)
						table.insert(Window.CurrentTab.Connections, conn3)
					end
				end

			if element.Type == "Input" then
				local InputFrame = New("Frame", {
					Name = "Input",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 56)
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = InputFrame
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = InputFrame
				})

				New("TextLabel", {
					Parent = InputFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.026, 0, 0, 5),
					Size = UDim2.new(0.95, 0, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local InputBox = New("TextBox", {
					Parent = InputFrame,
					BackgroundColor3 = Theme.SurfaceActive,
					BorderSizePixel = 0,
					Position = UDim2.new(0.026, 0, 0.45, 0),
					Size = UDim2.new(0.948, 0, 0, 26),
					Font = Enum.Font.Gotham,
					PlaceholderText = element.Placeholder,
					PlaceholderColor3 = Theme.TextMuted,
					Text = element.Value,
					TextColor3 = Theme.TextPrimary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					TextEditable = element.Enabled
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.15, 0),
					Parent = InputBox
				})

				New("UIPadding", {
					Parent = InputBox,
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8)
				})

				if element.Enabled then
					local conn = InputBox.FocusLost:Connect(function(enterPressed)
						element.Value = InputBox.Text
						SafeCallback(element.Callback, element.Value, enterPressed)
					end)

					table.insert(Window.CurrentTab.Connections, conn)
				end

			if element.Type == "Dropdown" then
				local DropdownFrame = New("Frame", {
					Name = "Dropdown",
					Parent = ContentContainer,
					BackgroundColor3 = Theme.SurfaceVariant,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 56),
					ZIndex = element.Open and 10 or 1
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = DropdownFrame
				})

				New("UIStroke", {
					Color = Theme.Border,
					Thickness = 1,
					Parent = DropdownFrame
				})

				New("TextLabel", {
					Parent = DropdownFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.026, 0, 0, 5),
					Size = UDim2.new(0.95, 0, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local DropdownButton = New("TextButton", {
					Parent = DropdownFrame,
					BackgroundColor3 = Theme.SurfaceActive,
					BorderSizePixel = 0,
					Position = UDim2.new(0.026, 0, 0.45, 0),
					Size = UDim2.new(0.948, 0, 0, 26),
					Font = Enum.Font.Gotham,
					Text = "  " .. tostring(element.Value) .. "  ▼",
					TextColor3 = Theme.TextPrimary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.15, 0),
					Parent = DropdownButton
				})

				local DropdownList = New("Frame", {
					Parent = DropdownFrame,
					BackgroundColor3 = Theme.Surface,
					BorderSizePixel = 0,
					Position = UDim2.new(0.026, 0, 1, 5),
					Size = UDim2.new(0.948, 0, 0, math.min(#element.Options * (30), 150)),
					Visible = element.Open,
					ZIndex = 11
				})

				New("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
					Parent = DropdownList
				})

				New("UIStroke", {
					Color = Theme.BorderAccent,
					Thickness = 1,
					Parent = DropdownList
				})

				local DropdownScroll = New("ScrollingFrame", {
					Parent = DropdownList,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					CanvasSize = UDim2.new(0, 0, 0, #element.Options * (30)),
					ScrollBarThickness = 4,
					ScrollBarImageColor3 = Theme.BorderAccent,
					ZIndex = 11
				})

				local DropdownLayout = New("UIListLayout", {
					Parent = DropdownScroll,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2)
				})

				if element.Enabled then
					local dropdownConnections = CreateInputHandler(DropdownButton, {
						OnClick = function()
							element.Open = not element.Open
							Window:RefreshContent()
						end
					})

					for _, conn in pairs(dropdownConnections) do
						table.insert(Window.CurrentTab.Connections, conn)
					end

					for i, option in pairs(element.Options) do
						local OptionButton = New("TextButton", {
							Parent = DropdownScroll,
							BackgroundColor3 = Theme.SurfaceVariant,
							BackgroundTransparency = option == element.Value and 0 or 0.5,
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 28),
							Font = Enum.Font.Gotham,
							Text = tostring(option),
							TextColor3 = option == element.Value and Theme.Primary or Theme.TextPrimary,
							TextSize = 13,
							AutoButtonColor = false,
							ZIndex = 11
						})

						New("UICorner", {
							CornerRadius = UDim.new(0.1, 0),
							Parent = OptionButton
						})

						local optionConnections = CreateInputHandler(OptionButton, {
							OnHoverStart = function()
								CreateTween(OptionButton, Timing.Fast, {BackgroundTransparency = 0})
							end,
							OnHoverEnd = function()
								if option ~= element.Value then
									CreateTween(OptionButton, Timing.Fast, {BackgroundTransparency = 0.5})
								end
							end,
							OnClick = function()
								element.Value = option
								element.Open = false
								Window:RefreshContent()
								SafeCallback(element.Callback, option)
							end
						})

						for _, conn in pairs(optionConnections) do
							table.insert(Window.CurrentTab.Connections, conn)
						end
					end
				end

				if element.Open then
					DropdownFrame.Size = UDim2.new(1, 0, 0, (56) + DropdownList.AbsoluteSize.Y + 5)
				end

			if element.Type == "Divider" then
				local DividerFrame = New("Frame", {
					Name = "Divider",
					Parent = ContentContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, element.Text ~= "" and 30 or 15)
				})

				if element.Text ~= "" then
					New("TextLabel", {
						Parent = DividerFrame,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20),
						Font = Enum.Font.GothamBold,
						Text = element.Text,
						TextColor3 = Theme.TextSecondary,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Center
					})
				end

				local Line = New("Frame", {
					Parent = DividerFrame,
					BackgroundColor3 = Theme.Border,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, element.Text ~= "" and 0.7 or 0.5, 0),
					Size = UDim2.new(1, 0, 0, 1)
				})
			end
		end
	end

	-- Window Management
	function Window:Toggle()
		Window.Visible = not Window.Visible
		CreateTween(Background, Timing.Normal, {
			Size = Window.Visible and UDim2.new(0, Sizes.WindowWidth, 0, Sizes.WindowHeight) or UDim2.new(0, 0, 0, 0)
		}, Enum.EasingStyle.Back)
	end

	function Window:Destroy()
		for _, connection in pairs(connections) do
			if connection and connection.Disconnect then
				connection:Disconnect()
			end
		end
		
		for _, tab in pairs(Window.Tabs) do
			for _, conn in pairs(tab.Connections or {}) do
				if conn and conn.Disconnect then
					conn:Disconnect()
				end
			end
		end
		
		if ZeusUI then
			ZeusUI:Destroy()
		end
		
		for i, win in pairs(ZeusLib.Windows) do
			if win == Window then
				table.remove(ZeusLib.Windows, i)
				break
			end
		end
	end

	table.insert(ZeusLib.Windows, Window)
	return Window
end

-- Notification System
function ZeusLib:Notify(title, message, duration, notifType)
	title = title or "Notification"
	message = message or ""
	duration = duration or 3
	notifType = notifType or "info" -- info, success, warning, error

	local NotifColor = Theme.Primary
	if notifType == "success" then
		NotifColor = Theme.Success
	if notifType == "warning" then
		NotifColor = Theme.Warning
	if notifType == "error" then
		NotifColor = Theme.Error
	end

	local NotifGui = New("ScreenGui", {
		Name = "ZeusNotification",
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true
	})

	local NotifFrame = New("Frame", {
		Parent = NotifGui,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 20, 0, 20),
		Size = UDim2.new(0, 350, 0, 70)
	})

	New("UICorner", {
		CornerRadius = UDim.new(0.1, 0),
		Parent = NotifFrame
	})

	New("UIStroke", {
		Color = NotifColor,
		Thickness = 2,
		Parent = NotifFrame
	})

	local Accent = New("Frame", {
		Parent = NotifFrame,
		BackgroundColor3 = NotifColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0)
	})

	New("TextLabel", {
		Parent = NotifFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 8),
		Size = UDim2.new(1, -20, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	New("TextLabel", {
		Parent = NotifFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 30),
		Size = UDim2.new(1, -20, 1, -35),
		Font = Enum.Font.Gotham,
		Text = message,
		TextColor3 = Theme.TextSecondary,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	})

	-- Slide in animation
	CreateTween(NotifFrame, Timing.Normal, {
		Position = UDim2.new(1, -20, 0, 20)
	}, Enum.EasingStyle.Back)

	-- Auto dismiss
	task.wait(duration)
	CreateTween(NotifFrame, Timing.Normal, {
		Position = UDim2.new(1, 20, 0, 20)
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	task.wait(Timing.Normal)
	NotifGui:Destroy()
end

return ZeusLib
