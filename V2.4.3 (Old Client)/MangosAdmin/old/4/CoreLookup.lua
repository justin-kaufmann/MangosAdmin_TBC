-- ================= Dynamic Lookup Indexer & Parser =================
MangosAdminDB = MangosAdminDB or { spells = {}, items = {}, quests = {}, teles = {} }

local MAX_RESULTS = 50
local MAQ = { queue = {}, running = false, cur = nil, nextAt = 0, total=0, done=0 }
local lastCount = 0

MA_LastLookupTag = MA_LastLookupTag
MA_LastLookupExpiry = MA_LastLookupExpiry or 0

local function Enqueue(prefix, tag)
  table.insert(MAQ.queue, { prefix = prefix, tag = tag })
  MAQ.total = MAQ.total + 1
end

local function currentLookupTag()
  if MAQ.running and MAQ.cur then
    return MAQ.cur
  end
  if MA_LastLookupTag and GetTime() <= (MA_LastLookupExpiry or 0) then
    return MA_LastLookupTag
  end
  return nil
end

local function ParseLookupLine(msg)
  if not msg then return end

  local dbgTag = currentLookupTag()
  if dbgTag then
    DEFAULT_CHAT_FRAME:AddMessage(("DEBUG[%s]: "):format(dbgTag)..msg)
  end

  msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

  local tag = currentLookupTag()
  if not tag then return end

  local id, name = msg:match("^(%d+)%s*%-%s*(.+)$")
  if id and name then
    local nid = tonumber(id)
    if tag == "spell" then MangosAdminDB.spells[nid] = name end
    if tag == "item"  then MangosAdminDB.items[nid]  = name end
    if tag == "quest" then MangosAdminDB.quests[nid] = name end
    lastCount = lastCount + 1
    return
  end

  local tname, key = msg:match("Teleport%s+location:%s*([^%(%-]+)%s*%(([^%)]*)%)")
  if tname and key and tag == "tele" then
    MangosAdminDB.teles[key] = tname:gsub("%s+$","")
    lastCount = lastCount + 1
  end
end

local MA_EventFrame = CreateFrame("Frame")
MA_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
MA_EventFrame:RegisterEvent("CHAT_MSG_SERVER_INFO")
MA_EventFrame:SetScript("OnEvent", function(self, event, msg)
    ParseLookupLine(msg)
end)

local statusFrame = CreateFrame("Frame", "MA_IndexStatus", UIParent)
statusFrame:SetWidth(260); statusFrame:SetHeight(60)
statusFrame:SetPoint("CENTER")
statusFrame:SetBackdrop({
  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
  tile=true, tileSize=16, edgeSize=16,
  insets={left=4,right=4,top=4,bottom=4}
})
statusFrame:Hide()
local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statusText:SetPoint("CENTER")

local function UpdateStatus()
  if MAQ.running then
    statusText:SetText("Indexiere "..(MAQ.cur or "?").." ("..MAQ.done.."/"..MAQ.total..")")
    statusFrame:Show()
  else
    statusFrame:Hide()
  end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
  if GetTime() < MAQ.nextAt then return end
  if not MAQ.running then return end
  local job = table.remove(MAQ.queue, 1)
  if not job then
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Indexierung abgeschlossen: "..(MAQ.cur or ""))
    MAQ.running = false
    UpdateStatus()
    return
  end
  lastCount = 0
  MA_LastLookupTag = job.tag
  MA_LastLookupExpiry = GetTime() + 5

  SendGM(".lookup "..job.tag.." "..job.prefix)
  MAQ.done = MAQ.done + 1
  UpdateStatus()
  MAQ.nextAt = GetTime() + 0.7
end)

function MangosAdmin.BuildIndex(kind)
  if MAQ.running then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffdd55[MA]|r Bereits am Indexieren …")
    return
  end

  if kind == "item"  then MangosAdminDB.items  = {} end
  if kind == "spell" then MangosAdminDB.spells = {} end
  if kind == "quest" then MangosAdminDB.quests = {} end
  if kind == "tele"  then MangosAdminDB.teles  = {} end

  MAQ.running = true
  MAQ.cur = kind
  MAQ.queue = {}
  MAQ.total, MAQ.done = 0, 0
  for c = string.byte("a"), string.byte("z") do Enqueue(string.char(c), kind) end
  for d = 0,9 do Enqueue(tostring(d), kind) end
  DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[MA]|r Starte Indexierung: "..kind)
  MAQ.nextAt = 0
  UpdateStatus()
end

-- Optionen für Dropdowns (ohne Items, die sind in Items.lua)
local function mapToOptionsFromKV(store, makeValueText)
  local opts = {}
  for k, v in pairs(store) do
    local val, txt = makeValueText(k, v)
    table.insert(opts, { value = val, text = txt })
  end
  table.sort(opts, function(a,b) return a.text < b.text end)
  return opts
end

function MangosAdmin.GetSpellOptions()
  return mapToOptionsFromKV(MangosAdminDB.spells, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetQuestOptions()
  return mapToOptionsFromKV(MangosAdminDB.quests, function(id, name) return id, name.." ("..id..")" end)
end

function MangosAdmin.GetTeleOptions()
  local t = {}
  for key, name in pairs(MangosAdminDB.teles) do
    table.insert(t, { value = key, text = name.." ("..key..")" })
  end
  table.sort(t, function(a,b) return a.text < b.text end)
  return t
end