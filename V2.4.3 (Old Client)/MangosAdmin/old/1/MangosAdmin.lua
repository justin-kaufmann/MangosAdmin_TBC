-- Status merken
local flyEnabled = false

-- Slash-Befehl registrieren
SLASH_GMTEST1 = "/gmtest"
SlashCmdList["GMTEST"] = function()
  if flyEnabled then
    -- Fly off
    SendChatMessage(".gm fly off", "SAY")
    DEFAULT_CHAT_FRAME:AddMessage(">>> GM Fly OFF gesendet <<<")
    flyEnabled = false
  else
    -- Fly on
    SendChatMessage(".gm fly on", "SAY")
    DEFAULT_CHAT_FRAME:AddMessage(">>> GM Fly ON gesendet <<<")
    flyEnabled = true
  end
end
