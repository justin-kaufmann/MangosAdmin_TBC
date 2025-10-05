-- Eindeutiger Namenszähler für Dropdowns
local MA_DROPDOWN_ID = 0
local function NextDropName()
  MA_DROPDOWN_ID = MA_DROPDOWN_ID + 1
  return "MangosAdmin_Drop"..MA_DROPDOWN_ID
end

-- ========== Hauptfenster ==========
local f = CreateFrame("Frame", "MangosAdmin_Main", UIParent)
f:SetWidth(1000)
f:SetHeight(600)
f:SetPoint("CENTER")
f:SetBackdrop({
  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
  tile=true, tileSize=32, edgeSize=32,
  insets={left=11,right=12,top=12,bottom=11}
})
f:SetBackdropColor(0,0,0,1)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()

local title = f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
title:SetPoint("TOP", f, "TOP", 0, -10)
title:SetText("Mangos Admin [TBC]  —  /madmin  |  /gmraw <command>")

-- Seitenleiste
local sidebar = CreateFrame("Frame", nil, f)
sidebar:SetWidth(230); sidebar:SetHeight(480)
sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -44)
sidebar:SetBackdrop({
  bgFile="Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
sidebar:SetBackdropColor(0,0,0,0.5)

-- Panel rechts
local panel = CreateFrame("Frame", nil, f)
panel:SetWidth(580); panel:SetHeight(480)
panel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -44)
panel:SetBackdrop({
  bgFile="Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
panel:SetBackdropColor(0,0,0,0.35)

-- Scroll + Scrollbar
local scroll = CreateFrame("ScrollFrame", "MangosAdmin_SF", panel)
scroll:SetWidth(752); scroll:SetHeight(460)
scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)

local content = CreateFrame("Frame", "MangosAdmin_Content", scroll)
content:SetWidth(752); content:SetHeight(460)
scroll:SetScrollChild(content)

local scrollbar = CreateFrame("Slider", "MangosAdmin_ScrollBar", panel, "OptionsSliderTemplate")
scrollbar:SetWidth(16); scrollbar:SetHeight(460)
scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
scrollbar:SetMinMaxValues(0, 0)
scrollbar:SetValueStep(10)
_G[scrollbar:GetName().."Low"]:SetText("")
_G[scrollbar:GetName().."High"]:SetText("")
_G[scrollbar:GetName().."Text"]:SetText("")
scrollbar:SetScript("OnValueChanged", function(self, val)
  scroll:SetVerticalScroll(val)
end)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
  local cur = scrollbar:GetValue()
  local min, max = scrollbar:GetMinMaxValues()
  cur = cur - delta*30
  if cur < min then cur = min end
  if cur > max then cur = max end
  scrollbar:SetValue(cur)
end)

-- Raw Command
local rawLabel = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
rawLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 18)
rawLabel:SetText("Custom Command:")

local rawEdit = CreateFrame("EditBox", "MangosAdmin_Raw", f, "InputBoxTemplate")
rawEdit:SetWidth(640); rawEdit:SetHeight(20)
rawEdit:SetPoint("LEFT", rawLabel, "RIGHT", 10, 0)
rawEdit:SetAutoFocus(false)

local rawBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
rawBtn:SetWidth(120); rawBtn:SetHeight(22)
rawBtn:SetPoint("LEFT", rawEdit, "RIGHT", 8, 0)
rawBtn:SetText("Ausführen")
rawBtn:SetScript("OnClick", function()
  local t = rawEdit:GetText()
  if t and t ~= "" and MangosAdmin and MangosAdmin.ExecRaw then
    MangosAdmin.ExecRaw(t)
  end
end)

-- Fly-Status
MangosAdmin_StatusLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MangosAdmin_StatusLabel:SetPoint("TOP", f, "TOP", 0, -34)
MangosAdmin_StatusLabel:SetText("Fly: AUS")

-- ===== Helpers =====
local currentContent = content

local function ResetContent()
  -- local new = CreateFrame("Frame", "MangosAdmin_Content_"..GetTime(), scroll)
  local new = CreateFrame("Frame", nil, scroll)  -- namenlos, sicher in TBC


  new:SetWidth(752); new:SetHeight(460)
  scroll:SetScrollChild(new)
  currentContent:Hide()
  currentContent = new
