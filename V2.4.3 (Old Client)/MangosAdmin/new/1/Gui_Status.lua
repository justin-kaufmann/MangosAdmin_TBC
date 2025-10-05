-- ========= Status-Label (Fly: AN/AUS) =========
MangosAdmin = MangosAdmin or {}

function MangosAdmin.CreateStatusLabel(parent)
  MangosAdmin_StatusLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  MangosAdmin_StatusLabel:SetPoint("TOP", parent, "TOP", 0, -34)
  MangosAdmin_StatusLabel:SetText("Fly: AUS")
  return MangosAdmin_StatusLabel
end