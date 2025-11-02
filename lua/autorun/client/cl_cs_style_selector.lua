-- Clean BHOP Style Selector (minimal, stable)
-- Opens via chat: !style !styles !mode !modes, console: cs_styles / cs_styles_cl, and server net message.
-- Shows all Core.Config.Style entries (sorted by ID) + Random button (after first) + highlights current & last chosen.

-- luacheck: globals surface draw vgui net hook concommand Color ScrW ScrH LocalPlayer IsValid cookie chat RunConsoleCommand TOP FILL
local NETMSG = "cs_open_style_selector"
local FRAME
local LAST_COOKIE_KEY = "cs_last_style"

-- Fonts (matching gamemode Cinzel fonts)
surface.CreateFont("CSStyle_Title", { font = "Cinzel", size = 34, weight = 800 })
-- Doubled button fonts (was 18 / 15)
surface.CreateFont("CSStyle_Item", { font = "Cinzel", size = 24, weight = 700 })
surface.CreateFont("CSStyle_ItemSmall", { font = "Cinzel", size = 20, weight = 700 })
surface.CreateFont("CSStyle_ItemTiny", { font = "Cinzel", size = 16, weight = 700 })

-- Gamemode theming colors
local gold1 = Color(214, 177, 64)
local gold2 = Color(235, 205, 95)
local darkBg = Color(20, 18, 12)
local darkBg2 = Color(35, 30, 18)
local buttonLight = Color(50, 45, 30)
local buttonDark = Color(40, 35, 22)
local textColor = Color(185, 185, 185)
local textLight = Color(230, 230, 230)

-- Button accent colors (complementing gold/dark theme)
local buttonColors = {
    Color(70, 120, 150),   -- Blue
    Color(80, 140, 100),   -- Green
    Color(150, 110, 60),   -- Orange
    Color(140, 80, 80),    -- Red
    Color(120, 90, 140),   -- Purple
    Color(130, 130, 70),   -- Yellow-green
    Color(100, 120, 140),  -- Slate blue
    Color(120, 100, 80),   -- Brown
    Color(110, 130, 120),  -- Teal
    Color(130, 100, 110)   -- Mauve
}

