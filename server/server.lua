local Framework = Config.Framework or 'vorp'
local Core = Framework == 'rsg'
	and exports['rsg-core']:GetCoreObject()
	or exports.vorp_core:GetCore()

---Claimed composite indexes until timeout (shared harvest lock).
---@type table<number, number>
local ClaimedUntil = {}

---Active loot sessions keyed by player source.
---@type table<number, { index: number, action: 'eat'|'pick', at: number }>
local Sessions = {}

local SESSION_TTL = 20
local MAX_DIST = 3.0

---@param src number
---@param msg string
local function Notify(src, msg)
	if Framework == 'rsg' then
		TriggerClientEvent('ox_lib:notify', src, { description = msg, type = 'inform', duration = 4000 })
	elseif Framework == 'vorp' then
		Core.NotifyRightTip(src, msg, 4000)
	end
end

---@param src number
---@param item string
---@param amount number
---@return boolean
local function CanCarry(src, item, amount)
	if Framework == 'rsg' then
		return exports['rsg-inventory']:CanAddItem(src, item, amount)
	elseif Framework == 'vorp' then
		return exports.vorp_inventory:canCarryItems(src, amount)
			and exports.vorp_inventory:canCarryItem(src, item, amount)
	end
	return false
end

---@param src number
---@param item string
---@param amount number
---@return boolean
local function AddItem(src, item, amount)
	if Framework == 'rsg' then
		local player = Core.Functions.GetPlayer(src)
		if not player then return false end
		return player.Functions.AddItem(item, amount)
	elseif Framework == 'vorp' then
		exports.vorp_inventory:addItem(src, item, amount)
		return true
	end
	return false
end

---@param src number
local function SyncClaimed(src)
	TriggerClientEvent('gs_plants:client:SyncClaimed', src, ClaimedUntil)
end

local function ClearExpired()
	local now = GlobalState.gs_plants_time
	local kept = {}

	for index, untilTs in pairs(ClaimedUntil) do
		if untilTs > now then
			kept[index] = untilTs
		end
	end
	ClaimedUntil = kept

	for src, session in pairs(Sessions) do
		if (now - session.at) > SESSION_TTL then
			Sessions[src] = nil
		end
	end

	SetTimeout(60000, ClearExpired)
end

---Returns a composite location from shared CompositeLocations by index.
---@param index number
---@return table|nil
local function GetLocation(index)
	if type(index) ~= 'number' or index < 1 then
		return nil
	end
	local location = CompositeLocations?[index]
	if type(location) ~= 'table' or not location.coords or type(location.rewards) ~= 'string' then
		return nil
	end
	return location
end

RegisterNetEvent('gs_plants:server:RequestClaimed', function()
	SyncClaimed(source)
end)

AddEventHandler('vorp:SelectedCharacter', function(src)
	if Framework ~= 'vorp' then return end
	if type(src) == 'number' then
		SyncClaimed(src)
	end
end)

RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
	if Framework ~= 'rsg' then return end
	SyncClaimed(source)
end)

RegisterNetEvent('gs_plants:server:LootStart', function(index, action)
	local _source = source
	if action ~= 'eat' and action ~= 'pick' then
		return
	end

	local location = GetLocation(index)
	if not location or not Config.Plants?[location.rewards] then
		return
	end

	local ped = GetEntityCoords(GetPlayerPed(_source))
	if #(vec2(ped.x, ped.y) - location.coords) > MAX_DIST then
		return
	end

	local untilTs = ClaimedUntil[index]
	if untilTs and GlobalState.gs_plants_time < untilTs then
		Notify(_source, _('harvested_recently'))
		return
	end

	Sessions[_source] = {
		index = index,
		action = action,
		at = GlobalState.gs_plants_time,
	}
end)

RegisterNetEvent('gs_plants:server:LootCancel', function()
	Sessions[source] = nil
end)

RegisterNetEvent('gs_plants:server:CompleteLoot', function(index)
	local _source = source
	local session = Sessions[_source]
	if not session then
		return
	end

	local now = GlobalState.gs_plants_time
	if (now - session.at) > SESSION_TTL or session.index ~= index then
		Sessions[_source] = nil
		return
	end

	local location = GetLocation(index)
	if not location then
		Sessions[_source] = nil
		return
	end

	local plant = Config.Plants?[location.rewards]
	if not plant then
		Sessions[_source] = nil
		return
	end

	local ped = GetEntityCoords(GetPlayerPed(_source))
	if #(vec2(ped.x, ped.y) - location.coords) > MAX_DIST then
		return
	end

	local action = session.action
	Sessions[_source] = nil

	local claimedUntil = ClaimedUntil[index]
	if claimedUntil and now < claimedUntil then
		Notify(_source, _('harvested_recently'))
		return
	end

	local untilTs = now + ((Config.Timeout or 60) * 60)
	ClaimedUntil[index] = untilTs
	TriggerClientEvent('gs_plants:client:MarkClaimed', -1, index, untilTs)

	local label = plant.name or location.rewards

	if action == 'eat' then
		Notify(_source, _('ate_plant', label))
		TriggerClientEvent('gs_plants:client:ApplyEatEffects', _source, location.rewards)
		return
	end

	if not plant.rewards then
		return
	end

	local rolled = {}
	for item, def in pairs(plant.rewards) do
		if type(item) == 'string' and type(def) == 'table' then
			local chance = tonumber(def.chance) or 1.0
			if math.random() <= chance then
				local minAmount = math.max(1, math.floor(tonumber(def.min) or 1))
				local maxAmount = math.max(minAmount, math.floor(tonumber(def.max) or minAmount))
				rolled[#rolled + 1] = {
					item = item,
					amount = math.random(minAmount, maxAmount),
				}
			end
		end
	end

	if #rolled < 1 then
		Notify(_source, _('found_nothing'))
		return
	end

	local granted = {}

	for i = 1, #rolled do
		local entry = rolled[i]
		if not CanCarry(_source, entry.item, entry.amount) then
			Notify(_source, _('cant_carry', label))
			break
		end

		if AddItem(_source, entry.item, entry.amount) then
			granted[#granted + 1] = entry.amount..'x '..entry.item
		end
	end

	if #granted > 0 then
		Notify(_source, _('got_items', table.concat(granted, ', ')))
	end
end)

AddEventHandler('playerDropped', function()
	Sessions[source] = nil
end)

CreateThread(function()
	while true do
		GlobalState.gs_plants_time = os.time()
		Wait(1000)
	end
end)

SetTimeout(60000, ClearExpired)