end

local function SetScrollHeight(total)
  if total < 460 then total = 460 end
  currentContent:SetHeight(total)
  scrollbar:SetMinMaxValues(0, total - 460)
  scrollbar:SetValue(0)
  scroll:SetVerticalScroll(0)
end

local function CreateRow(parent, y)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(536); row:SetHeight(46)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  return row
end

local function SafeFont(name, fallback)
  local f = _G[name]
  return f or _G[fallback] or GameFontNormal
end

local function CreateEdit(parent, x, labelText, width)
  -- Label
  local label = parent:CreateFontString(nil, "OVERLAY")
  label:SetFontObject(GameFontNormal)  -- TBC-sicher
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -2)
  label:SetText(labelText or "")

  -- Wrapper mit Backdrop
  local box = CreateFrame("Frame", nil, parent)
  box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
  box:SetWidth(width or 110)
  box:SetHeight(20)
  box:SetBackdrop({
    bgFile  = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile= "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  box:SetBackdropColor(0, 0, 0, 0.6)

  -- EditBox innen
  local edit = CreateFrame("EditBox", nil, box)
  edit:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -2)
  edit:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 2)
  edit:SetAutoFocus(false)
  edit:SetTextInsets(0, 0, 0, 0)
  edit:SetFontObject(GameFontHighlight)
  edit:SetMaxLetters(256)
  edit:EnableMouse(true)

  box:SetFrameLevel(parent:GetFrameLevel() + 1)
  edit:SetFrameLevel(box:GetFrameLevel() + 1)

  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  function edit:SetValueText(t) self:SetText(t or "") end

  return edit
end

