local Active = {}
local Locations = {}
---Claimed composite indexes -> server unix expiry (GlobalState.gs_plants_time).
---@type table<number, number>
local ClaimedUntil = {}
local RequestedAssets = {}
---Maps plant entity handle -> composite location index.
---@type table<number, number>
local EntityToIndex = {}
---Pending native plant interactions keyed by looted entity id.
---@type table<number, { action: 'eat'|'pick', at: number }>
local PendingLoot = {}

local function EnsureCompositeAsset(hash)
	if RequestedAssets[hash] then
		return true
	end

	-- _REQUEST_HERB_COMPOSITE_ASSET / ARE_COMPOSITE_LOOTABLE_ENTITY_DEF_ASSETS_LOADED
	Citizen.InvokeNative(0x73F0D0327BFA0812, hash)
	local tries = 0
	while not Citizen.InvokeNative(0x5E5D96BE25E9DF68, hash) and tries < 500 do
		tries = tries + 1
		Wait(0)
	end

	if Citizen.InvokeNative(0x5E5D96BE25E9DF68, hash) then
		RequestedAssets[hash] = true
		return true
	end

	return false
end

---Plant entities attached to a herb composite.
---@param compositeId number
---@return number[]
local function GetCompositeEntities(compositeId)
	local entities = {}
	if not compositeId or compositeId == 0 or compositeId == -1 then
		return entities
	end

	local maxEntities = 8
	local buffer = DataView.ArrayBuffer((maxEntities + 1) * 8)
	local count = Citizen.InvokeNative(0x96C6ED22FB742C3E, compositeId, buffer:Buffer(), Citizen.ResultAsInteger())
	if type(count) ~= 'number' or count < 1 then
		return entities
	end

	for i = 0, math.min(count, maxEntities) - 1 do
		local ent = buffer:GetInt32(i * 8)
		if ent and ent ~= 0 and DoesEntityExist(ent) then
			entities[#entities + 1] = ent
		end
	end

	return entities
end

local function UnbindEntities(index, entry)
	if entry?.entities then
		for i = 1, #entry.entities do
			local ent = entry.entities[i]
			if EntityToIndex[ent] == index then
				EntityToIndex[ent] = nil
			end
		end
	end
end

local function BindEntities(index, entry)
	UnbindEntities(index, entry)
	entry.entities = GetCompositeEntities(entry.compositeId)
	for i = 1, #entry.entities do
		EntityToIndex[entry.entities[i]] = index
	end

	local entities = entry.entities
	for i = 1, #entities do
		local ent = entities[i]
		if ent and ent ~= 0 and DoesEntityExist(ent) then
			-- PLACE_ENTITY_ON_GROUND_PROPERLY
			Citizen.InvokeNative(0x9587913B9E772D29, ent, true)
		end
	end

	local first = entities[1]
	if first and first ~= 0 and DoesEntityExist(first) then
		entry.coords = GetEntityCoords(first)
	end
end

local function DeleteActive(index)
	local entry = Active[index]
	if not entry then return end

	UnbindEntities(index, entry)

	if entry.compositeId and entry.compositeId ~= 0 and entry.compositeId ~= -1 then
		-- discoveries: delete COMPOSITE scenario
		Citizen.InvokeNative(0x5758B1EE0C3FD4AC, entry.compositeId, false)
	end

	Active[index] = nil
end

---Match a native plant loot to one of our streamed composites.
---@param lootedEntity number
---@return number|nil index
---@return table|nil entry
local function FindActiveForLoot(lootedEntity)
	if lootedEntity and lootedEntity ~= 0 then
		local index = EntityToIndex[lootedEntity]
		if index and Active[index] then
			return index, Active[index]
		end

		for activeIndex, entry in pairs(Active) do
			BindEntities(activeIndex, entry)
			for i = 1, #(entry.entities or {}) do
				if entry.entities[i] == lootedEntity then
					return activeIndex, entry
				end
			end
		end
	end

	local pedCoords = GetEntityCoords(PlayerPedId())
	local bestIndex, bestEntry, bestDist
	for activeIndex, entry in pairs(Active) do
		local dist = #(pedCoords - entry.coords)
		if dist <= 3.0 and (not bestDist or dist < bestDist) then
			bestIndex, bestEntry, bestDist = activeIndex, entry, dist
		end
	end

	return bestIndex, bestEntry
end

---Applies plant eat effects to outsider_needs (preferred) or stock vorp_metabolism.
---Eat tables use outsider_needs keys (AddHunger, AddThirst, RemoveStress, ...).
---@param effects table
local function ApplyNeedsEffects(effects)
	if GetResourceState('outsider_needs') == 'started' then
		exports.outsider_needs:SetNeedsData(effects)
		return
	end

	if GetResourceState('vorp_metabolism') ~= 'started' then
		return
	end

	-- Stock vorp_metabolism: 0-1000 hunger/thirst. Outsider-style values are 0-100.
	local scale = 10
	local hunger = (tonumber(effects.AddHunger) or 0) - (tonumber(effects.RemoveHunger) or 0)
	local thirst = (tonumber(effects.AddThirst) or 0) - (tonumber(effects.RemoveThirst) or 0)
	local metabolism = (tonumber(effects.AddMetabolism) or 0) - (tonumber(effects.RemoveMetabolism) or 0)
	hunger = hunger + (tonumber(effects.Hunger) or 0)
	thirst = thirst + (tonumber(effects.Thirst) or 0)
	metabolism = metabolism + (tonumber(effects.Metabolism) or 0)

	if hunger ~= 0 then
		TriggerEvent('vorpmetabolism:changeValue', 'Hunger', math.floor(hunger * scale))
	end
	if thirst ~= 0 then
		TriggerEvent('vorpmetabolism:changeValue', 'Thirst', math.floor(thirst * scale))
	end
	if metabolism ~= 0 then
		TriggerEvent('vorpmetabolism:changeValue', 'Metabolism', math.floor(metabolism * scale))
	end
end

---Listen via Config.EventProvider ('gs_events' or 'vorp_lib').
---@param eventName string
---@param callback fun(data: any)
local function ListenToGameEvent(eventName, callback)
	local provider = Config.EventProvider or 'gs_events'

	if provider == 'vorp_lib' then
		if type(Import) ~= 'function' then
			error("^1[gs_plants]^7 Config.EventProvider is 'vorp_lib' but @vorp_lib/import.lua is not in fxmanifest shared_scripts")
		end
		if GetResourceState('vorp_lib') ~= 'started' then
			error("^1[gs_plants]^7 Config.EventProvider is 'vorp_lib' but vorp_lib is not started")
		end

		local Game = Import 'events'
		-- group 0 = SCRIPT_EVENT_QUEUE_AI; true = start immediately
		Game.Events:Register(eventName, 0, callback, true)
		return
	end

	if GetResourceState('gs_events') ~= 'started' then
		error("^1[gs_plants]^7 Config.EventProvider is 'gs_events' but gs_events is not started")
	end

	exports.gs_events:ListenTo(eventName, callback)
end

local function CreateActive(location)
	local index = location.index
	if Active[index] then return end

	local untilTs = ClaimedUntil[index]
	local now = GlobalState.gs_plants_time
	if untilTs and now and now < untilTs then return end
	if type(location.composite) ~= 'string' or location.composite == '' then return end
	if not Config.Plants?[location.plantKey] then return end

	local cfg = Config.Composites
	local activeCount = 0
	for _ in pairs(Active) do
		activeCount = activeCount + 1
	end
	if activeCount >= (cfg.maxActive or 40) then
		return
	end

	local asset = joaat(location.composite)
	if not EnsureCompositeAsset(asset) then
		return
	end

	local pedCoords = GetEntityCoords(PlayerPedId())
	local found, groundZ = GetGroundZFor_3dCoord(location.x, location.y, pedCoords.z + 999.0, false)
	local z = (found and groundZ) or pedCoords.z

	-- discoveries: create COMPOSITE (herb entity + native pick/eat scenario)
	local compositeId = Citizen.InvokeNative(
		0x5B4BBE80AD5972DC,
		asset,
		location.x,
		location.y,
		z,
		0.0,
		0,
		Citizen.PointerValueInt(),
		-1,
		Citizen.ReturnResultAnyway()
	)

	if not compositeId or compositeId == 0 or compositeId == -1 then
		return
	end

	local entry = {
		compositeId = compositeId,
		coords = vector3(location.x, location.y, z),
		plantKey = location.plantKey,
		index = index,
		entities = {},
	}
	Active[index] = entry

	CreateThread(function()
		Wait(100)
		if Active[index] == entry then
			BindEntities(index, entry)
		end
	end)
end

local function StreamComposites()
	local cfg = Config.Composites
	if not cfg?.enabled then return end
	if not LocalPlayer.state.IsInSession then return end
	if IsPedDeadOrDying(PlayerPedId()) then return end

	local now = GlobalState.gs_plants_time
	if now then
		local kept = {}
		for index, untilTs in pairs(ClaimedUntil) do
			if untilTs > now then
				kept[index] = untilTs
			end
		end
		ClaimedUntil = kept
	end

	local pedCoords = GetEntityCoords(PlayerPedId())
	local spawnDist = cfg.spawnDistance or 60.0
	local despawnDist = cfg.despawnDistance or 80.0
	local spawnDistSq = spawnDist * spawnDist
	local despawnDistSq = despawnDist * despawnDist

	for index, entry in pairs(Active) do
		local dx = pedCoords.x - entry.coords.x
		local dy = pedCoords.y - entry.coords.y
		if (dx * dx + dy * dy) > despawnDistSq then
			DeleteActive(index)
		end
	end

	for i = 1, #Locations do
		local location = Locations[i]
		local claimedUntil = ClaimedUntil[location.index]
		if not Active[location.index] and not (claimedUntil and now and now < claimedUntil) then
			local dx = pedCoords.x - location.x
			local dy = pedCoords.y - location.y
			if (dx * dx + dy * dy) <= spawnDistSq then
				CreateActive(location)
			end
		end
	end
end

-- Native plant loot: plant-start (eat vs pick), loot extras, then complete
-- EVENT_LOOT_PLANT_START is DataSize 2 (not 36 from discoveries).
ListenToGameEvent('EVENT_LOOT_PLANT_START', function(data)
	local behaviorType = data[1]
	local lootedEntity = data[2]
	local eatType = Config.LootBehaviors?.eat or 2
	local action = behaviorType == eatType and 'eat' or 'pick'

	if lootedEntity and lootedEntity ~= 0 then
		PendingLoot[lootedEntity] = { action = action, at = GetGameTimer() }
	end

	local _, entry = FindActiveForLoot(lootedEntity)
	if entry?.index then
		TriggerServerEvent('gs_plants:server:LootStart', entry.index, action)
	end
end)

ListenToGameEvent('EVENT_LOOT', function(data)
	local numRewards = data[1]
	local itemHash = data[3]
	local looterId = data[27]
	local lootedEntity = data[28]

	if looterId == PlayerPedId() and (numRewards > 0 or itemHash ~= 0) then
		if lootedEntity and lootedEntity ~= 0 then
			PendingLoot[lootedEntity] = { action = 'pick', at = GetGameTimer() }
		end
		local _, entry = FindActiveForLoot(lootedEntity)
		if entry?.index then
			TriggerServerEvent('gs_plants:server:LootStart', entry.index, 'pick')
		end
	end
end)

ListenToGameEvent('EVENT_LOOT_COMPLETE', function(data)
	local looterId = data[1]
	local lootedEntity = data[2]
	local isSuccess = data[3]
	if looterId ~= PlayerPedId() then return end

	if isSuccess ~= 1 then
		PendingLoot[lootedEntity] = nil
		TriggerServerEvent('gs_plants:server:LootCancel')
		return
	end

	if not LocalPlayer.state.IsInSession or IsPedDeadOrDying(PlayerPedId()) then
		TriggerServerEvent('gs_plants:server:LootCancel')
		return
	end

	local index, entry = FindActiveForLoot(lootedEntity)
	if not index or not entry then
		TriggerServerEvent('gs_plants:server:LootCancel')
		return
	end

	PendingLoot[lootedEntity] = nil
	TriggerServerEvent('gs_plants:server:CompleteLoot', entry.index)

	local serverNow = GlobalState.gs_plants_time
	if serverNow then
		ClaimedUntil[index] = serverNow + ((Config.Timeout or 60) * 60)
	end
	DeleteActive(index)
end)

RegisterNetEvent('gs_plants:client:SyncClaimed', function(claimed)
	local now = GlobalState.gs_plants_time
	local kept = {}

	if type(claimed) == 'table' and now then
		for index, untilTs in pairs(claimed) do
			if type(index) == 'number' and type(untilTs) == 'number' and untilTs > now then
				kept[index] = untilTs
				DeleteActive(index)
			end
		end
	end

	ClaimedUntil = kept
end)

RegisterNetEvent('gs_plants:client:MarkClaimed', function(index, untilTs)
	if type(index) ~= 'number' or index < 1 then return end
	if type(untilTs) ~= 'number' then return end

	ClaimedUntil[index] = untilTs
	DeleteActive(index)
end)

RegisterNetEvent('gs_plants:client:ApplyEatEffects', function(plantKey)
	local plant = Config.Plants?[plantKey]
	local effects = plant?.eat or Config.DefaultEat
	if type(effects) ~= 'table' then
		return
	end

	ApplyNeedsEffects(effects)
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
	TriggerServerEvent('gs_plants:server:RequestClaimed')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= GetCurrentResourceName() then return end

	for index in pairs(Active) do
		DeleteActive(index)
	end
end)

CreateThread(function()
	if not Config.Composites?.enabled then return end

	if type(CompositeLocations) ~= 'table' then
		print('^1[gs_plants]^7 missing CompositeLocations (data/composites.lua)')
		return
	end

	local rewardKeys = {}
	for i = 1, #CompositeLocations do
		local entry = CompositeLocations[i]
		if type(entry) == 'table' and entry.coords and type(entry.composite) == 'string' and type(entry.rewards) == 'string' then
			Locations[#Locations + 1] = {
				plantKey = entry.rewards,
				index = i,
				composite = entry.composite,
				x = entry.coords.x + 0.0,
				y = entry.coords.y + 0.0,
			}
			rewardKeys[entry.rewards] = true
		end
	end

	local plantCount = 0
	for _ in pairs(rewardKeys) do
		plantCount = plantCount + 1
	end
	print(('^2[gs_plants]^7 loaded %s composite locations (%s plants)'):format(#Locations, plantCount))

	TriggerServerEvent('gs_plants:server:RequestClaimed')

	while true do
		StreamComposites()
		Wait(1000)
	end
end)
