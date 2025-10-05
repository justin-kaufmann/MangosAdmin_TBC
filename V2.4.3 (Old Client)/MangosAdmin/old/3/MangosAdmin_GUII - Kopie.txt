-- ========== Hauptfenster ==========
local f = CreateFrame("Frame", "MangosAdmin_Main", UIParent)
-- Schließen-Button (X)
local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT")
-- ESC soll das Fenster schließen
tinsert(UISpecialFrames, f:GetName())

-- Standardwert, falls noch nichts gespeichert ist
if not MangosAdminDB then MangosAdminDB = {} end
if not MangosAdminDB.minimapAngle then MangosAdminDB.minimapAngle = 45 end

local MA_MinimapButton = CreateFrame("Button", "MangosAdmin_MinimapButton", Minimap)
MA_MinimapButton:SetWidth(32)
MA_MinimapButton:SetHeight(32)
MA_MinimapButton:SetFrameStrata("MEDIUM")
MA_MinimapButton:SetFrameLevel(8)
MA_MinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local icon = MA_MinimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01") -- Zahnrad
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER")

-- Position aktualisieren
local function UpdateButtonPos()
  local angle = MangosAdminDB.minimapAngle
  local radius = (Minimap:GetWidth()/2) - 5
  local x = cos(angle) * radius
  local y = sin(angle) * radius
  MA_MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
UpdateButtonPos()

-- Dragging
MA_MinimapButton:RegisterForDrag("LeftButton")
MA_MinimapButton:SetScript("OnDragStart", function(self)
  self:SetScript("OnUpdate", function()
    local mx, my = GetCursorPosition()
    local cx, cy = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    mx, my = mx/scale, my/scale
    MangosAdminDB.minimapAngle = math.deg(math.atan2(my - cy, mx - cx))
    UpdateButtonPos()
  end)
end)
MA_MinimapButton:SetScript("OnDragStop", function(self)
  self:SetScript("OnUpdate", nil)
end)

-- Klick öffnet/schließt dein Hauptfenster f
MA_MinimapButton:SetScript("OnClick", function()
  if f:IsShown() then
    f:Hide()
  else
    f:Show()
  end
end)

MA_MinimapButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("MangosAdmin")
  GameTooltip:AddLine("Linksklick: Fenster öffnen/schließen", 1, 1, 1)
  GameTooltip:AddLine("Ziehen: Symbol verschieben", 1, 1, 1)
  GameTooltip:Show()
end)
MA_MinimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

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

-- Scroll + Scrollbar (match panel width)
local innerPadding = 10
local scrollWidth = panel:GetWidth() - innerPadding*2 - 18  -- ~542 usable + room for scrollbar
local scrollHeight = panel:GetHeight() - innerPadding*2     -- 460

local scroll = CreateFrame("ScrollFrame", "MangosAdmin_SF", panel)
scroll:SetWidth(scrollWidth); scroll:SetHeight(scrollHeight)
scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", innerPadding, -innerPadding)

local content = CreateFrame("Frame", "MangosAdmin_Content", scroll)
content:SetWidth(scrollWidth); content:SetHeight(scrollHeight)
scroll:SetScrollChild(content)

local scrollbar = CreateFrame("Slider", "MangosAdmin_ScrollBar", panel, "OptionsSliderTemplate")
scrollbar:SetWidth(16); scrollbar:SetHeight(scrollHeight)
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
  local new = CreateFrame("Frame", nil, scroll)  -- namenlos, TBC-sicher
  new:SetWidth(scrollWidth); new:SetHeight(scrollHeight)
  scroll:SetScrollChild(new)
  currentContent:Hide()
  currentContent = new
end

local function SetScrollHeight(total)
  if total < scrollHeight then total = scrollHeight end
  currentContent:SetHeight(total)
  scrollbar:SetMinMaxValues(0, total - scrollHeight)
  scrollbar:SetValue(0)
  scroll:SetVerticalScroll(0)
end

local function CreateRow(parent, y)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(scrollWidth - 24)  -- leave some margin
  row:SetHeight(46)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  return row
