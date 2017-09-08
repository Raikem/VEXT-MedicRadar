class "MedicRadarClient"

function MedicRadarClient:__init()
  self.m_ClearUI = NetEvents:Subscribe('medicradar:clearui', self, self.OnClearUI)
  self.m_ShowUI = NetEvents:Subscribe('medicradar:showui', self, self.OnShowUI)
  self.m_OnLoadedEvent = Events:Subscribe('ExtensionLoaded', self, self.OnLoaded)
  self.m_ClientFrameUpdateEvent = Events:Subscribe('Client:PostFrameUpdate', self, self.OnPostFrameUpdate)
  self.m_Medics = {}
  self.m_DeathPos = {x=0, y=0, z=0}
  self.m_IsClientDead = false
  self.m_DeadTimer = 0
  self.MAX_DISTANCE = 50
end

function MedicRadarClient:OnLoaded()
  print("onloaded called")
  WebUI:Init()
  WebUI:Hide()
end

function MedicRadarClient:UpdateUI(p_Medics)
  WebUI:ExecuteJS('removeAll()')

  local s_Messages = split(p_Medics, "|")
  
  for i, s_Message in ipairs(s_Messages) do
    if s_Message ~= nil and i < 10 then
      WebUI:ExecuteJS('addText("' .. tostring(s_Message) .. '")')
    end
  end
end
  
function MedicRadarClient:OnClearUI()
  print("Recived call from server: clearui")
  self.m_IsClientDead = false
  self.m_DeadTimer = 0
  WebUI:ExecuteJS('removeAll()')
  WebUI:Hide()

end

function MedicRadarClient:OnShowUI()
  print("Recived call from server: showui")
  local s_LocalPlayer = PlayerManager:GetLocalPlayer()
  if s_LocalPlayer ~= nil then
    local soldier = s_LocalPlayer.soldier

    if soldier ~= nil then
      self.m_DeathPos = {x = soldier.transform.trans.x, y = soldier.transform.trans.y, z = soldier.transform.trans.z}
      -- print("Got position: " .. tostring(soldier.transform.trans.x) .. 
      --   " ".. tostring(soldier.transform.trans.y) ..
      --   " ".. tostring(soldier.transform.trans.z) .. " ")
    end
  end
  self.m_IsClientDead = true
  
end

function MedicRadarClient:OnPostFrameUpdate(p_Delta)
  if not self.m_IsClientDead then 
    return
  end

  self.m_DeadTimer = self.m_DeadTimer + p_Delta

  if self.m_DeadTimer < 1 then --Wait 1 sec before showing ui
    return
  end

  if self.m_DeadTimer > 12 then --You can't be revived anymore
    self:OnClearUI()
    return
  end

  local s_LocalPlayer = PlayerManager:GetLocalPlayer()

  if s_LocalPlayer == nil then
    return
  end
  
  local s_LocalSoldier = s_LocalPlayer.soldier

  if s_LocalSoldier ~= nil then
    self:OnClearUI()
    return
  end

  WebUI:Show()

  local s_Players = PlayerManager:GetPlayers()
  local s_MedicsWithDefib = ""

  for s_Index, s_Player in pairs(s_Players) do 
        
    if s_LocalPlayer.name ~= s_Player.name and
      s_LocalPlayer.teamID == s_Player.teamID then

      --print("found player in same team")
      local s_Soldier = s_Player.soldier
      
      if s_Soldier ~= nil then

        if self:HasDefib(s_Soldier) then
          local distance2 =  
            (self.m_DeathPos.x - s_Soldier.transform.trans.x) * (self.m_DeathPos.x - s_Soldier.transform.trans.x) + 
            (self.m_DeathPos.y - s_Soldier.transform.trans.y) * (self.m_DeathPos.y - s_Soldier.transform.trans.y) +
            (self.m_DeathPos.z - s_Soldier.transform.trans.z) * (self.m_DeathPos.z - s_Soldier.transform.trans.z)
          local distance = math.floor( math.sqrt(distance2) )

          if distance < self.MAX_DISTANCE then
            s_MedicsWithDefib = s_MedicsWithDefib .. s_Player.name .. ": " .. tostring(distance) .. "m.|"
          end
        end
      end
    end
  end

  self:UpdateUI(s_MedicsWithDefib)
end

function MedicRadarClient:HasDefib(p_Soldier)
  local s_Gadget = tostring(p_Soldier:GetWeaponNameByIndex(5)):lower()
  if s_Gadget == "defib" then
    return true
  end
  return false
end

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
    if s ~= 1 or cap ~= "" then
   table.insert(Table,cap)
    end
    last_end = e+1
    s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
   end
   return Table
end

  
g_MedicRadarClient = MedicRadarClient()
