local function LoadLocales(name)
	local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(name))
	if not raw then
		return nil
	end
	return json.decode(raw)
end

local Locales = LoadLocales(Config.Locale or 'en') or LoadLocales('en') or {}

---Translate a locale key with optional string.format args.
---@param str string
---@param ... any
---@return string
function _(str, ...)
	local entry = Locales?[str]
	if entry then
		return entry:format(...)
	end
	return str:format(...)
end

---Translate and uppercase the first letter.
---@param str string
---@param ... any
---@return string
function _U(str, ...)
	return tostring(_(str, ...):gsub('^%l', string.upper))
end
