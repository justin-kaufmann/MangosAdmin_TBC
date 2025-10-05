-- ========= GuiCategories.lua =========
MangosAdmin = MangosAdmin or {}
MangosAdmin.UI = MangosAdmin.UI or {}

local function BuildCategory(cat)
  local ui = MangosAdmin.UI
  MangosAdmin.ResetContent()
  local y = -10
  local totalHeight = 10
  local parent = ui.currentContent

  for _, cmd in ipairs(cat.commands) do
    local row = MangosAdmin.CreateRow(parent, y)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 6, 0)
    lbl:SetText(cmd.label or "Command")

    local run = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    run:SetWidth(80); run:SetHeight(22)
    run:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    run:SetText("Run")

    if cmd.type == "toggle" then
      run:SetScript("OnClick", function()
        if cmd.toggle then cmd.toggle() end
      end)

    elseif cmd.type == "button" then
      run:SetScript("OnClick", function()
        if cmd.toggle then
          cmd.toggle()
        elseif cmd.build then
          local built = cmd.build()
          if built and MangosAdmin.SendGM then
            MangosAdmin.SendGM(built)
          else
            if DEFAULT_CHAT_FRAME then
              DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültiger/Leerer Befehl")
            end
          end
        end
      end)

    elseif cmd.type == "input" then
      local x, yOff = 220, 0
      local maxWidth = row:GetWidth() - 100
      local inputs = {}

      for _, inp in ipairs(cmd.inputs or {}) do
        local w = inp.width or 110
        if x + w > maxWidth then
          x = 220
          yOff = yOff - 42
          row:SetHeight(math.max(row:GetHeight(), -yOff + 42))
        end

        local e, container = MangosAdmin.CreateEdit(row, x, yOff, inp.label or inp.key, w)
        inputs[inp.key] = e
        e:SetScript("OnEnterPressed", function() run:Click() end)
        x = x + w + 18
      end

      run:SetScript("OnClick", function()
        local a = {}
        for _, inp in ipairs(cmd.inputs or {}) do
          a[inp.key] = inputs[inp.key]:GetText()
        end
        local built = cmd.build and cmd.build(a)
        if built and MangosAdmin.SendGM then
          MangosAdmin.SendGM(built)
        else
          if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültige Eingaben.")
          end
        end
      end)

    elseif cmd.type == "select" then
      local opts = (cmd.options and cmd.options) or (cmd.optionsFunc and cmd.optionsFunc()) or {}

      local dd = CreateSimpleDropdown(row, 220, 0, 160, opts, function(val, text)
        if cmd.onChange then cmd.onChange(val, text) end
      end)

      -- Refresh für Items
      if cmd.optionsFunc == MangosAdmin.GetItemOptions then
        local refresher = function()
          if dd.setOptions then
            dd.setOptions(MangosAdmin.GetItemOptions())
          end
        end
        if MangosAdmin.RegisterItemInfoListener then
          MangosAdmin.RegisterItemInfoListener(refresher)
        end
      end

      -- Refresh für Itemsets
      if cmd.optionsFunc == MangosAdmin.GetItemsetOptions then
        local refresher = function()
          if dd.setOptions then
            dd.setOptions(MangosAdmin.GetItemsetOptions())
          end
        end
        if MangosAdmin.RegisterItemInfoListener then
          MangosAdmin.RegisterItemInfoListener(refresher)
        end
      end

      run:SetScript("OnClick", function()
        local val, text = dd.get()
        local built = cmd.build and cmd.build({ value = val, text = text })
        if built and MangosAdmin.SendGM then
          MangosAdmin.SendGM(built)
        else
          if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Keine gültige Auswahl.")
          end
        end
      end)
    end

    y = y - row:GetHeight() - 2
    totalHeight = totalHeight + row:GetHeight() + 2
  end

  MangosAdmin.SetScrollHeight(totalHeight + 10)
end

function MangosAdmin.CreateCategoryButtons()
  if not MangosAdmin or not MangosAdmin.Registry then return end
  local sidebar = MangosAdmin.UI.sidebar
  local y = -10
  local firstCat = nil

  for _, cat in ipairs(MangosAdmin.Registry) do
    local b = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    b:SetWidth(206); b:SetHeight(24)
    b:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, y)
    b:SetText(cat.category or "Kategorie")
    b:SetScript("OnClick", function()
      BuildCategory(cat)
      local kids = { sidebar:GetChildren() }
      for _, k in ipairs(kids) do
        local fs = k:GetFontString()
        if fs then fs:SetTextColor(1, 0.82, 0) end
      end
      local fs = b:GetFontString()
      if fs then fs:SetTextColor(0.6, 1.0, 0.6) end
    end)
    local fs = b:GetFontString()
    if fs then fs:SetTextColor(1, 0.82, 0) end

    if not firstCat then
      firstCat = { btn=b, cat=cat }
    end
    y = y - 28
  end

  if firstCat then
    BuildCategory(firstCat.cat)
    local fs = firstCat.btn:GetFontString()
    if fs then fs:SetTextColor(0.6, 1.0, 0.6) end
  end
end
