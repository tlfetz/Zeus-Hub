local Library = {}
Library.Windows = {}

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
	Spacing = 8
}

-- Service Cache
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

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
			warn("UI Callback Error:", err)
		end
	end
end

-- Window Creation
function Library:CreateWindow(title, subtitle)
	local Window = {}
	local windowIndex = #Library.Windows + 1
	local connections = {}

	title = title or "UI Library"
	subtitle = subtitle or "Subtitle"

	local SeizureUI = New("ScreenGui", {
		Name = "SeizureUI_" .. windowIndex,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false
	})

	local Background = New("Frame", {
		Name = "Background",
		Parent = SeizureUI,
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

	-- Title Elements
	New("TextLabel", {
		Name = "title",
		Parent = Background,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.03, 0, 0.03, 0),
		Size = UDim2.new(0, 548, 0, 21),
		Font = Enum.Font.GothamMedium,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	New("TextLabel", {
		Name = "subtitle",
		Parent = Background,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.03, 0, 0.064, 0),
		Size = UDim2.new(0, 548, 0, 21),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Theme.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})

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
	local TabContainer = New("Frame", {
		Name = "TabContainer",
		Parent = Background,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.019, 0, 0.141, 0),
		Size = UDim2.new(0, 135, 0, 324)
	})

	New("UIListLayout", {
		Parent = TabContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Sizes.Spacing)
	})

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

	-- Dragging Functionality
	local dragging, dragInput, dragStart, startPos, dragTween

	table.insert(connections, Background.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Background.Position

			if dragTween then
				dragTween:Cancel()
			end

			local endConnection
			endConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if endConnection then
						endConnection:Disconnect()
					end
				end
			end)
		end
	end))

	table.insert(connections, Background.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local newPosition = UDim2.new(
				startPos.X.Scale, 
				startPos.X.Offset + delta.X, 
				startPos.Y.Scale, 
				startPos.Y.Offset + delta.Y
			)

			if dragTween then
				dragTween:Cancel()
			end

			dragTween = CreateTween(Background, Timing.Fast, {Position = newPosition})
		end
	end))

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
			Font = Enum.Font.Gotham,
			Text = name,
			TextColor3 = isFirstTab and Theme.TextPrimary or Theme.TextSecondary,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false
		})

		New("UIPadding", {
			Parent = TabButton,
			PaddingLeft = UDim.new(0, 5)
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

		-- Hover Effect
		TabButton.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then
				CreateTween(TabButton, Timing.Fast, {
					BackgroundTransparency = 0.5
				})
			end
		end)

		TabButton.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then
				CreateTween(TabButton, Timing.Fast, {
					BackgroundTransparency = 1
				})
			end
		end)

		TabButton.MouseButton1Click:Connect(function()
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
		end)

		Tab.Button = TabButton
		Tab.Elements = {}

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
			default = default or min

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

		return Tab
	end

	-- Content Refresh
	function Window:RefreshContent()
		if not Window.CurrentTab then return end

		for _, child in pairs(ContentContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

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
					Font = Enum.Font.GothamMedium,
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

				task.spawn(function()
					task.wait()
					local titleSize = TextService:GetTextSize(
						element.Title, 
						14, 
						Enum.Font.GothamMedium, 
						Vector2.new(Paragraph.AbsoluteSize.X - 24, math.huge)
					)
					local contentSize = TextService:GetTextSize(
						element.Content, 
						13, 
						Enum.Font.Gotham, 
						Vector2.new(Paragraph.AbsoluteSize.X - 24, math.huge)
					)
					Paragraph.Size = UDim2.new(1, 0, 0, titleSize.Y + contentSize.Y + 32)
				end)

			elseif element.Type == "Button" then
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
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local ClickButton = New("TextButton", {
					Parent = ButtonFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					AutoButtonColor = false
				})

				if element.Enabled then
					ClickButton.MouseEnter:Connect(function()
						CreateTween(ButtonFrame, Timing.Fast, {
							BackgroundColor3 = Theme.SurfaceHover
						})
					end)

					ClickButton.MouseLeave:Connect(function()
						CreateTween(ButtonFrame, Timing.Fast, {
							BackgroundColor3 = Theme.SurfaceVariant
						})
					end)

					ClickButton.MouseButton1Click:Connect(function()
						CreateTween(ButtonFrame, Timing.Fast, {
							BackgroundColor3 = Theme.SurfaceActive
						})
						task.wait(Timing.Fast)
						CreateTween(ButtonFrame, Timing.Fast, {
							BackgroundColor3 = Theme.SurfaceVariant
						})

						SafeCallback(element.Callback)
					end)
				end

			elseif element.Type == "Toggle" then
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
					Size = UDim2.new(0.85, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local Indicator = New("Frame", {
					Parent = ToggleFrame,
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = element.Value and Theme.Primary or Theme.SurfaceActive,
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
					ClickButton.MouseButton1Click:Connect(function()
						element.Value = not element.Value

						CreateTween(Indicator, Timing.Normal, {
							BackgroundColor3 = element.Value and Theme.Primary or Theme.SurfaceActive
						})

						SafeCallback(element.Callback, element.Value)
					end)
				end

			elseif element.Type == "Slider" then
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
					Size = UDim2.new(0.85, 0, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = element.Text,
					TextColor3 = element.Enabled and Theme.TextPrimary or Theme.TextMuted,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})

				local ValueLabel = New("TextLabel", {
					Parent = SliderFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.85, 0, 0, 5),
					Size = UDim2.new(0.12, 0, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = tostring(math.floor(element.Value)),
					TextColor3 = Theme.TextSecondary,
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

					SliderBar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							updateSlider(input)
						end
					end)

					SliderBar.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							updateSlider(input)
						end
					end)
				end
			end
		end
	end

	-- Window Management
	function Window:Toggle()
		Window.Visible = not Window.Visible
		CreateTween(Background, Timing.Normal, {
			Size = Window.Visible and UDim2.new(0, Sizes.WindowWidth, 0, Sizes.WindowHeight) or UDim2.new(0, 0, 0, 0)
		})
	end

	function Window:Destroy()
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end
		
		if SeizureUI then
			SeizureUI:Destroy()
		end
		
		for i, win in pairs(Library.Windows) do
			if win == Window then
				table.remove(Library.Windows, i)
				break
			end
		end
	end

	table.insert(Library.Windows, Window)
	return Window
end

return Library
