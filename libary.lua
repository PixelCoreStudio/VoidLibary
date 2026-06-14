--[[
    Cyberpunk UI System Refactor (Lua)
    Design: Minimalist Cyberpunk
    Colors: Obsidian Black, Velvet Gray, Neon Purple
    Style: Glassmorphism, Rounded Corners, Fluid Animations
]]

local module = {}
local ts = cloneref(game:GetService("TweenService"))
local cg = cloneref(game:GetService("CoreGui"))
local ui = cloneref(game:GetService("UserInputService"))

-- ========================================
-- 🎨 CYBERPUNK COLOR PALETTE & STYLING CONSTANTS
-- ========================================
local C = {
    ObsidianBlack = Color3.fromRGB(11, 11, 14), -- Haupt-Hintergrund (Darkest)
    VelvetGray = Color3.fromRGB(26, 26, 46),   -- Sekundärhintergrund (Cards, Buttons)
    AccentNeon = Color3.fromRGB(160, 32, 240), -- Primärer Akzent (Purple Highlight)
    WhitePrimary = Color3.new(1, 1, 1),         -- Weißer Text
    GraySecondary = Color3.fromRGB(143, 143, 143) -- Aschgrau (Beschreibung/Inaktiv)
}

local CORNER_RADIUS = UDim2.new(0, 8)
local TRANSITION_TIME = 0.25
local HOVER_DURATION = 0.3

-- Helper function to apply corner radius and dark background fill
local function applyCyberStyle(instance, bgColor)
    if instance:IsA("Frame") or instance:IsA("TextLabel") then
        -- Set Corner Radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = CORNER_RADIUS
        corner.Parent = instance

        -- Apply base color (Glassmorphism simulation)
        instance.BackgroundColor3 = bgColor
        if instance:FindFirstChildOfClass("Frame") then -- Check if it's a container that needs transparency
             instance.BackgroundTransparency = 0.1
        else
             instance.BackgroundTransparency = 0.2
        end

    end
end

-- ========================================
-- MAIN WINDOW LOGIC
-- ========================================