end

-- Eingabefeld mit Label in eigenem Container
--! 

-- Eingabefeld in eigenem Container mit eigenem Rahmen (ohne InputBoxTemplate)
local function CreateEdit(parent, x, y, labelText, width)
  local w = width or 120

  local container = CreateFrame("Frame", nil, parent)
  container:SetWidth(w)
  container:SetHeight(40) -- genug Platz für Label + Box
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

  -- Label
  local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
  label:SetText(labelText or "")

  -- Rahmen-Box
  local box = CreateFrame("Frame", nil, container)
  box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
  box:SetWidth(w)
  box:SetHeight(22)
  box:SetBackdrop({
    bgFile  = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile= "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  box:SetBackdropColor(0, 0, 0, 0.8)

  -- EditBox innen (ohne Template)
  local edit = CreateFrame("EditBox", nil, box)
  edit:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -3)
  edit:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -6, 3)
  edit:SetAutoFocus(false)
  edit:SetMultiLine(false)
  edit:SetFontObject(GameFontHighlight)
  edit:SetTextInsets(0, 0, 0, 0)
  edit:SetMaxLetters(256)
  edit:EnableMouse(true)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  -- Hilfs-API wie zuvor
  function edit:SetValueText(t) self:SetText(t or "") end

  return edit, container
end


-- Einfaches, eigenes Dropdown ohne UIDropDownMenu
--[[local MA_DROPDOWN_ID = 0
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
  local sfName = "MangosAdmin_DDScroll"..MA_DROPDOWN_ID
  local sf = CreateFrame("ScrollFrame", sfName, list, "UIPanelScrollFrameTemplate")

  sf:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 6)

  local listContent = CreateFrame("Frame", nil, sf) -- parent the child to the scrollframe
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
end]]

