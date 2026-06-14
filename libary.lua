--[[
    Customizable UI Library
    Original concept by esore aka vaehz - rewritten so the WHOLE design
    can be customized via module.Theme / win(title, themeOverrides) /
    window:SetTheme(...) WITHOUT having to build new UI assets.

    Every visual element (window, topbar, tabs, buttons, toggles,
    textboxes, sliders, labels) is built with Instance.new and styled
    from a single "theme" table. Change colors, fonts, sizes, corner
    radius etc. in one place - or override them per window, or change
    them live at runtime.

    -------------------------------------------------------------------
    THEME PASS: "Minimal Cyberpunk"
    - Obsidian black panels (#0B0B0E)
    - Velvet blue/grey secondary surfaces (#1A1A2E)
    - Neon amethyst accent (#A020F0) for highlights, borders, toggles
    - White / ash-grey text
    - 8px rounded corners everywhere
    - Subtle glassmorphism (translucent panels + soft neon stroke glow)
    - Fast, elegant transitions (<= 0.3s, Quint easing)

    No functional/behavioral changes were made - only colors,
    transparencies, corner radii, strokes and tween parameters.
    -------------------------------------------------------------------
]]

local module = {}

local ts = cloneref(game:GetService("TweenService"))
local cg = cloneref(game:GetService("CoreGui"))
local ui = cloneref(game:GetService("UserInputService"))

-- =========================================================================
-- THEME  -- this is the single source of truth for the whole design.
-- Edit these values directly, or pass a table with the keys you want
-- to change into module:win(title, overrides).
-- =========================================================================
module.Theme = {
    Font            = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,

    CornerRadius    = UDim.new(0, 8),   -- main window corners
    ElementRadius   = UDim.new(0, 8),   -- buttons / toggles / tabs / inputs

    -- core surfaces ------------------------------------------------------
    Background      = Color3.fromRGB(11, 11, 14),     -- #0B0B0E  obsidian (main panels)
    Topbar          = Color3.fromRGB(26, 26, 46),      -- #1A1A2E  velvet blue/grey
    TabBar          = Color3.fromRGB(26, 26, 46),      -- #1A1A2E
    ElementBg       = Color3.fromRGB(26, 26, 46),      -- #1A1A2E
    ElementHoverBg  = Color3.fromRGB(42, 33, 64),      -- slightly lifted, purple-tinted hover

    -- text -----------------------------------------------------------------
    Text            = Color3.fromRGB(255, 255, 255),   -- #FFFFFF
    SubText         = Color3.fromRGB(143, 143, 143),   -- #8F8F8F

    -- accents ----------------------------------------------------------------
    Accent          = Color3.fromRGB(160, 32, 240),    -- #A020F0  neon amethyst
    ToggleOn        = Color3.fromRGB(160, 32, 240),    -- #A020F0  neon amethyst (active)
    ToggleOff       = Color3.fromRGB(50, 50, 64),      -- muted slate (inactive)

    -- glassmorphism / glow ---------------------------------------------------
    PanelTransparency        = 0.30,  -- topbar / tabbar glass strength
    ElementTransparency      = 0.35,  -- resting glass strength for buttons etc.
    ElementHoverTransparency = 0.08,  -- glass strength on hover
    StrokeTransparency       = 1,     -- hidden neon edge by default
    StrokeHoverTransparency  = 0.35,  -- neon edge glow on hover/active
    WindowStrokeTransparency = 0.45,  -- always-on neon edge around the whole window

    -- layout --------------------------------------------------------------
    WindowSize      = UDim2.new(0.37, 0, 0.42, 0),
    WindowPosition  = UDim2.new(0.315, 0, 0.29, 0),

    TopbarHeight    = 40,
    TabBarWidth     = 130,
    ElementHeight   = 36,
}

-- =========================================================================
-- HELPERS
-- =========================================================================
local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

-- =========================================================================
-- WINDOW
-- =========================================================================
function module:win(title, themeOverrides)

    -- merge default theme + per-window overrides (without touching module.Theme)
    local theme = {}
    for k, v in pairs(module.Theme) do theme[k] = v end
    for k, v in pairs(themeOverrides or {}) do theme[k] = v end

    -- registry of {instance, property, themeKey} so SetTheme can re-apply colors live
    local registry = {}
    local function reg(inst, prop, key)
        inst[prop] = theme[key]
        table.insert(registry, {inst, prop, key})
        return inst
    end

    -- screen gui ------------------------------------------------------------
    local screenGui = create("ScreenGui", {
        Name = "CustomUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local hui = gethui or get_hidden_gui or nil
    screenGui.Parent = hui and hui() or cg

    -- main frame (CanvasGroup -> whole UI can fade together) ----------------
    local main = create("CanvasGroup", {
        Name = "Frame",
        Parent = screenGui,
        Size = theme.WindowSize,
        Position = theme.WindowPosition,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    reg(main, "BackgroundColor3", "Background")
    create("UICorner", {Parent = main, CornerRadius = theme.CornerRadius})

    -- always-on neon edge glow around the whole window -----------------------
    local mainStroke = create("UIStroke", {
        Parent = main,
        Thickness = 1,
        Transparency = theme.WindowStrokeTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    reg(mainStroke, "Color", "Accent")

    -- topbar ------------------------------------------------------------------
    local topbar = create("Frame", {
        Name = "topbar",
        Parent = main,
        Size = UDim2.new(1, 0, 0, theme.TopbarHeight),
        BackgroundTransparency = theme.PanelTransparency,
        BorderSizePixel = 0,
    })
    reg(topbar, "BackgroundColor3", "Topbar")
    create("UICorner", {Parent = topbar, CornerRadius = theme.CornerRadius})

    -- thin neon separator line between topbar and body -----------------------
    local topbarLine = create("Frame", {
        Name = "accentline",
        Parent = topbar,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.55,
    })
    reg(topbarLine, "BackgroundColor3", "Accent")

    local titleLbl = create("TextLabel", {
        Name = "title",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Text = title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    reg(titleLbl, "TextColor3", "Text")
    reg(titleLbl, "Font", "FontBold")

    -- topbar buttons (close / minimize) - drawn as text, no images needed --
    local btns = create("Frame", {
        Name = "btns",
        Parent = topbar,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 60, 0, 24),
    })
    create("UIListLayout", {
        Parent = btns,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
    })

    local function makeTopbarBtn(symbol)
        local btn = create("TextButton", {
            Parent = btns,
            Size = UDim2.new(0, 24, 0, 24),
            BackgroundTransparency = 1,
            Text = symbol,
            TextSize = 14,
            AutoButtonColor = false,
        })
        reg(btn, "TextColor3", "SubText")
        reg(btn, "Font", "Font")
        reg(btn, "BackgroundColor3", "ElementBg")
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

        btn.MouseEnter:Connect(function()
            ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementHoverTransparency}):Play()
            ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = theme.Accent}):Play()
        end)
        btn.MouseLeave:Connect(function()
            ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = theme.SubText}):Play()
        end)
        return btn
    end

    local minimizeBtn = makeTopbarBtn("–")
    local closeBtn = makeTopbarBtn("✕")

    -- open / minimize -------------------------------------------------------
    local function setOpen(isOpen)
        ts:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            GroupTransparency = isOpen and 0 or 1,
            Size = isOpen and theme.WindowSize
                or UDim2.new(theme.WindowSize.X.Scale, theme.WindowSize.X.Offset, 0, theme.TopbarHeight),
        }):Play()
        main.Interactable = isOpen
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        setOpen(false)
    end)

    local toggleKeyConn = ui.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.K then
            setOpen(not main.Interactable)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        toggleKeyConn:Disconnect()
        screenGui:Destroy()
    end)

    -- dragging via topbar -----------------------------------------------------
    do
        local dragging, dragInput, mousePos, framePos

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = main.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        topbar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        ui.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                main.Position = UDim2.new(
                    framePos.X.Scale, framePos.X.Offset + delta.X,
                    framePos.Y.Scale, framePos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- body: tab bar (left) + section container (right) ----------------------
    local body = create("Frame", {
        Name = "body",
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, theme.TopbarHeight),
        Size = UDim2.new(1, 0, 1, -theme.TopbarHeight),
    })

    local tabBar = create("ScrollingFrame", {
        Name = "tabbar",
        Parent = body,
        BorderSizePixel = 0,
        BackgroundTransparency = theme.PanelTransparency,
        Size = UDim2.new(0, theme.TabBarWidth, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
    })
    reg(tabBar, "BackgroundColor3", "TabBar")
    reg(tabBar, "ScrollBarImageColor3", "Accent")
    create("UIListLayout", {Parent = tabBar, Padding = UDim.new(0, 4)})
    create("UIPadding", {
        Parent = tabBar,
        PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    })

    local sectionsHolder = create("Frame", {
        Name = "sectionsholder",
        Parent = body,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, theme.TabBarWidth, 0, 0),
        Size = UDim2.new(1, -theme.TabBarWidth, 1, 0),
        ClipsDescendants = true,
    })

    -- =====================================================================
    -- TABS / SECTIONS
    -- =====================================================================
    local sections = {}
    local curBtn, curSection = nil, nil

    local function setSelectedTab(btn, section)
        if curBtn == btn then return end
        if curBtn then
            local curGlow = curBtn:FindFirstChild("glow")
            local curIndicator = curBtn:FindFirstChild("indicator")
            ts:Create(curBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            ts:Create(curIndicator, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            ts:Create(curGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeTransparency}):Play()
            curSection.Visible = false
        end
        local glow = btn:FindFirstChild("glow")
        local indicator = btn:FindFirstChild("indicator")
        ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementHoverTransparency}):Play()
        ts:Create(indicator, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        ts:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeHoverTransparency}):Play()
        section.Visible = true
        curBtn, curSection = btn, section
    end

    -- icon is OPTIONAL: pass nil for a pure text tab (no asset needed),
    -- or pass any image id/url if you want an icon.
    function sections:tab(title, icon)
        local btn = create("TextButton", {
            Parent = tabBar,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
        })
        reg(btn, "BackgroundColor3", "ElementBg")
        create("UICorner", {Parent = btn, CornerRadius = theme.ElementRadius})

        -- subtle neon edge glow, fades in when this tab is active -------------
        local glow = create("UIStroke", {
            Name = "glow",
            Parent = btn,
            Thickness = 1,
            Transparency = theme.StrokeTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        reg(glow, "Color", "Accent")

        local indicator = create("Frame", {
            Name = "indicator",
            Parent = btn,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 3, 0.6, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        reg(indicator, "BackgroundColor3", "Accent")
        create("UICorner", {Parent = indicator, CornerRadius = UDim.new(1, 0)})

        local label = create("TextLabel", {
            Parent = btn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, (icon and icon ~= "") and 36 or 12, 0, 0),
            Size = UDim2.new(1, (icon and icon ~= "") and -44 or -20, 1, 0),
            Text = title,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        reg(label, "TextColor3", "Text")
        reg(label, "Font", "Font")

        if icon and icon ~= "" then
            local iconLbl = create("ImageLabel", {
                Parent = btn,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
                Image = icon,
            })
            reg(iconLbl, "ImageColor3", "SubText")
        end

        btn.MouseEnter:Connect(function()
            if curBtn ~= btn then
                ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementTransparency}):Play()
                ts:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeHoverTransparency}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if curBtn ~= btn then
                ts:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                ts:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeTransparency}):Play()
            end
        end)

        -- section content -----------------------------------------------------
        local section = create("ScrollingFrame", {
            Name = title,
            Parent = sectionsHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            Visible = false,
        })
        reg(section, "ScrollBarImageColor3", "Accent")
        create("UIListLayout", {Parent = section, Padding = UDim.new(0, 6)})
        create("UIPadding", {
            Parent = section,
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        })

        btn.MouseButton1Click:Connect(function()
            setSelectedTab(btn, section)
        end)

        if not curBtn then
            setSelectedTab(btn, section)
        end

        -- =================================================================
        -- ELEMENTS
        -- =================================================================
        local contents = {}

        function contents:label(text)
            local lbl = create("TextLabel", {
                Parent = section,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Text = text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
            })
            reg(lbl, "TextColor3", "SubText")
            reg(lbl, "Font", "Font")
            return lbl
        end

        function contents:button(text, cb)
            local btnEl = create("TextButton", {
                Parent = section,
                Size = UDim2.new(1, 0, 0, theme.ElementHeight),
                BackgroundTransparency = theme.ElementTransparency,
                AutoButtonColor = false,
                Text = text,
                TextSize = 13,
            })
            reg(btnEl, "BackgroundColor3", "ElementBg")
            reg(btnEl, "TextColor3", "Text")
            reg(btnEl, "Font", "Font")
            create("UICorner", {Parent = btnEl, CornerRadius = theme.ElementRadius})

            -- neon edge glow that appears on hover ---------------------------
            local glow = create("UIStroke", {
                Parent = btnEl,
                Thickness = 1,
                Transparency = theme.StrokeTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            reg(glow, "Color", "Accent")

            btnEl.MouseEnter:Connect(function()
                ts:Create(btnEl, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementHoverTransparency}):Play()
                ts:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeHoverTransparency}):Play()
            end)
            btnEl.MouseLeave:Connect(function()
                ts:Create(btnEl, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementTransparency}):Play()
                ts:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeTransparency}):Play()
            end)
            btnEl.MouseButton1Click:Connect(cb)
            return btnEl
        end

        function contents:toggle(text, default, cb)
            local toggled = default and true or false

            local holder = create("TextButton", {
                Parent = section,
                Size = UDim2.new(1, 0, 0, theme.ElementHeight),
                BackgroundTransparency = theme.ElementTransparency,
                AutoButtonColor = false,
                Text = "",
            })
            reg(holder, "BackgroundColor3", "ElementBg")
            create("UICorner", {Parent = holder, CornerRadius = theme.ElementRadius})

            -- neon edge glow that appears on hover ---------------------------
            local hoverGlow = create("UIStroke", {
                Parent = holder,
                Thickness = 1,
                Transparency = theme.StrokeTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            reg(hoverGlow, "Color", "Accent")

            local lbl = create("TextLabel", {
                Parent = holder,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Text = text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            reg(lbl, "TextColor3", "Text")
            reg(lbl, "Font", "Font")

            local track = create("Frame", {
                Parent = holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 38, 0, 20),
                BorderSizePixel = 0,
            })
            create("UICorner", {Parent = track, CornerRadius = UDim.new(1, 0)})

            -- neon glow ring around the track that intensifies when active ----
            local trackGlow = create("UIStroke", {
                Parent = track,
                Thickness = 1,
                Transparency = 0.6,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            reg(trackGlow, "Color", "Accent")

            local knob = create("Frame", {
                Parent = track,
                AnchorPoint = toggled and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
                Position = toggled and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            })
            create("UICorner", {Parent = knob, CornerRadius = UDim.new(1, 0)})

            local function applyVisual(animated)
                local goalColor = toggled and theme.ToggleOn or theme.ToggleOff
                local goalGlow = toggled and 0.15 or 0.85
                local goalPos = toggled and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                local goalAnchor = toggled and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
                if animated then
                    ts:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = goalColor}):Play()
                    ts:Create(trackGlow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = goalGlow}):Play()
                    ts:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = goalPos}):Play()
                else
                    track.BackgroundColor3 = goalColor
                    trackGlow.Transparency = goalGlow
                    knob.Position = goalPos
                end
                knob.AnchorPoint = goalAnchor
            end
            applyVisual(false)

            holder.MouseEnter:Connect(function()
                ts:Create(holder, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementHoverTransparency}):Play()
                ts:Create(hoverGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeHoverTransparency}):Play()
            end)
            holder.MouseLeave:Connect(function()
                ts:Create(holder, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = theme.ElementTransparency}):Play()
                ts:Create(hoverGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeTransparency}):Play()
            end)

            holder.MouseButton1Click:Connect(function()
                toggled = not toggled
                applyVisual(true)
                cb(toggled)
            end)

            if toggled then
                task.defer(cb, toggled)
            end

            return holder
        end

        function contents:textbox(text, default, cb)
            local holder = create("Frame", {
                Parent = section,
                Size = UDim2.new(1, 0, 0, theme.ElementHeight),
                BackgroundTransparency = theme.ElementTransparency,
            })
            reg(holder, "BackgroundColor3", "ElementBg")
            create("UICorner", {Parent = holder, CornerRadius = theme.ElementRadius})

            local lbl = create("TextLabel", {
                Parent = holder,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.5, -12, 1, 0),
                Text = text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            reg(lbl, "TextColor3", "Text")
            reg(lbl, "Font", "Font")

            local inputBg = create("Frame", {
                Parent = holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.new(0.45, 0, 0, 24),
            })
            reg(inputBg, "BackgroundColor3", "ElementHoverBg")
            create("UICorner", {Parent = inputBg, CornerRadius = UDim.new(0, 6)})

            -- neon edge glow on the input field, brightens on focus -----------
            local focusGlow = create("UIStroke", {
                Parent = inputBg,
                Thickness = 1,
                Transparency = theme.StrokeTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            reg(focusGlow, "Color", "Accent")

            local input = create("TextBox", {
                Parent = inputBg,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                Text = default or "",
                PlaceholderText = "...",
                TextSize = 13,
                ClearTextOnFocus = false,
            })
            reg(input, "TextColor3", "Text")
            reg(input, "Font", "Font")

            input.Focused:Connect(function()
                ts:Create(focusGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeHoverTransparency}):Play()
            end)

            if default and default ~= "" then
                task.defer(cb, default)
            end

            input.FocusLost:Connect(function(enterPressed)
                ts:Create(focusGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = theme.StrokeTransparency}):Play()
                if enterPressed then
                    cb(input.Text)
                end
            end)

            return holder
        end

        function contents:slider(text, min, max, default, cb)
            local holder = create("Frame", {
                Parent = section,
                Size = UDim2.new(1, 0, 0, theme.ElementHeight + 14),
                BackgroundTransparency = theme.ElementTransparency,
            })
            reg(holder, "BackgroundColor3", "ElementBg")
            create("UICorner", {Parent = holder, CornerRadius = theme.ElementRadius})

            local lbl = create("TextLabel", {
                Parent = holder,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 4),
                Size = UDim2.new(1, -24, 0, 18),
                Text = text .. " : " .. tostring(default),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            reg(lbl, "TextColor3", "Text")
            reg(lbl, "Font", "Font")

            local track = create("Frame", {
                Parent = holder,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 28),
                Size = UDim2.new(1, -24, 0, 6),
                BorderSizePixel = 0,
            })
            reg(track, "BackgroundColor3", "ElementHoverBg")
            create("UICorner", {Parent = track, CornerRadius = UDim.new(1, 0)})

            local fill = create("Frame", {
                Parent = track,
                Size = UDim2.new(0, 0, 1, 0),
                BorderSizePixel = 0,
            })
            reg(fill, "BackgroundColor3", "Accent")
            create("UICorner", {Parent = fill, CornerRadius = UDim.new(1, 0)})

            -- soft neon glow following the fill -------------------------------
            local fillGlow = create("UIStroke", {
                Parent = fill,
                Thickness = 1,
                Transparency = 0.3,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            reg(fillGlow, "Color", "Accent")

            local dragging = false
            local lastVal = default

            local function setFromAlpha(alpha)
                alpha = math.clamp(alpha, 0, 1)
                local value = math.floor(min + (max - min) * alpha + 0.5)
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                lastVal = value
                lbl.Text = text .. " : " .. tostring(value)
            end

            local function updateFromInput(x)
                local rel = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
                setFromAlpha(rel)
            end

            setFromAlpha((default - min) / (max - min))

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X)
                end
            end)

            ui.InputEnded:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    if cb then
                        pcall(cb, lastVal)
                    end
                end
            end)

            return holder
        end

        return contents
    end

    -- live re-theming: change colors/fonts/sizes after the UI was built ----
    function sections:SetTheme(overrides)
        for k, v in pairs(overrides) do
            theme[k] = v
        end
        for _, entry in ipairs(registry) do
            local inst, prop, key = entry[1], entry[2], entry[3]
            if inst and inst.Parent then
                inst[prop] = theme[key]
            end
        end
    end

    function sections:GetTheme()
        return theme
    end

    return sections
end

return module
