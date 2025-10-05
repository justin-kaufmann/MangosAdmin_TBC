-- ================= Slash Commands =================
SLASH_MANGOSADMIN1 = "/madmin"
SlashCmdList["MANGOSADMIN"] = function()
    if MangosAdmin_Main and MangosAdmin_Main:IsShown() then
        MangosAdmin_Main:Hide()
    else
        if MangosAdmin_Main then MangosAdmin_Main:Show() end
    end
end

SLASH_GMRAW1 = "/gmraw"
SlashCmdList["GMRAW"] = function(msg)
    if msg and msg ~= "" then
        MangosAdmin.ExecRaw(msg)
    end
end