-- Dropdown mit Suchfeld + Scrollbar (TBC-sicher, benannte Frames)
--[[local MA_DROPDOWN_ID = 0
local function CreateSimpleDropdown(parent, left, top, width, options, onChange)
  MA_DROPDOWN_ID = MA_DROPDOWN_ID + 1

  local btnName = "MangosAdmin_Dropdown"..MA_DROPDOWN_ID
  local listName = "MangosAdmin_DDList"..MA_DROPDOWN_ID
  local sfName   = "MangosAdmin_DDScroll"..MA_DROPDOWN_ID

  local dd = CreateFrame("Button", btnName, parent, "UIPanelButtonTemplate")
  dd:SetWidth(width)
  dd:SetHeight(22)
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
  dd:SetText("Auswahl")

  local opts = options or {}
  local selectedValue, selectedText

  -- Popup-Liste
  local list = CreateFrame("Frame", listName, parent)
  list:SetFrameStrata("DIALOG")
  list:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}
  })
  list:SetBackdropColor(0,0,0,0.95)
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetWidth(width + 40)
  list:SetHeight(220) -- feste Höhe für Suchfeld + ca. 10 Einträge
  list:Hide()

  -- Suchfeld
  local searchBox = CreateFrame("EditBox", listName.."_Search", list, "InputBoxTemplate")
  searchBox:SetWidth(width)
  searchBox:SetHeight(20)
  searchBox:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
  searchBox:SetAutoFocus(false)

  -- ScrollFrame MUSS benannt sein bei UIPanelScrollFrameTemplate (TBC-Anforderung)
  local sf = CreateFrame("ScrollFrame", sfName, list, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -6)
  sf:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 6)

  local listContent = CreateFrame("Frame", listName.."_Content", sf)
  listContent:SetWidth(width + 22)
  sf:SetScrollChild(listContent)

  local buttons = {}
  local rowH = 18

  local function RefreshButtons(filtered)
    for _, b in ipairs(buttons) do b:Hide() end
    buttons = {}

    for i, opt in ipairs(filtered) do
      local b = CreateFrame("Button", listName.."_Item"..i, listContent)
      b:SetHeight(rowH)
      b:SetPoint("TOPLEFT", listContent, "TOPLEFT", 2, -(i-1)*rowH)
      b:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", -2, -(i-1)*rowH)

      local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetAllPoints(b)
      fs:SetJustifyH("LEFT")
      fs:SetText(opt.text or "")
      b:SetFontString(fs)

      b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      b:GetHighlightTexture():SetBlendMode("ADD")

      b:SetScript("OnClick", function()
        selectedValue = opt.value
        selectedText  = opt.text
        dd:SetText(selectedText or "Auswahl")
        list:Hide()
        if onChange then onChange(selectedValue, selectedText) end
      end)

      table.insert(buttons, b)
    end

    listContent:SetHeight(#filtered * rowH)
  end

  local function ApplyFilter()
    local text = searchBox:GetText()
    text = text and text:lower() or ""
    local filtered = {}
    for _, opt in ipairs(opts) do
      local t = opt.text or ""
      if text == "" or string.find(t:lower(), text, 1, true) then
        table.insert(filtered, opt)
      end
    end
    RefreshButtons(filtered)
    sf:SetVerticalScroll(0)
  end

  searchBox:SetScript("OnTextChanged", ApplyFilter)

  -- Öffnen/Schließen
  dd:SetScript("OnClick", function()
    if list:IsShown() then
      list:Hide()
    else
      list:Show()
      searchBox:SetText("")
      ApplyFilter()
      searchBox:ClearFocus()
    end
  end)

  list:SetScript("OnHide", function()
    sf:SetVerticalScroll(0)
  end)

  -- Initialauswahl
  if #opts > 0 then
    selectedValue = opts[1].value
    selectedText  = opts[1].text
    dd:SetText(selectedText or "Auswahl")
  else
    dd:SetText("Auswahl")
  end
  -- Buttons initial bauen (auch wenn Liste zu ist)
  searchBox:SetText("")
  ApplyFilter()

  return {
    frame = dd,
    list = list,
    get = function() return selectedValue, selectedText end,
    setOptions = function(newOptions)
      opts = newOptions or {}
      if #opts > 0 then
        selectedValue = opts[1].value
        selectedText  = opts[1].text
        dd:SetText(selectedText or "Auswahl")
      else
        selectedValue, selectedText = nil, nil
        dd:SetText("Auswahl")
      end
      searchBox:SetText("")
      ApplyFilter()
    end
  }
end]]

-- Dropdown mit Suchfeld + Scrollbar (TBC-sicher, immer im Vordergrund)
--[[local MA_DROPDOWN_ID = 0
local function CreateSimpleDropdown(parent, left, top, width, options, onChange)
  MA_DROPDOWN_ID = MA_DROPDOWN_ID + 1

  local btnName = "MangosAdmin_Dropdown"..MA_DROPDOWN_ID
  local listName = "MangosAdmin_DDList"..MA_DROPDOWN_ID
  local sfName   = "MangosAdmin_DDScroll"..MA_DROPDOWN_ID

  local dd = CreateFrame("Button", btnName, parent, "UIPanelButtonTemplate")
  dd:SetWidth(width)
  dd:SetHeight(22)
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
  dd:SetText("Auswahl")

  local opts = options or {}
  local selectedValue, selectedText

  -- Popup-Liste
  local list = CreateFrame("Frame", listName, UIParent) -- wichtig: UIParent, nicht parent
  list:SetFrameStrata("TOOLTIP")                        -- ganz nach vorne
  list:SetFrameLevel(parent:GetFrameLevel() + 50)       -- höher als Hauptfenster
  list:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}
  })
  list:SetBackdropColor(0,0,0,0.95)
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetWidth(width + 40)
  list:SetHeight(220)
  list:Hide()

  -- Suchfeld
  local searchBox = CreateFrame("EditBox", listName.."_Search", list, "InputBoxTemplate")
  searchBox:SetWidth(width)
  searchBox:SetHeight(20)
  searchBox:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
  searchBox:SetAutoFocus(false)

  -- ScrollFrame (benannt, TBC-sicher)
  local sf = CreateFrame("ScrollFrame", sfName, list, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -6)
  sf:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 6)

  local listContent = CreateFrame("Frame", listName.."_Content", sf)
  listContent:SetWidth(width + 22)
  sf:SetScrollChild(listContent)

  local buttons = {}
  local rowH = 18

  local function RefreshButtons(filtered)
    for _, b in ipairs(buttons) do b:Hide() end
    buttons = {}

