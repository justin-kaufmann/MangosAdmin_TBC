-- ================= CoreSlash.lua =================

-- /madmin: Hauptfenster ein-/ausblenden
SLASH_MANGOSADMIN1 = "/madmin"
SLASH_MANGOSADMIN2 = "/ma"   -- optionaler Alias
SlashCmdList["MANGOSADMIN"] = function()
    if not MangosAdmin_Main then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Hauptfenster nicht verfügbar.")
        end
        return
    end
    if MangosAdmin_Main:IsShown() then
        MangosAdmin_Main:Hide()
    else
        MangosAdmin_Main:Show()
    end
end

-- /gmraw: Rohbefehl direkt an den Server senden
SLASH_GMRAW1 = "/gmraw"
SlashCmdList["GMRAW"] = function(msg)
    if not msg or msg == "" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r Kein Befehl angegeben.")
        end
        return
    end
    if MangosAdmin and MangosAdmin.ExecRaw then
        MangosAdmin.ExecRaw(msg)
    else
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[MA]|r ExecRaw nicht verfügbar.")
        end
    end
end
