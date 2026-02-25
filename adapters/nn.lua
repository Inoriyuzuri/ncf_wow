--============================================================
-- NCF Adapter: Nn (NoName) Unlocker
-- 填充 NCF.API 为 Nn 解锁器实现
--============================================================
local Nn = ...
local API = NCF.API

API.CastSpell = function(name, target)
    if target then
        CastSpellByName(name, target)
    else
        CastSpellByName(name)
    end
end

API.UseItem = function(name)
    Unlock(UseItemByName, name)
end

API.ClickAt = ClickPosition

API.GetObjects = function()
    return ObjectManager("Unit" or 5) or {}
end

API.GetObjectType = ObjectType

API.GetPosition = ObjectPosition

API.GetFacing = ObjectFacing

API.GetDistance = Distance

API.GetCombatReach = CombatReach

API.RayTrace = TraceLine

API.SetFacing = function(angle)
    SetPlayerFacing(angle, true)
end

API.IsMouselooking = IsMouselooking

API.MouselookStart = MouselookStart

API.StopTargeting = function()
    Unlock(SpellStopTargeting)
end

API.UseSlotItem = function(slot)
    Unlock(UseInventoryItem, slot)
end

API.ReadFile = ReadFile

API.WriteFile = function(path, data)
    return WriteFile(path, data, false)
end

API.FileExists = FileExists

API.LoadModule = function(path)
    return Nn:Require(path)
end

API.HttpRequest = function(opts)
    HTTP:Request(opts)
end

API.AntiAFK = function()
    UpdateLastHardwareAction(GetTime() * 1000)
end