for i, opt in ipairs(filtered) do
      local b = CreateFrame("Button", listName.."_Item"..i, listContent)
      b:SetHeight(rowH)
      b:SetPoint("TOPLEFT", listContent, "TOPLEFT", 2, -(i-1)*rowH)
      b:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", -2, -(i-1)*rowH)
      b:SetFrameLevel(list:GetFrameLevel() + 1)

      local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetAllPoints(b)
      fs:SetJustifyH("LEFT")

      -- Kategorien/Subkategorien/Items unterschiedlich darstellen
      if opt.kind == "category" then
        fs:SetText("|cffffff00"..opt.text.."|r")
        b:Disable()
      elseif opt.kind == "sub" then
        fs:SetText("  + "..opt.text)
        b:Disable()
      elseif opt.kind == "item" then
        fs:SetText("    - "..opt.text)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        b:GetHighlightTexture():SetBlendMode("ADD")

        b:SetScript("OnEnter", function()
          if opt.value then
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:"..opt.value)
          end
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)

        b:SetScript("OnClick", function()
          selectedValue = opt.value
          selectedText  = opt.text
          dd:SetText(selectedText or "Auswahl")
          list:Hide()
          if onChange then onChange(selectedValue, selectedText) end
        end)
      end

	  b:SetFontString(fs)
      table.insert(buttons, b)
    end

    listContent:SetHeight(#filtered * rowH)
  end

  local function ApplyFilter()
    local text = searchBox:GetText()
    text = text and text:lower() or ""
    local filtered = {}
    for _, opt in ipairs(opts) do
      local t = opt.text or ""
      if text == "" or string.find(t:lower(), text, 1, true) then
        table.insert(filtered, opt)
      end
    end
    RefreshButtons(filtered)
    sf:SetVerticalScroll(0)
  end

  searchBox:SetScript("OnTextChanged", ApplyFilter)

  -- Öffnen/Schließen
dd:SetScript("OnClick", function()
    if list:IsShown() then
        list:Hide()
    else
        -- beim Öffnen: Optionen neu laden, Auswahl beibehalten
        if dd.setOptions and cmd.optionsFunc then
            dd.setOptions(cmd.optionsFunc())
        end

        list:Show()

        -- Suchfeld leeren und gleich fokussieren
        searchBox:SetText("")
        ApplyFilter()
        searchBox:SetFocus()
    end
end)

list:SetScript("OnHide", function()
    -- Scroll zurücksetzen
    sf:SetVerticalScroll(0)
    -- Tooltip sicherheitshalber schließen
    GameTooltip:Hide()
end)


  -- Initialauswahl
  if #opts > 0 then
    selectedValue = opts[1].value
    selectedText  = opts[1].text
    dd:SetText(selectedText or "Auswahl")
  else
    dd:SetText("Auswahl")
  end
  searchBox:SetText("")
  ApplyFilter()

  return {
    frame = dd,
    list = list,
    get = function() return selectedValue, selectedText end,

	setOptions = function(newOptions)
	  local prev = selectedValue
	  opts = newOptions or {}

	  -- Versuche, die bisherige Auswahl zu bewahren
	  selectedValue, selectedText = nil, nil
	  if prev ~= nil then
		for _, opt in ipairs(opts) do
		  if opt.value == prev then
			selectedValue = opt.value
			selectedText  = opt.text
			break
		  end
		end
	  end

	  -- Wenn keine vorige Auswahl oder nicht mehr vorhanden → nimm ersten Eintrag (falls vorhanden)
	  if not selectedValue then
		if #opts > 0 then
		  selectedValue = opts[1].value
		  selectedText  = opts[1].text
		else
		  selectedValue, selectedText = nil, nil
		end
	  end

	  dd:SetText(selectedText or "Auswahl")
	  searchBox:SetText("")
	  ApplyFilter()
	end
  }
end]]

