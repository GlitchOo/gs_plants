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

local Framework = Config.Framework or 'vorp'

---@return boolean
local function IsPlayerReady()
	if LocalPlayer.state.IsInSession then
		return true
	end
	if Framework == 'rsg' and LocalPlayer.state.isLoggedIn then
		return true
	end
	return false
end

---@return string
local function ResolveNeeds()
	local needs = Config.Needs or 'auto'
	if needs ~= 'auto' then
		return needs
	end
	if Framework == 'rsg' then
		return 'rsg_hud'
	end
	if GetResourceState('outsider_needs') == 'started' then
		return 'outsider_needs'
	end
	if GetResourceState('vorp_metabolism') == 'started' then
		return 'vorp_metabolism'
	end
	return 'none'
end

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

---Known world/inventory plant models used when composite entity lookup returns nothing.
---Im not sure if composites spawn variations so i've added all the possible variations that i could find...
local PlantModels = {
	agarita = { joaat('mp005_s_inv_agarita_01x'), joaat('mp005_s_inv_agarita_01bx') },
	alaskan_ginseng = { joaat('alaskanginseng_p'), joaat('s_inv_alaskanginseng01x'), joaat('s_inv_alaskanginseng01bx') },
	american_ginseng = { joaat('ginseng_p'), joaat('s_ginseng01x') },
	bay_bolete = { joaat('s_inv_baybolete'), joaat('s_inv_baybolete01bx') },
	black_berry = { joaat('s_inv_blackberry01x'), joaat('s_inv_blackberry01bx') },
	black_currant = { joaat('blackcurrant_p'), joaat('s_inv_blackcurrant01x'), joaat('s_inv_blackcurrant01bx') },
	blood_flower = { joaat('mp005_bloodflower_p'), joaat('s_inv_bloodflower01x'), joaat('mp005_s_inv_bloodflw01x') },
	chanterelles = { joaat('s_inv_chanterelles'), joaat('s_inv_chanterelles01bx') },
	common_bulrush = { joaat('bulrush_p'), joaat('s_inv_bulrush01x'), joaat('s_inv_bulrush01bx') },
	creeping_thyme = { joaat('thyme_p'), joaat('s_inv_thyme01x'), joaat('s_inv_thyme01bx') },
	desert_sage = { joaat('desertsage_p'), joaat('s_desertsage01x') },
	english_mace = { joaat('engmace_p') },
	evergreen_huckleberry = { joaat('s_inv_huckleberry01x'), joaat('s_inv_huckleberry01bx') },
	golden_currant = { joaat('goldencurrant_p'), joaat('s_goldencurrant01x') },
	hummingbird_sage = { joaat('humbirdsage_p'), joaat('s_hummingbirdsage01x') },
	indian_tobacco = { joaat('indtobacco_p'), joaat('s_indiantobacco01x') },
	milkweed = { joaat('milkweed_p') },
	oleander_sage = { joaat('orleander_p') },
	oregano = { joaat('oregano_p') },
	parasol_mushroom = { joaat('s_inv_parasol'), joaat('s_inv_parasol01bx') },
	prairie_poppy = { joaat('prariepoppy_p') },
	rams_head = { joaat('s_inv_ramshead'), joaat('s_inv_ramshead01bx') },
	red_raspberry = { joaat('s_inv_raspberry01x'), joaat('s_inv_raspberry01bx') },
	red_sage = { joaat('redsage_p') },
	wild_carrots = { joaat('wildcarrot_p'), joaat('s_inv_wildcarrot01x'), joaat('s_inv_wildcarrot01bx') },
	wild_feverfew = { joaat('feverfew_p') },
	wild_mint = { joaat('wildmint_p'), joaat('s_inv_wildmint01x'), joaat('s_inv_wildmint01bx') },
	wintergreen_berry = { joaat('s_inv_wintergreen01x'), joaat('s_inv_wintergreen01bx') },
	yarrow = { joaat('yarrow01_p'), joaat('s_yarrow01x'), joaat('s_inv_yarrow01x') },
}

