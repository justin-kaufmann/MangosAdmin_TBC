-- ========= GUI Helpers =========
MangosAdmin = MangosAdmin or {}
MangosAdmin.UI = MangosAdmin.UI or {}

function MangosAdmin.ResetContent()
  local ui = MangosAdmin.UI
  local new = CreateFrame("Frame", nil, ui.scroll)
  new:SetWidth(ui.scrollWidth); new:SetHeight(ui.scrollHeight)
  ui.scroll:SetScrollChild(new)
  if ui.currentContent then ui.currentContent:Hide() end
  ui.currentContent = new
  return new
end

function MangosAdmin.SetScrollHeight(total)
  local ui = MangosAdmin.UI
  if total < ui.scrollHeight then total = ui.scrollHeight end
  ui.currentContent:SetHeight(total)
  ui.scrollbar:SetMinMaxValues(0, total - ui.scrollHeight)
  ui.scrollbar:SetValue(0)
  ui.scroll:SetVerticalScroll(0)
end

function MangosAdmin.CreateRow(parent, y)
  local ui = MangosAdmin.UI
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(ui.scrollWidth - 24)
  row:SetHeight(46)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  return row
end

function MangosAdmin.CreateEdit(parent, x, y, labelText, width)
  local w = width or 120

  local container = CreateFrame("Frame", nil, parent)
  container:SetWidth(w)
  container:SetHeight(40)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

  local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
  label:SetText(labelText or "")

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

  function edit:SetValueText(t) self:SetText(t or "") end

  return edit, container
end