local function FetchStyles()
    local tab = {}
    local cfg = Core and Core.Config and Core.Config.Style
    if not cfg then return tab end
    for name,id in pairs(cfg) do
        if tonumber(id) then
            local display = Core.StyleName and Core.StyleName(id) or name
            tab[#tab+1] = { id = id, name = display }
        end
    end
    table.SortByMember(tab, "id", true)
    return tab
end

local function OpenSelector()
    if IsValid(FRAME) then FRAME:Remove() end

    local styles = FetchStyles()
    FRAME = vgui.Create("DFrame")
    local f = FRAME
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(false)
    f:SetSize(math.min(ScrW()*0.70, 1100), math.min(ScrH()*0.60, 580))
    f:Center()
    f:MakePopup()

    f.Paint = function(self,w,h)
        -- Draw textured background similar to gamemode windows
        surface.SetDrawColor(darkBg)
        surface.DrawRect(0, 0, w, h)
        
        -- Add subtle gradient effect
        for i = 0, h, 4 do
            local alpha = math.floor((i / h) * 15)
            surface.SetDrawColor(Color(40, 35, 20, alpha))
            surface.DrawRect(0, i, w, 4)
        end
        
        -- Add fine line texture pattern
        surface.SetDrawColor(Color(214, 177, 64, 8))
        for i = 0, h, 2 do
            surface.DrawRect(0, i, w, 1)
        end
        
        -- Outer elegant border (gold)
        surface.SetDrawColor(gold1)
        surface.DrawRect(0, 0, w, 2)              -- Top border
        surface.DrawRect(0, h - 2, w, 2)          -- Bottom border
        surface.DrawRect(0, 0, 2, h)              -- Left border
        surface.DrawRect(w - 2, 0, 2, h)          -- Right border
        
        -- Inner frame accent line
        surface.SetDrawColor(Color(214, 177, 64, 60))
        surface.DrawRect(2, 2, w - 4, 1)
        surface.DrawRect(2, h - 3, w - 4, 1)
        surface.DrawRect(2, 2, 1, h - 4)
        surface.DrawRect(w - 3, 2, 1, h - 4)
        
        -- Draw title background
        surface.SetDrawColor(darkBg2)
        surface.DrawRect(0, 0, w, 52)
        
        -- Title texture overlay
        for i = 0, 52, 2 do
            surface.SetDrawColor(Color(214, 177, 64, 5))
            surface.DrawRect(0, i, w, 1)
        end
        
        -- Title accent line
        surface.SetDrawColor(Color(214, 177, 64, 90))
        surface.DrawRect(0, 50, w, 2)
        
        -- Title text
        draw.SimpleText("BHOP STYLE SELECTOR", "CSStyle_Title", w/2, 26, gold1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local btnClose = vgui.Create("DButton", f)
    btnClose:SetSize(34,34)
    btnClose:SetPos(f:GetWide()-42,6)
    btnClose:SetText("✕")
    btnClose:SetFont("CSStyle_Item")
    btnClose.DoClick = function() f:Remove() end
    btnClose.Paint = function(self,w,h)
        -- Match gamemode close button styling
        surface.SetDrawColor(Color(50, 45, 30))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(gold1)
        surface.DrawOutlinedRect(0, 0, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(gold2)
            surface.DrawOutlinedRect(1, 1, w-2, h-2)
        end
        draw.SimpleText("✕", "CSStyle_Item", w/2, h/2, textLight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local header = vgui.Create("DPanel", f)
    header:Dock(TOP)
    header:DockMargin(12,58,12,6)
    header:SetTall(38)
    header.Paint = function(p,w,h)
        -- Header background with gamemode styling
        surface.SetDrawColor(darkBg2)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(gold1)
        surface.DrawOutlinedRect(0, 0, w, h)
        
        -- Inner accent line
        surface.SetDrawColor(Color(214, 177, 64, 60))
        surface.DrawRect(1, 1, w - 2, 1)
        surface.DrawRect(1, h - 2, w - 2, 1)
        
        local lp = LocalPlayer()
        local sname = (lp.Style and Core.StyleName and Core.StyleName(lp.Style)) or "Normal"
        draw.SimpleText(lp:Nick() .. "  |  " .. sname, "CSStyle_Item", w/2, h/2, gold1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local canvas = vgui.Create("DPanel", f)
    canvas:Dock(FILL)
    canvas:DockMargin(12,0,12,6)
    canvas.Paint = function() end
    local buttons = {}

    -- Instruction text at the bottom
    local instructText = vgui.Create("DPanel", f)
    instructText:Dock(BOTTOM)
    instructText:DockMargin(12,0,12,12)
    instructText:SetTall(20)
    instructText.Paint = function(p,w,h)
        draw.SimpleText("Right-click any style to set it as your default", "CSStyle_ItemSmall", w/2, h/2, gold1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local lastStyle = tonumber(cookie.GetString(LAST_COOKIE_KEY, "0")) or 0

    local function AddStyleButton(index, data)
        local b = vgui.Create("DButton", canvas)
        b:SetSize(150,60)
        b:SetText("")
        b.StyleID = data.id
        b.Label = string.upper(data.name)
        b.ButtonColor = buttonColors[(index - 1) % #buttonColors + 1]
        b.Paint = function(self,w,h)
            local isCurrent = LocalPlayer().Style == self.StyleID
            local isLast = self.StyleID == lastStyle
            
            -- Main button background with button color accent
            surface.SetDrawColor(buttonDark)
            surface.DrawRect(0, 0, w, h)
            
            -- Colored accent overlay for style variety
            surface.SetDrawColor(Color(self.ButtonColor.r, self.ButtonColor.g, self.ButtonColor.b, 100))
            surface.DrawRect(1, 1, w - 2, h - 2)
            
            -- Main border (gold)
            surface.SetDrawColor(gold1)
            surface.DrawOutlinedRect(0, 0, w, h)
            
            -- Inner accent border for current/last selected
            if isCurrent then
                surface.SetDrawColor(Color(100, 180, 180, 150))
                surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
            elseif isLast then
                surface.SetDrawColor(gold2)
                surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
            end
            
            -- Add texture lines to match window background
            surface.SetDrawColor(Color(214, 177, 64, 5))
            for i = 0, h, 4 do
                surface.DrawRect(0, i, w, 1)
            end
            
            -- Dynamic font sizing based on label length and button size
            local font = "CSStyle_Item"
            surface.SetFont(font)
            local textW, textH = surface.GetTextSize(self.Label)
            
            -- If text is too wide, use smaller font
            if textW > w - 10 then
                font = "CSStyle_ItemSmall"
                surface.SetFont(font)
                textW, textH = surface.GetTextSize(self.Label)
                
                -- If still too wide, use tiny font
                if textW > w - 10 then
                    font = "CSStyle_ItemTiny"
                    surface.SetFont(font)
                    textW, textH = surface.GetTextSize(self.Label)
                end
            end
            
            draw.SimpleText(self.Label, font, w/2, h/2, textLight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function(self)
            cookie.Set(LAST_COOKIE_KEY, tostring(self.StyleID))
            RunConsoleCommand("style", tostring(self.StyleID))
            f:Remove()
        end
        b.DoRightClick = function(self)
            net.Start("cs_set_default_style")
            net.WriteInt(self.StyleID, 32)
            net.SendToServer()
            
            -- Check if this is the Normal style (ID 1)
            if self.StyleID == 1 then
                chat.AddText(gold1, "[Style Selector] ", Color(255,255,255), "Default style cleared! You will now start with ", gold2, "NORMAL", Color(255,255,255), " on join.")
            else
                chat.AddText(gold1, "[Style Selector] ", Color(255,255,255), "Set ", gold2, self.Label, Color(255,255,255), " as your default style!")
            end
        end
        table.insert(buttons, b)
    end

    for i, st in ipairs(styles) do
        AddStyleButton(i, st)
        if i == 1 then
            local rb = vgui.Create("DButton", canvas)
            rb:SetSize(150,60)
            rb:SetText("")
            rb.Label = "RANDOM"
            rb.Paint = function(self,w,h)
                surface.SetDrawColor(buttonLight)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(gold1)
                surface.DrawOutlinedRect(0, 0, w, h)
                
                -- Add texture lines
                surface.SetDrawColor(Color(214, 177, 64, 5))
                for i = 0, h, 4 do
                    surface.DrawRect(0, i, w, 1)
                end
                
                -- Dynamic font sizing for random button (keeping text bold)
                local font = "CSStyle_Item"
                surface.SetFont(font)
                local textW, textH = surface.GetTextSize(self.Label)
                
                if textW > w - 10 then
                    font = "CSStyle_ItemSmall"
                    surface.SetFont(font)
                    textW, textH = surface.GetTextSize(self.Label)
                    
                    if textW > w - 10 then
                        font = "CSStyle_ItemTiny"
                        surface.SetFont(font)
                        textW, textH = surface.GetTextSize(self.Label)
                    end
                end
                
                draw.SimpleText(self.Label, font, w/2, h/2, textLight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            rb.DoClick = function()
                if #styles == 0 then return end
                local pick = styles[math.random(#styles)]
                cookie.Set(LAST_COOKIE_KEY, tostring(pick.id))
                RunConsoleCommand("style", tostring(pick.id))
                chat.AddText(gold1, "Random picked: ", Color(255,255,255), pick.name)
                f:Remove()
            end
            table.insert(buttons, rb)
        end
    end

    -- Centered manual layout (stable) - DYNAMIC HEIGHT VERSION
    local BTN_W, BTN_H, SPACING = 150, 60, 12
    local layoutDirty = true
    local performing = false
    local function MarkDirty() layoutDirty = true end

    local function ComputeAvailableWidth()
        local wpanel = canvas:GetWide() or 0
        if wpanel < BTN_W + SPACING*2 then
            wpanel = math.max(BTN_W + SPACING*2, (f:GetWide() - 48))
        end
        return wpanel
    end

    local function LayoutButtons()
        if performing or not layoutDirty or not IsValid(canvas) then return end
        performing = true
        layoutDirty = false
        local available = ComputeAvailableWidth()
        local y = 0
        local row = {}
        local function FlushRow()
            if #row == 0 then return end
            local totalW = #row * BTN_W + (#row - 1) * SPACING
            local startX = math.floor((available - totalW) / 2)
            for i, btn in ipairs(row) do
                if IsValid(btn) then
                    btn:SetPos(startX + (i-1)*(BTN_W+SPACING), y)
                end
            end
            y = y + BTN_H + SPACING
            row = {}
        end
        for _, btn in ipairs(buttons) do
            if IsValid(btn) then
                if #row == 0 then
                    row[1] = btn
                else
                    local projected = (#row + 1) * BTN_W + #row * SPACING
                    if projected > available then
                        FlushRow()
                        row[1] = btn
                    else
                        row[#row+1] = btn
                    end
                end
            end
        end
        FlushRow()
        canvas:SetTall(math.max(0, y - SPACING))
        
        -- Dynamically adjust frame height based on canvas height
        local headerHeight = 38
        local instructHeight = 20
        local margins = 58 + 6 + 6 + 12 + 50 -- top spacing + header margin + canvas margin + instruction margin + extra bottom padding
        local canvasHeight = canvas:GetTall()
        local totalContentHeight = margins + headerHeight + canvasHeight + instructHeight
        
        -- Cap the height to screen height
        local maxHeight = math.min(ScrH()*0.95, totalContentHeight)
        f:SetTall(maxHeight)
        f:Center()
        
        performing = false
    end

    -- Hooks to keep layout stable
    f.OnSizeChanged = function()
        MarkDirty(); LayoutButtons()
    end
    canvas.OnSizeChanged = function()
        MarkDirty(); LayoutButtons()
    end
    -- Initial layout
    MarkDirty(); LayoutButtons()
end

net.Receive(NETMSG, OpenSelector)

hook.Add("OnPlayerChat", "CS_StyleSelector_Fallback", function(ply, text)
    if ply ~= LocalPlayer() then return end
    local t = string.lower(string.Trim(text or ""))
    if t == "!style" or t == "!styles" or t == "!mode" or t == "!modes" then
        if not IsValid(FRAME) then OpenSelector() end
    end
end)

concommand.Add("cs_styles_cl", OpenSelector)
concommand.Add("cs_styles", OpenSelector)