---Nearest matching plant models around composite coords.
---@param plantKey string
---@param coords vector3
---@param radius number
---@return number[]
local function FindNearbyPlantEntities(plantKey, coords, radius)
	local entities = {}
	local models = PlantModels[plantKey]
	if not models or not coords then
		return entities
	end

	for i = 1, #models do
		local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, models[i], false, false, false)
		if obj and obj ~= 0 and DoesEntityExist(obj) then
			local already = false
			for j = 1, #entities do
				if entities[j] == obj then
					already = true
					break
				end
			end
			if not already then
				entities[#entities + 1] = obj
			end
		end
	end

	return entities
end

---Resolve plant object handles near a composite (composite entity enum is unreliable).
---@param entry table
---@return number[]
local function ResolvePlantEntities(entry)
	return FindNearbyPlantEntities(entry.plantKey, entry.coords, 4.0)
end

---Whether the game clock is inside Config.NightHours.
---@return boolean
local function IsNightHours()
	local hour = GetClockHours()
	local start = Config.NightHours?.start or 22
	local finish = Config.NightHours?.finish or 5
	if start == finish then
		return true
	end
	if start > finish then
		return hour >= start or hour < finish
	end
	return hour >= start and hour < finish
end

---Whether a plant key may spawn right now (config + nightOnly).
---@param plantKey string
---@return boolean
local function CanSpawnPlant(plantKey)
	local plant = Config.Plants?[plantKey]
	if not plant then
		return false
	end
	if plant.nightOnly and not IsNightHours() then
		return false
	end
	return true
end

local function GetEagleEyeTint(plantKey)
	local plant = Config.Plants?[plantKey]
	if not plant then
		return nil
	end
	if plant.eagleEyeTint == false then
		return false
	end
	if type(plant.eagleEyeTint) == 'table' then
		return plant.eagleEyeTint
	end
	local fallback = Config.DefaultEagleEyeTint
	if fallback == false then
		return false
	end
	return fallback
end

-- NOT SURE IF THIS IS NEEDED? BUT ADDED JUST IN CASE.
local function UnregisterEagleEyeEntities(entities)
	if not entities then
		return
	end
	local player = PlayerId()
	for i = 1, #entities do
		local ent = entities[i]
		if ent and ent ~= 0 then
			-- _UNREGISTER_EAGLE_EYE_FOR_ENTITY
			Citizen.InvokeNative(0x9DAE1380CC5C6451, player, ent)
		end
	end
end

local function ApplyEagleEyeTint(plantKey, entities)
	local tint = GetEagleEyeTint(plantKey)
	if not tint or tint == false or not entities then
		return
	end
	local r = math.floor(tonumber(tint.r) or 0)
	local g = math.floor(tonumber(tint.g) or 0)
	local b = math.floor(tonumber(tint.b) or 0)
	local player = PlayerId()
	for i = 1, #entities do
		local ent = entities[i]
		if ent and ent ~= 0 and DoesEntityExist(ent) then
			-- _REGISTER_EAGLE_EYE_FOR_ENTITY
			Citizen.InvokeNative(0x543DFE14BE720027, player, ent, true)
			-- EAGLE_EYE_SET_CUSTOM_ENTITY_TINT
			Citizen.InvokeNative(0x62ED71E133B6C9F1, ent, r, g, b)
			-- _EAGLE_EYE_SET_REGISTERED_ENTITY_GLOW
			Citizen.InvokeNative(0xBC02B3D151D3859F, ent, true)
		end
	end
end

local function UnbindEntities(index, entry)
	if entry?.entities then
		UnregisterEagleEyeEntities(entry.entities)
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
	local entities = ResolvePlantEntities(entry)
	entry.entities = entities
	for i = 1, #entry.entities do
		EntityToIndex[entry.entities[i]] = index
	end

	for i = 1, #entities do
		local ent = entities[i]
		if ent and ent ~= 0 and DoesEntityExist(ent) then
			-- PLACE_ENTITY_ON_GROUND_PROPERLY
			Citizen.InvokeNative(0x9587913B9E772D29, ent, true)
		end
	end

	ApplyEagleEyeTint(entry.plantKey, entities)

	local first = entities[1]
	if first and first ~= 0 and DoesEntityExist(first) then
		entry.coords = GetEntityCoords(first)
	end

	return #entities > 0
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

---Applies plant eat effects via Config.Needs (outsider_needs, vorp_metabolism, rsg_hud, none).
---Eat tables use outsider_needs keys (AddHunger, AddThirst, RemoveStress, ...).
---@param effects table
local function ApplyNeedsEffects(effects)
	local provider = ResolveNeeds()
	if provider == 'none' then
		return
	end

	if provider == 'outsider_needs' then
		if GetResourceState('outsider_needs') ~= 'started' then
			return
		end
		exports.outsider_needs:SetNeedsData(effects)
		return
	end

	if provider == 'rsg_hud' then
		if GetResourceState('rsg-hud') ~= 'started' then
			return
		end
		local hunger = (tonumber(effects.AddHunger) or 0) - (tonumber(effects.RemoveHunger) or 0)
			+ (tonumber(effects.Hunger) or 0)
		local thirst = (tonumber(effects.AddThirst) or 0) - (tonumber(effects.RemoveThirst) or 0)
			+ (tonumber(effects.Thirst) or 0)
		local removeStress = tonumber(effects.RemoveStress) or 0
		local addStress = tonumber(effects.AddStress) or 0

		if hunger ~= 0 then
			local current = tonumber(LocalPlayer.state.hunger) or 0
			TriggerEvent('hud:client:UpdateHunger', math.max(0, math.min(100, current + hunger)))
		end
		if thirst ~= 0 then
			local current = tonumber(LocalPlayer.state.thirst) or 0
			TriggerEvent('hud:client:UpdateThirst', math.max(0, math.min(100, current + thirst)))
		end
		if removeStress > 0 then
			TriggerEvent('hud:client:RelieveStress', removeStress)
		end
		if addStress > 0 then
			TriggerEvent('hud:client:GainStress', addStress)
		end
		return
	end

	if provider == 'vorp_metabolism' then
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

	-- groundSetting 0 snaps the composite to ground; Z is only a search seed
	local z = GetEntityCoords(PlayerPedId()).z

	-- discoveries: create COMPOSITE (herb entity + native pick/eat scenario)
	local compositeId = Citizen.InvokeNative(
		0x5B4BBE80AD5972DC,
		asset,
		location.x,
		location.y,
		z,
		0.0,
		0, -- groundSetting: 0 = spawn on ground
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
		for attempt = 1, 20 do
			Wait(attempt == 1 and 100 or 150)
			if Active[index] ~= entry then
				return
			end
			if BindEntities(index, entry) then
				return
			end
		end
	end)
end

local function StreamComposites()
	local cfg = Config.Composites
	if not IsPlayerReady() then return end
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
	local isNight = IsNightHours()

	for index, entry in pairs(Active) do
		local plant = Config.Plants?[entry.plantKey]
		if plant?.nightOnly and not isNight then
			DeleteActive(index)
		else
			local dx = pedCoords.x - entry.coords.x
			local dy = pedCoords.y - entry.coords.y
			if (dx * dx + dy * dy) > despawnDistSq then
				DeleteActive(index)
			end
		end
	end

	for i = 1, #Locations do
		local location = Locations[i]
		local claimedUntil = ClaimedUntil[location.index]
		if not Active[location.index]
			and not (claimedUntil and now and now < claimedUntil)
			and CanSpawnPlant(location.plantKey) then
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

	if not IsPlayerReady() or IsPedDeadOrDying(PlayerPedId()) then
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

local function RequestClaimed()
	TriggerServerEvent('gs_plants:server:RequestClaimed')
end

RegisterNetEvent('vorp:SelectedCharacter', function()
	if Framework ~= 'vorp' then return end
	RequestClaimed()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
	if Framework ~= 'rsg' then return end
	RequestClaimed()
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= GetCurrentResourceName() then return end

	for index in pairs(Active) do
		DeleteActive(index)
	end
end)

CreateThread(function()
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

	RequestClaimed()

	-- Re-apply Eagle Eye tint/glow when Eagle Eye turns on
	CreateThread(function()
		local wasEagleEye = false
		while true do
			local eagleEye = Citizen.InvokeNative(0x45AB66D02B601FA7, PlayerId()) == true
			if eagleEye and not wasEagleEye then
				for _, entry in pairs(Active) do
					if entry.entities and #entry.entities > 0 then
						ApplyEagleEyeTint(entry.plantKey, entry.entities)
					end
				end
			end
			wasEagleEye = eagleEye
			Wait(eagleEye and 200 or 400)
		end
	end)

	while true do
		StreamComposites()
		Wait(1000)
	end
end)
