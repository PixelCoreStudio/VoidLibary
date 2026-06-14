local Library = {}

local DEFAULTS = {
    WINDOW_WIDTH = 550,
    WINDOW_HEIGHT = 380,
    SIDEBAR_WIDTH = 150,
    BACKGROUND_COLOR = Color3.fromRGB(12, 12, 16), -- Deep Black-Blue
    ACCENT_COLOR = Color3.fromRGB(6, 182, 212),   -- Cyber-Cyan
    STROKE_COLOR = Color3.fromRGB(35, 35, 45),     -- Dark Grey/Blue for Stroke
    CORNER_RADIUS = 12,                            -- Window Radius
    ELEMENT_CORNER_RADIUS = 8,                     -- Element Radius
}

local function createFrame(parent, className, properties)
    local frame = Instance.new("Frame")
    frame.Name = className or "Frame"
    if properties then
        for k, v in pairs(properties) do
            frame[k] = v
        end
    end
    return frame
end

-- Helper to apply the aesthetic styling to a Frame
local function applyAesthetics(frame, isWindow)
    if frame then
        frame.BackgroundColor3 = DEFAULTS.BACKGROUND_COLOR
        frame.BorderSizePixel = 0
        frame.UIStroke = {
            Color = DEFAULTS.STROKE_COLOR,
            Thickness = 1,
        }
        if isWindow then
            frame.UICorner = Instance.new("UICorner")
            frame.UICorner.CornerRadius = DEFAULTS.CORNER_RADIUS
        else
            frame.UICorner = Instance.new("UICorner")
            frame.UICorner.CornerRadius = DEFAULTS.ELEMENT_CORNER_RADIUS
        end
    end
end

-- 1. CreateWindow
function Library.CreateWindow(titleText)
    local coreGui = game:GetService("CoreGui")
    local window = createFrame(coreGui, "Window", {
        Size = UDim2.new(0, DEFAULTS.WINDOW_WIDTH, 0, DEFAULTS.WINDOW_HEIGHT),
        Position = UDim2.new(0.5, -DEFAULTS.WINDOW_WIDTH / 2, 0.5, -DEFAULTS.WINDOW_HEIGHT / 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = DEFAULTS.BACKGROUND_COLOR,
        Visible = true,
    })

    applyAesthetics(window, true) -- Apply window aesthetics

    -- Sidebar (Tabs)
    local sidebar = createFrame(window, "Sidebar")
    sidebar.Size = UDim2.new(0, DEFAULTS.SIDEBAR_WIDTH, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 1)
    sidebar.BackgroundColor3 = Color3.fromRGB(35, 35, 45) -- Slightly different dark shade for contrast

    -- Content Area
    local contentArea = createFrame(window, "ContentArea")
    contentArea.Size = UDim2.new(1, -DEFAULTS.SIDEBAR_WIDTH, 1, 0)
    contentArea.Position = UDim2.new(0, DEFAULTS.SIDEBAR_WIDTH, 0, 0)

    -- Sidebar Tabs setup (simplified for structure)
    local tabsFrame = createFrame(sidebar, "TabsFrame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
    })

    -- Content Area Layout setup
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentArea:WaitForChild("UIListLayout").Name = "ListLayout" -- Ensure the layout is in the content area

    -- Placeholder for tab management (will be handled by Window:CreateTab)
    window:SetSidebar(sidebar, tabsFrame)

    return window
end

-- Helper method to attach sidebar to window (Inferred from requirement 2)
function Library.CreateWindow:SetSidebar(window, sidebar, tabsFrame)
    -- In a real implementation, this would manage the actual tab UI elements within the sidebar
    -- For simplicity here, we just ensure the structure exists.
end


-- 2. Window:CreateTab
function Library.Window:CreateTab(tabName)
    local window = self -- 'self' refers to the returned Window object
    if not window or not window:GetSidebar then return nil end

    -- Placeholder for tab UI (e.g., a button in the sidebar)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabButton"
    tabButton.Text = tabName
    tabButton.Size = UDim2.new(1, 0, 0, 40)
    tabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    tabButton.Parent = tabsFrame -- Assuming tabsFrame is accessible or managed by the window object

    -- Placeholder for content (The actual tab content creation would happen here, involving TweenService)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "TabContent"
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    contentFrame.Parent = window -- Content goes into the main window frame

    -- Implement smooth switching logic (requires TweenService access, assumed available)
    local tweenService = game:GetService("TweenService")

    -- Simplified logic: switch content based on tabName
    if tabName == "Default" then
        contentFrame.Visible = true
    else
        contentFrame.Visible = false
    end

    return {
        TabButton = tabButton,
        Content = contentFrame,
        Window = window -- Return the main window reference for further interaction
    }
end


-- 3. Tab:CreateButton
function Library.Tab:CreateButton(text, callback)
    local button = Instance.new("TextButton")
    button.Text = text
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 60) -- Slightly lighter for base state
    button.Parent = Instance.new("Frame") -- Parent structure needs definition in actual use case

    local tweenService = game:GetService("TweenService")
    local originalColor = button.BackgroundColor3
    local targetColor = Library.DEFAULTS.ACCENT_COLOR

    -- Initial state setup (needs a Frame context for mouse enter)
    button.MouseEnter:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local goal = {BackgroundColor3 = targetColor}
        tweenService:Create(goal, tweenInfo):Play()
    end)

    button.MouseLeave:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local goal = {BackgroundColor3 = originalColor}
        tweenService:Create(goal, tweenInfo):Play()
    end)

    button.MouseButton1Click:Connect(function()
        callback()
    end)

    return button
end