-- Lagfreies Dropdown mit Suchfeld und FauxScrollFrame (TBC-sicher, eigener Update-Driver)
local MA_DROPDOWN_ID = 0
function CreateSimpleDropdown(parent, left, top, width, options, onChange)
  MA_DROPDOWN_ID = MA_DROPDOWN_ID + 1

  local ddName   = "MangosAdmin_Dropdown"..MA_DROPDOWN_ID
  local listName = "MangosAdmin_DDList"..MA_DROPDOWN_ID
  local fsName   = "MangosAdmin_DDFaux"..MA_DROPDOWN_ID

  local dd = CreateFrame("Button", ddName, parent, "UIPanelButtonTemplate")
  dd:SetWidth(width)
  dd:SetHeight(22)
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
  dd:SetText("Auswahl")

  local opts = options or {}
  local selectedValue, selectedText

  -- Popup-Liste
  local list = CreateFrame("Frame", listName, UIParent)
  list:SetFrameStrata("TOOLTIP")
  list:SetFrameLevel((parent:GetFrameLevel() or 1) + 50)
  list:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}
  })
  list:SetBackdropColor(0,0,0,0.95)
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetWidth(width + 40)
  list:SetHeight(260)
  list:Hide()

  -- Suchfeld
  local searchBox = CreateFrame("EditBox", listName.."_Search", list, "InputBoxTemplate")
  searchBox:SetWidth(width)
  searchBox:SetHeight(20)
  searchBox:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
  searchBox:SetAutoFocus(false)

  -- FauxScrollFrame (kein Blizzard-Update mehr verwenden)
  local scrollFrame = CreateFrame("ScrollFrame", fsName, list, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 6)

  local scrollBar = _G[fsName.."ScrollBar"]
  local scrollUpBtn = _G[scrollBar:GetName().."ScrollUpButton"]
  local scrollDownBtn = _G[scrollBar:GetName().."ScrollDownButton"]

  -- Konstanten
  local VISIBLE_ROWS = 12
  local ROW_HEIGHT   = 18

  -- Für TBC: Hinweise zur Zeilenhöhe am Frame und als Global hinterlegen
  scrollFrame.buttonHeight = ROW_HEIGHT
  _G[fsName.."ButtonHeight"] = ROW_HEIGHT

  local buttons = {}
  local filtered = {}

  -- 12 Buttons recyceln
  for i = 1, VISIBLE_ROWS do
    local b = CreateFrame("Button", listName.."_Row"..i, list)
    b:SetHeight(ROW_HEIGHT)
    b:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 2, -(i-1)*ROW_HEIGHT)
    b:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -(i-1)*ROW_HEIGHT)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetAllPoints(b)
    fs:SetJustifyH("LEFT")
    b.text = fs

    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    b:GetHighlightTexture():SetBlendMode("ADD")

    buttons[i] = b
  end

  -- Render der sichtbaren 12 Zeilen basierend auf dem Faux-Offset
  local function RefreshButtons()
    local offset = FauxScrollFrame_GetOffset(scrollFrame) or 0
    for i = 1, VISIBLE_ROWS do
      local index = offset + i
      local opt = filtered[index]
      local b = buttons[i]

      if opt then
        b:Show()
        b.opt = opt
        local label = opt.text or ""

        if opt.kind == "category" then
          b.text:SetText("|cffffff00"..label.."|r")
          b:Disable()
          b:SetScript("OnEnter", nil)
          b:SetScript("OnLeave", nil)
          b:SetScript("OnClick", nil)

        elseif opt.kind == "sub" then
          b.text:SetText("  + "..label)
          b:Disable()
          b:SetScript("OnEnter", nil)
          b:SetScript("OnLeave", nil)
          b:SetScript("OnClick", nil)

        else -- item
          b.text:SetText("    - "..label)
          b:Enable()

          b:SetScript("OnEnter", function(self)
            local o = self.opt
            if o and o.value then
              GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
              GameTooltip:SetHyperlink("item:"..o.value)
            end
          end)
          b:SetScript("OnLeave", function() GameTooltip:Hide() end)
          b:SetScript("OnClick", function(self)
            local o = self.opt
            selectedValue = o and o.value or nil
            selectedText  = o and o.text or nil
            dd:SetText(selectedText or "Auswahl")
            list:Hide()
            if onChange and selectedValue then onChange(selectedValue, selectedText) end
          end)
        end
      else
        b:Hide()
        b.opt = nil
        b:SetScript("OnEnter", nil)
        b:SetScript("OnLeave", nil)
        b:SetScript("OnClick", nil)
      end
    end
  end
  scrollFrame.update = RefreshButtons

  -- Eigener, TBC-sicherer Faux-Update-Driver (ersetzt FauxScrollFrame_Update)
  local function MA_FauxUpdate(totalItems)
    -- Immer >= 1 für Blizzard-Frames
    local total = (totalItems and totalItems > 0) and totalItems or 1
    local rows  = VISIBLE_ROWS
    local step  = ROW_HEIGHT

    local maxScroll = math.max(0, (total - rows) * step)

    -- aktuellen ScrollValue clampen
    local cur = scrollBar:GetValue() or 0
    if cur < 0 then cur = 0 end
    if cur > maxScroll then cur = maxScroll end

    scrollBar:SetMinMaxValues(0, maxScroll)
    scrollBar:SetValueStep(step)
    scrollBar:SetValue(cur)

    -- Up/Down Buttons aktivieren/deaktivieren
    if cur <= 0 then scrollUpBtn:Disable() else scrollUpBtn:Enable() end
    if cur >= maxScroll then scrollDownBtn:Disable() else scrollDownBtn:Enable() end

    -- Faux-Offset aus Scrollbar ableiten
    local offset = math.floor((cur / step) + 0.5)
    FauxScrollFrame_SetOffset(scrollFrame, offset)

    RefreshButtons()
  end

  -- Scroll-Ereignisse: Mausrad + Drag
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = ROW_HEIGHT * 3 -- schneller scrollen
    local newVal = (scrollBar:GetValue() or 0) - delta * step
    local min, max = scrollBar:GetMinMaxValues()
    if newVal < min then newVal = min end
    if newVal > max then newVal = max end
    scrollBar:SetValue(newVal)
    -- Offset + Buttons aktualisieren
    local offset = math.floor((newVal / ROW_HEIGHT) + 0.5)
    FauxScrollFrame_SetOffset(scrollFrame, offset)
    RefreshButtons()
  end)

  scrollBar:SetScript("OnValueChanged", function(self, value)
    local offset = math.floor((value / ROW_HEIGHT) + 0.5)
    FauxScrollFrame_SetOffset(scrollFrame, offset)
    RefreshButtons()
  end)

  -- Filter
  local function ApplyFilter()
    local q = (searchBox:GetText() or ""):lower()
    filtered = {}
    for _, opt in ipairs(opts) do
      local t = opt.text or ""
      if q == "" or t:lower():find(q, 1, true) then
        table.insert(filtered, opt)
      end
    end
    MA_FauxUpdate(#filtered)
  end

  searchBox:SetScript("OnTextChanged", ApplyFilter)
  scrollFrame:SetScript("OnShow", RefreshButtons)

  -- Öffnen/Schließen
  dd:SetScript("OnClick", function()
    if list:IsShown() then
      list:Hide()
    else
      list:Show()
      searchBox:SetText("")
      ApplyFilter()
      searchBox:SetFocus()
    end
  end)

  list:SetScript("OnHide", function()
    GameTooltip:Hide()
  end)

  -- Initialauswahl
  if #opts > 0 then
    selectedValue = opts[1].value
    selectedText  = opts[1].text
    dd:SetText(selectedText or "Auswahl")
  else
    dd:SetText("Auswahl")
  end
  ApplyFilter()

  return {
    frame = dd,
    list = list,
    get = function() return selectedValue, selectedText end,
    setOptions = function(newOptions)
      local prev = selectedValue
      opts = newOptions or {}

      selectedValue, selectedText = nil, nil
      if prev ~= nil then
        for _, o in ipairs(opts) do
          if o.value == prev then
            selectedValue = o.value
            selectedText  = o.text
            break
          end
        end
      end
      if not selectedValue and #opts > 0 then
        selectedValue = opts[1].value
        selectedText  = opts[1].text
      end

      dd:SetText(selectedText or "Auswahl")
      ApplyFilter()
    end
  }
end


local function BuildCategory(cat)
  ResetContent()
  local y = -10
  local totalHeight = 10

  for _, cmd in ipairs(cat.commands) do
    local row = CreateRow(currentContent, y)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 6, 0)
    lbl:SetText(cmd.label or "Command")

    local run = CreateFrame("Button", "MangosAdmin_RunBtn"..math.random(100000), row, "UIPanelButtonTemplate")
    run:SetWidth(80); run:SetHeight(22)
    run:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    run:SetText("Run")

    if cmd.type == "toggle" then
      run:SetScript("OnClick", function()
        if cmd.toggle then cmd.toggle() end
      end)

    elseif cmd.type == "button" then
      run:SetScript("OnClick", function()
        local built = cmd.build and cmd.build()
        if built then
          if MangosAdmin then
            -- centralize through SendGM for consistent UI feedback
            local ok, _ = pcall(function() SendChatMessage("", "SAY") end) -- noop to satisfy Lua upvalue usage
          end
          -- call core sender
          if SendGM then SendGM(built) end
        else
          if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültiger/Leerer Befehl") end
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
		  yOff = yOff - 42 -- neue Zeile, genug Abstand
		  row:SetHeight(row:GetHeight() + 42)
		end

		local e, container = CreateEdit(row, x, yOff, inp.label or inp.key, w)
		inputs[inp.key] = e
		x = x + w + 18
	  end

	  run:SetScript("OnClick", function()
		local a = {}
		for _, inp in ipairs(cmd.inputs or {}) do
		  a[inp.key] = inputs[inp.key]:GetText()
		end
		local built = cmd.build and cmd.build(a)
		if built then
		  if SendGM then SendGM(built) end
		else
		  DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Ungültige Eingaben.")
		end
	  end)

    --[[elseif cmd.type == "select" then
      local dd = CreateSimpleDropdown(row, 220, 0, 160, cmd.options or {}, function(val, text)
        if cmd.onChange then cmd.onChange(val, text) end
      end)

      run:SetScript("OnClick", function()
        local val, text = dd.get()
        local built = cmd.build and cmd.build({ value = val, text = text })
        if built then
          if SendGM then SendGM(built) end
        else
          DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Keine gültige Auswahl.")
        end
      end)
    end]]
	
	elseif cmd.type == "select" then
		local opts = cmd.options or (cmd.optionsFunc and cmd.optionsFunc()) or {}

		local dd = CreateSimpleDropdown(row, 220, 0, 160, opts, function(val, text)
			if cmd.onChange then
				cmd.onChange(val, text)
			end
		end)

		-- Automatischer Refresh für Items
		if cmd.optionsFunc == MangosAdmin.GetItemOptions then
			local refresher = function()
				if dd.setOptions then
					dd.setOptions(MangosAdmin.GetItemOptions())
				end
			end
			MangosAdmin.RegisterItemInfoListener(refresher)
		end

		run:SetScript("OnClick", function()
			local val, text = dd.get()
			local built = cmd.build and cmd.build({ value = val, text = text })
			if built then
				if SendGM then SendGM(built) end
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Keine gültige Auswahl.")
			end
		end)
	end



    y = y - row:GetHeight() + -2
    totalHeight = totalHeight + row:GetHeight() + 2
  end

  SetScrollHeight(totalHeight + 10)
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

  if firstCat then
    BuildCategory(firstCat.cat)
    local fs = firstCat.btn:GetFontString()
    if fs then fs:SetTextColor(0.6, 1.0, 0.6) end
  end
end

CreateCategoryButtons()