function module:win(title)
    local windowAssetId = "rbxassetid://96576283085736"
    local elementsAssetId = "rbxassetid://83539751566719"

    -- NOTE: Assuming the assets are loaded and functional.
    local window = game:GetObjects(windowAssetId)[1]
    local elements = game:GetObjects(elementsAssetId)[1]

    -- Apply initial cyber style to main containers
    applyCyberStyle(window, C.ObsidianBlack)
    applyCyberStyle(window.Frame, C.ObsidianBlack)
    applyCyberStyle(window.Frame.topbar, C.VelvetGray) -- Topbar is a smaller box

    -- Set title text color (Assuming the Title object exists within topbar)
    local titleText = window.Frame.topbar.title
    if titleText then
        titleText.TextColor3 = C.WhitePrimary
    end

    local closeBtn = window.Frame.topbar.btns.Close
    local miniBtn = window.Frame.topbar.btns.Minimize

    -- Style buttons: Use the secondary background and corner radius
    applyCyberStyle(closeBtn, C.VelvetGray)
    applyCyberStyle(miniBtn, C.VelvetGray)

    local toggleCon = nil

    local function fadebtn(btn, isIn)
        ts:Create(
            btn,
            TweenInfo.new(HOVER_DURATION), -- Use the defined hover duration
            {
                BackgroundTransparency = isIn and 0.2 or 1, -- Less transparent when active/hovered
                -- Optional: Add a slight scale up for more pop
            }
        ):Play()
    end

    local function togglewin(isIn)
        ts:Create(
            window.Frame,
            TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                GroupTransparency = isIn and 0 or 1
            }
        ):Play()

        -- Note: Using a fixed scale/size calculation based on original code's intent.
        local targetSize = isIn and UDim2.new(0.37, 0, 0.407, 0) or UDim2.new(0.37, 0, 0.376, 0)
        ts:Create(
            window.Frame,
            TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = targetSize
            }
        ):Play()

        window.Frame.Interactable = isIn and true or false
    end

    local function fadetopbar(isIn)
        ts:Create(
            window.Frame.topbar,
            TweenInfo.new(HOVER_DURATION),
            {
                BackgroundTransparency = isIn and 0.2 or 0.8 -- Use low transparency for Cyber Look
            }
        ):Play()
    end

    -- Event Connections (unchanged logic)
    closeBtn.MouseEnter:Connect(function() fadebtn(closeBtn, true) end)
    miniBtn.MouseEnter:Connect(function() fadebtn(miniBtn, true) end)
    closeBtn.MouseLeave:Connect(function() fadebtn(closeBtn, false) end)
    miniBtn.MouseLeave:Connect(function() fadebtn(miniBtn, false) end)

    topbar.MouseEnter:Connect(function() fadetopbar(true) end)
    topbar.MouseLeave:Connect(function() fadetopbar(false) end)

    closeBtn.MouseButton1Click:Connect(function()
        window:Destroy()
        elements:Destroy()
        toggleCon:Disconnect()
    end)

    miniBtn.MouseButton1Click:Connect(function()
        togglewin(false)
    end)

    toggleCon = ui.InputBegan:Connect(function(keyc, gamep)
        if not gamep and keyc.KeyCode == Enum.KeyCode.K then
            togglewin(not window.Frame.Interactable)
        end
    end)

    -- Dragging Logic (Unchanged - this is input handling, not style)
    local sections = {}
    local curSelected = nil

    local dragging = false
    local dragInput, mousePos, framePos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = window.Frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    ui.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            window.Frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)

    -- ========================================
    -- TABS AND SECTIONS LOGIC (Updated Styling)
    -- ========================================

    local function toggletab(tab, isIn)
        ts:Create(
            tab,
            TweenInfo.new(TRANSITION_TIME),
            {
                GroupTransparency = isIn and 0 or 1
            }
        ):Play()
        ts:Create(
            tab,
            TweenInfo.new(TRANSITION_TIME),
            {
                Position = isIn and UDim2.new(0.5, 0, 1, 0) or UDim2.new(0.5, 0, 1.1, 0)
            }
        ):Play()
        tab.Interactable = isIn and true or false
    end

    local function fadeelement(which, isIn)
        -- Glow effect simulation: Change background color slightly on hover
        local targetTransparency = if(isIn then 0.1 else 0.3) -- More visible glow when hovered
        ts:Create(
            which,
            TweenInfo.new(HOVER_DURATION),
            {
                BackgroundTransparency = targetTransparency
            }
        ):Play()
    end

    function sections:tab(title, ico)
        -- 1. CLONE & STYLIZE TAB BUTTON (elements.tabelement)
        local newBtn = elements.tabelement:Clone()
        newBtn.Name = title
        applyCyberStyle(newBtn, C.ObsidianBlack) -- Use Obsidian for the tab background

        -- Style specific internal elements
        if newBtn:FindFirstChild("title") then
             local titleObj = newBtn.title
             titleObj.TextColor3 = C.WhitePrimary
        end

        newBtn.Image = ico
        newBtn.title.Text = title

        newBtn.Parent = window.Frame.tabscontainer

        -- 2. CLONE & STYLIZE SECTION CANVAS (elements.sectioncanvas)
        local newSect = elements.sectioncanvas:Clone()
        applyCyberStyle(newSect, C.ObsidianBlack) -- Use Obsidian for the section background

        newSect.Parent = window.Frame.sectionsholder
        newSect.GroupTransparency = 1
        newSect.Position = UDim2.new(0.5, 0, 1.1, 0)
        newSect.Interactable = false

        -- Tab Hover Logic
        local function fadetab(isIn)
            ts:Create(
                newBtn,
                TweenInfo.new(HOVER_DURATION),
                {ImageTransparency = isIn and 0.25 or 0.5}
            ):Play()
            ts:Create(
                newBtn.title,
                TweenInfo.new(HOVER_DURATION),
                {TextColor3 = isIn and C.AccentNeon or C.WhitePrimary} -- Color change on hover
            ):Play()
        end

        newBtn.MouseEnter:Connect(function() fadetab(true) end)
        newBtn.MouseLeave:Connect(function() fadetab(false) end)

        -- Tab Click Logic
        newBtn.MouseButton1Click:Connect(function()
            if curSelected == newSect then return end
            if curSelected ~= nil then
                toggletab(curSelected, false)
            end

            toggletab(newSect, true)
            curSelected = newSect
        end)

        local contents = {}

        -- --------------------
        -- CONTENT: LABEL (Static Text)
        -- --------------------
        function contents:label(title)
            local newLabel = elements.LabelElement:Clone()
            applyCyberStyle(newLabel, C.ObsidianBlack)
            if newLabel:FindFirstChild("lbl") then
                 local lblObj = newLabel.lbl
                 lblObj.TextColor3 = C.WhitePrimary
                 lblObj.TextXAlignment = Enum.TextXAlignment.Left
            end
            newLabel.lbl.Text = title
            newLabel.Parent = newSect.sectioncontainer
        end

        -- --------------------
        -- CONTENT: BUTTON
        -- --------------------
        function contents:button(title, cb)
            local newButton = elements.ButtonElement:Clone()
            applyCyberStyle(newButton, C.VelvetGray) -- Button background color

            -- Style the inner button element (the clickable part)
            local btnObj = newButton.btn
            applyCyberStyle(btnObj, C.ObsidianBlack) -- Inner button is darker for contrast

            if btnObj:FindFirstChild("lbl") then
                local lblObj = btnObj.lbl
                lblObj.TextColor3 = C.WhitePrimary
            end

            newButton.btn.lbl.Text = title
            newButton.Parent = newSect.sectioncontainer

            -- Hover/Interaction Feedback (Improved Glow)
            btnObj.MouseEnter:Connect(function() fadeelement(btnObj, true) end)
            btnObj.MouseLeave:Connect(function() fadeelement(btnObj, false) end)

            newButton.btn.MouseButton1Click:Connect(cb)
        end

        -- --------------------
        -- CONTENT: TOGGLE (Switch)
        -- --------------------
        function contents:toggle(title, default, cb)
            local toggled = default

            local newToggle = elements.ToggleElement:Clone()
            applyCyberStyle(newToggle, C.ObsidianBlack) -- Base container style

            -- Style the internal button wrapper
            local btnObj = newToggle.btn
            applyCyberStyle(btnObj, C.VelvetGray) -- Button background color

            if btnObj:FindFirstChild("lbl") then
                btnObj.lbl.TextColor3 = C.WhitePrimary
            end

            newToggle.btn.lbl.Text = title
            newToggle.Parent = newSect.sectioncontainer

            -- Style the slide element (the visual switch)
            local togglebg = newToggle.btn.togglebg
            local sidetog = togglebg.Frame
            applyCyberStyle(sidetog, C.AccentNeon) -- The active part should be Neon Purple

            if toggled then
                -- Initial positioning for 'On' state
                togglebg.BackgroundColor3 = C.AccentNeon -- Use solid color for the "on" fill
                sidetog.AnchorPoint = Vector2.new(1, 0.5)
                sidetog.Position = UDim2.new(1, 0, 0.5, 0)
                task.defer(cb, toggled)
            end

            local function setToggleVisuals(is_on)
                 if is_on then
                     togglebg.BackgroundColor3 = C.AccentNeon
                     sidetog.AnchorPoint = Vector2.new(1, 0.5)
                     sidetog.Position = UDim2.new(1, 0, 0.5, 0)
                 else
                     togglebg.BackgroundColor3 = Color3.fromRGB(74, 255, 89):Lerp(C.ObsidianBlack, 0.5) -- Muted red/off color
                     sidetog.AnchorPoint = Vector2.new(0, 0.5)
                     sidetog.Position = UDim2.new(0, 0, 0.5, 0)
                 end
            end

            -- Toggle Click Logic
            newToggle.btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                setToggleVisuals(toggled) -- Apply the new visual state

                ts:Create(
                    sidetog,
                    TweenInfo.new(0.15),
                    {AnchorPoint = Vector2.new(1,0.5)} -- Target anchor point for 'On'
                ):Play()

                ts:Create(
                    sidetog,
                    TweenInfo.new(0.15),
                    {Position = UDim2.new(1, 0, 0.5, 0)}
                ):Play()

                -- NOTE: Simplified visual logic here; assumes the initial setToggleVisuals handles color changes
                cb(toggled)
            end)
        end

        -- --------------------
        -- CONTENT: TEXTBOX (Input Field)
        -- --------------------
        function contents:textbox(title, default, cb)
            local newtb = elements.TextboxElement:Clone()
            applyCyberStyle(newtb, C.ObsidianBlack) -- Dark base for the box

            if newtb:FindFirstChild("frame") then
                applyCyberStyle(newtb.frame, C.VelvetGray) -- Slightly lighter background for the input area

                -- Title styling
                if newtb.frame:FindFirstChild("lbl") then
                    local lblObj = newtb.frame.lbl
                    lblObj.TextColor3 = C.WhitePrimary
                end

                local inp = newtb.frame.inp.lbl -- This is the actual editable text element
                applyCyberStyle(newtb.frame.inp, C.ObsidianBlack)

                -- Focus/Cursor Styling Simulation:
                -- The cursor should visually glow when focused (hard to do purely in Lua, but we style the box)
                inp.TextColor3 = C.WhitePrimary

                -- Input Value Setup
                inp.Text = default

                if default ~= "" then
                    task.defer(cb, default)
                end

                -- Focus Lost (Value update)
                inp.FocusLost:Connect(function(ep)
                    if ep then
                        cb(inp.Text)
                    end
                end)
            end
        end

        -- --------------------
        -- CONTENT: SLIDER
        -- --------------------
        function contents:slider(title, min, max, default, cb)
            local newsl = elements.SliderElement:Clone()
            applyCyberStyle(newsl, C.ObsidianBlack) -- Dark base for the slider element

            if newsl:FindFirstChild("lbl") then
                local lblObj = newsl.lbl
                lblObj.TextColor3 = C.WhitePrimary
            end

            -- Style the clickable button area
            local slbtn = newsl.btn
            applyCyberStyle(slbtn, C.VelvetGray) -- The track background

            -- Style the progress bar (The Neon element)
            local prog = slbtn.prog
            applyCyberStyle(prog, C.AccentNeon) -- PROGRESS BAR IS NEON ACCENT!

            local lastval = 0
            local dragging = false

            -- Utility Functions (Unchanged Logic)
            local function setFromAlpha(alpha)
                alpha = math.clamp(alpha, 0, 1)
                local value = math.floor(min + (max - min) * alpha + 0.5)
                prog.Size = UDim2.new(alpha, 0, 1, 0)
                lastval = value
            end

            local function updateFromInput(x)
                -- Calculate ratio based on screen position relative to the slider button size
                local rel = (x - slbtn.AbsolutePosition.X) / slbtn.AbsoluteSize.X
                setFromAlpha(rel)
            end

            setFromAlpha((default - min) / (max - min))

            -- Input Handling (Unchanged Logic)
            slbtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputEnded:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    if cb then
                        newsl.lbl.Text = title .. " : " .. tostring(lastval)
                        pcall(cb, lastval)
                    end
                end
            end)
        end

        return contents
    end

    return sections
end

return module