-- 4. Tab:CreateToggle
function Library.Tab:CreateToggle(text, default, callback)
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, 0, 0, 40)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = Instance.new("Frame") -- Wrapper for capsule

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 40, 0, 40)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Default state background
    toggleFrame.Parent = label

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(1, 0, 1, 0)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Default state (off/left)
    toggleCircle.Parent = toggleFrame

    local tweenService = game:GetService("TweenService")

    local function toggle()
        local currentState = toggleCircle.BackgroundColor3 == Color3.fromRGB(255, 255, 255)
        local newState = not currentState
        toggleCircle.BackgroundColor3 = newState and Library.DEFAULTS.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)

        if newState then
            -- Slide Right (True state)
            tweenService:Create(toggleCircle, TweenInfo.new(0.3), {Position = UDim2.new(1, -40, 0, 0)}):Play()
        else
            -- Slide Left (False state)
            tweenService:Create(toggleCircle, TweenInfo.new(0.3), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        end

        callback(newState)
    end

    label.MouseButton1Click:Connect(toggle)

    return label
end

-- 5. Tab:CreateSlider
function Library.Tab:CreateSlider(text, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "SliderFrame"
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderFrame.Parent = Instance.new("Frame")

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, 0, 1, 0)
    sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderBar.Parent = sliderFrame

    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 40, 0, 40)
    handle.BackgroundColor3 = Library.DEFAULTS.ACCENT_COLOR
    handle.Parent = sliderBar

    local userInputService = game:GetService("UserInputService")
    local tweenService = game:GetService("TweenService")

    local function updateSlider(position)
        local value = math.clamp(position.Scale * (max - min) + min, min, max)
        local newValue = math.floor(value * 100) / 100 -- Keep precision reasonable
        handle.Position = UDim2.new(0, newValue * 100, 0, 50) -- Position based on value (assuming the slider is relative to the bar)
        sliderBar.BackgroundColor3 = Color3.fromRGB(60 + (value / (max - min) * 20), 60, 80) -- Visual feedback

        local displayText = string.format("%s: %.2f", text, value)
        -- In a real scenario, this would update a TextLabel near the slider
        print(displayText)
    end

    local function onInput(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePosition = userInputService:GetMouseLocation()
            -- Calculate position relative to the sliderBar (simplified)
            local xOffset = math.clamp(mousePosition.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X) / sliderFrame.AbsoluteSize.X
            updateSlider(Vector2.new(xOffset, 1)) -- Passing relative position data
        end
    end

    local function onDragEnd()
        -- Final calculation and callback
        local finalPos = userInputService:GetMouseLocation()
        local xOffset = math.clamp(finalPos.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X) / sliderFrame.AbsoluteSize.X
        updateSlider(Vector2.new(xOffset, 1))
        callback(math.floor(xOffset * (max - min) + min)) -- Pass the final value to callback
    end

    -- Connect input handling for dragging
    local connection = userInputService.InputChanged:Connect(onInput)
    local dragConnection = userInputService.InputEnded:Connect(onDragEnd)


    userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    sliderFrame.Visible = true

    -- Simplified drag tracking (needs refinement based on exact implementation context)
    userInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and sliderFrame.Visible then
            local mousePos = userInputService:GetMouseLocation()
            local x = math.clamp(mousePos.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X) / sliderFrame.AbsoluteSize.X
            handle.Position = UDim2.new(0, x * (max - min) * 100, 0, 50) -- Update handle position
            sliderBar.BackgroundColor3 = Color3.fromRGB(60 + x * 20, 60, 80)
        end
    end)

    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and sliderFrame.Visible then
            local mousePos = userInputService:GetMouseLocation()
            local x = math.clamp(mousePos.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X) / sliderFrame.AbsoluteSize.X
            handle.Position = UDim2.new(0, x * (max - min) * 100, 0, 50) -- Final position
            local value = math.floor(x * (max - min) + min)
            callback(value)
        end
    end)

    -- NOTE: Full implementation of smooth dragging is highly dependent on how the parent structure interacts with CoreGui drag logic from source.lua.
    return sliderFrame
end

-- 6. Tab:CreateDropdown
function Library.Tab:CreateDropdown(text, optionsList, callback)
    local button = Instance.new("TextButton")
    button.Text = text
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    button.Parent = Instance.new("Frame") -- Wrapper

    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    optionsFrame.Parent = button

    local tweenService = game:GetService("TweenService")
    local defaultState = false

    button.MouseButton1Click:Connect(function()
        defaultState = not defaultState
        local targetSize = defaultState and UDim2.new(1, 0, 0, 100) or UDim2.new(1, 0, 0, 0)
        local tweenInfo = TweenInfo.new(0.3)
        tweenService:Create(optionsFrame, tweenInfo, {Size = targetSize}):Play()
    end)

    -- Placeholder for option selection logic (omitted complex interaction for brevity and focus on structure)
    optionsFrame.MouseButton1Click:Connect(function()
        local selected = true -- Simplified selection
        callback(selected)
        tweenService:Create(optionsFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    end)

    return button
end


-- 7. Tab:CreateTextBox
function Library.Tab:CreateTextBox(text, placeholder, callback)
    local inputField = Instance.new("TextBox")
    inputField.Text = text
    inputField.PlaceholderText = placeholder
    inputField.Size = UDim2.new(1, 0, 0, 40)
    inputField.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    inputField.Parent = Instance.new("Frame")

    local inputService = game:GetService("UserInputService")

    inputField.FocusLost:Connect(function()
        callback(inputField.Text)
    end)

    return inputField
end


-- Expose the main functions (if not handled by caller structure)
Library.CreateWindow = Library.CreateWindow
Library.Window = Library.Window
Library.Tab = Library.Tab