-- Einfaches, eigenes Dropdown ohne UIDropDownMenu
local function CreateSimpleDropdown(parent, left, top, width, options, onChange)
  MA_DROPDOWN_ID = MA_DROPDOWN_ID + 1
  local dd = CreateFrame("Button", "MangosAdmin_Dropdown"..MA_DROPDOWN_ID, parent, "UIPanelButtonTemplate")
  dd:SetWidth(width)
  dd:SetHeight(22)
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
  dd:SetText("Auswahl")

  local opts = options or {}
  local selectedIndex = (#opts > 0) and 1 or nil
  local selectedValue = selectedIndex and opts[selectedIndex].value or nil
  local selectedText  = selectedIndex and opts[selectedIndex].text  or "Auswahl"
  dd:SetText(selectedText)

  -- Popup-Liste
  local list = CreateFrame("Frame", "MangosAdmin_DDList"..MA_DROPDOWN_ID, parent)

  list:SetFrameStrata("DIALOG")
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}
  })
  list:SetBackdropColor(0,0,0,0.95)
  list:Hide()

  -- ScrollFrame
  local listContent = CreateFrame("Frame", nil, list)
  local sfName = "MangosAdmin_DDScroll"..MA_DROPDOWN_ID  -- TBC: Template braucht einen Namen
  local sf = CreateFrame("ScrollFrame", sfName, list, "UIPanelScrollFrameTemplate")

  sf:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 6)
  sf:SetScrollChild(listContent)

  local buttons = {}
  local rowH, visRows = 18, 12

  local function SetListSize()
    local rows = math.min(#opts, visRows)
    list:SetWidth(width + 40)
    list:SetHeight(rows * rowH + 12)
    listContent:SetWidth(width + 22)
    listContent:SetHeight(#opts * rowH)
  end

  local function RefreshButtons()
    for _, b in ipairs(buttons) do b:Hide() end
    buttons = {}

    for i, opt in ipairs(opts) do
      local b = CreateFrame("Button", nil, listContent)
      b:SetHeight(rowH)
      b:SetPoint("TOPLEFT", listContent, "TOPLEFT", 2, -(i-1)*rowH)
      b:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", -2, -(i-1)*rowH)

      -- FontString für Text
      local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetAllPoints(b)
      fs:SetJustifyH("LEFT")
      fs:SetText(opt.text or "")
      b:SetFontString(fs)

      b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      b:GetHighlightTexture():SetBlendMode("ADD")

      b:SetScript("OnClick", function()
        selectedIndex = i
        selectedValue = opt.value
        selectedText  = opt.text
        dd:SetText(selectedText)
        list:Hide()
        if onChange then onChange(selectedValue, selectedText) end
      end)

      table.insert(buttons, b)
    end
  end

  dd:SetScript("OnClick", function()
    if list:IsShown() then list:Hide() else list:Show() end
  end)
  list:SetScript("OnHide", function() sf:SetVerticalScroll(0) end)

  SetListSize()
  RefreshButtons()

  return {
    frame = dd,
    list = list,
    get = function() return selectedValue, selectedText end,
    setOptions = function(newOptions)
      opts = newOptions or {}
      selectedIndex = (#opts > 0) and 1 or nil
      selectedValue = selectedIndex and opts[selectedIndex].value or nil
      selectedText  = selectedIndex and opts[selectedIndex].text  or "Auswahl"
      dd:SetText(selectedText)
      SetListSize()
      RefreshButtons()
    end
  }
end


local function BuildCategory(cat)
  ResetContent()
  local y = -10

  for _, cmd in ipairs(cat.commands) do
    local row = CreateRow(currentContent, y)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 6, 0)
    lbl:SetText(cmd.label or "Command")

    local run = CreateFrame("Button", "MangosAdmin_RunBtn"..math.random(100000), row, "UIPanelButtonTemplate")
    run:SetWidth(80); run:SetHeight(22)
    run:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    run:SetText("Run")

    -- Toggle
    if cmd.type == "toggle" then
      run:SetScript("OnClick", function()
        if cmd.toggle then cmd.toggle() end
      end)

    -- Button
    elseif cmd.type == "button" then
      run:SetScript("OnClick", function()
        --local built = cmd.build and cmd.build()
		local built = cmd.build and cmd.build({ value = val, text = text })
        if built then
          SendChatMessage(built, "SAY")
          DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r "..built)
        end
      end)

    -- Input
    elseif cmd.type == "input" then
      local x, yOff = 220, 0
      local maxWidth = 700
      local inputs = {}

      for _, inp in ipairs(cmd.inputs or {}) do
        if x + (inp.width or 110) > maxWidth then
          x = 220
          yOff = yOff - 28
        end
        local e = CreateEdit(row, x, inp.label or inp.key, inp.width or 110)
        e:SetPoint("TOPLEFT", row, "TOPLEFT", x, yOff)
        inputs[inp.key] = e
        x = x + (inp.width or 110) + 18
      end

      run:SetScript("OnClick", function()
        local a = {}
        for _, inp in ipairs(cmd.inputs or {}) do
          a[inp.key] = inputs[inp.key]:GetText()
        end
        local built = cmd.build and cmd.build(a)
        if built then
          SendChatMessage(built, "SAY")
          DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r "..built)
        else
          DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültige Eingaben.")
        end
      end)

    -- Select (Dropdown)
    elseif cmd.type == "select" then
      local dd = CreateSimpleDropdown(row, 220, 0, 160, cmd.options or {}, function(val, text)
        if cmd.onChange then cmd.onChange(val, text) end
      end)

	  run:SetScript("OnClick", function()
	  local val, text = dd.get()
	  local built = cmd.build and cmd.build({ value = val, text = text })
	  if built then
		SendChatMessage(built, "SAY")
		DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r "..built)
	  else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Keine gültige Auswahl.")
	  end
	 end)
    end

    y = y - 32
  end
end




-- Kategorien-Buttons
local function CreateCategoryButtons()
  if not MangosAdmin or not MangosAdmin.Registry then return end
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

    if not firstCat then firstCat = { btn=b, cat=cat } end
    y = y - 28
  end

  -- Standard: erste Kategorie
  if firstCat then
    BuildCategory(firstCat.cat)
    local fs = firstCat.btn:GetFontString()
    if fs then fs:SetTextColor(0.6, 1.0, 0.6) end
  end
end

CreateCategoryButtons()
