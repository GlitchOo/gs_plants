Config = {}

Config.Locale = 'en' -- locales/<Locale>.json (falls back to en)

Config.Timeout = 60 -- Composite cooldown after pick/eat (minutes)

-- Game event listener: 'gs_events' or 'vorp_lib'
-- vorp_lib also needs: shared_script '@vorp_lib/import.lua' in fxmanifest.lua
Config.EventProvider = 'gs_events'

-- Composite streamer (xy locations in data/composites.lua; Z resolved at spawn)
Config.Composites = {
	spawnDistance = 20.0,
	despawnDistance = 40.0,
	maxActive = 20,
}

-- Night-only plants (start inclusive, finish exclusive). Wraps past midnight when start > finish.
Config.NightHours = { start = 22, finish = 5 }

-- Fallback Eagle Eye tint when a plant has no eagleEyeTint. Set false to disable default tinting.
Config.DefaultEagleEyeTint = { r = 0, g = 255, b = 0 }

-- EVENT_LOOT_PLANT_START (DataSize 2 on current build; discoveries 36 is wrong).
-- data[1] = LootingBehaviorType (0 = pick/loot, 1 = eat)
-- data[2] = looted entity / related id (confirm with sniff).
Config.LootBehaviors = {
	pick = 0,
	eat = 1,
}

-- Fallback eat effects when a plant has no eat table.
-- Keys match outsider_needs SetNeedsData (0-100 scale). Stock vorp_metabolism
-- maps Add/Remove Hunger+Thirst via vorpmetabolism:changeValue (scaled *10 to 0-1000).
Config.DefaultEat = {
	AddHunger = 5,
	AddThirst = 2,
	RemoveStress = 3,
}

-- Rewards / eat effects per plant key (keys match data/composites.lua rewards).
-- rewards: each item rolled independently (chance 1.0 = always).
-- eat: outsider_needs SetNeedsData fields, or mapped to stock vorp_metabolism events.
-- nightOnly: only spawn during Config.NightHours.
-- eagleEyeTint: RGB tint while Eagle Eye is active (false to skip; omit uses DefaultEagleEyeTint).
Config.Plants = {
	agarita = {
		name = 'Agarita',
		eagleEyeTint = { r = 180, g = 255, b = 80 },
		nightOnly = true,
		rewards = {
			['herb_agarita'] = { min = 1, max = 2, chance = 1.0 },
			['seed_agarita'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 5,
			AddThirst = 2,
			RemoveStress = 6,
		},
	},
	alaskan_ginseng = {
		name = 'Alaskan Ginseng',
		eagleEyeTint = { r = 80, g = 220, b = 120 },
		rewards = {
			['herb_alaskan_ginseng'] = { min = 1, max = 2, chance = 1.0 },
			['seed_alaskan_ginseng'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 5,
			AddThirst = 2,
			RemoveStress = 8,
		},
	},
	american_ginseng = {
		name = 'American Ginseng',
		eagleEyeTint = { r = 60, g = 200, b = 100 },
		rewards = {
			['herb_american_ginseng'] = { min = 1, max = 2, chance = 1.0 },
			['seed_american_ginseng'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 5,
			AddThirst = 2,
			RemoveStress = 8,
		},
	},
	bay_bolete = {
		name = 'Bay Bolete',
		eagleEyeTint = { r = 160, g = 100, b = 40 },
		rewards = {
			['mushroom_bay_bolete'] = { min = 1, max = 2, chance = 1.0 },
			['seed_bay_bolete'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 8,
			RemoveStress = 2,
		},
	},
	black_berry = {
		name = 'Blackberry',
		eagleEyeTint = { r = 120, g = 40, b = 160 },
		rewards = {
			['black_berry'] = { min = 1, max = 1, chance = 1.0 },
			['seed_black_berry'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	black_currant = {
		name = 'Black Currant',
		eagleEyeTint = { r = 90, g = 30, b = 140 },
		rewards = {
			['black_currant'] = { min = 1, max = 2, chance = 1.0 },
			['seed_black_currant'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	blood_flower = {
		name = 'Blood Flower',
		eagleEyeTint = { r = 220, g = 40, b = 40 },
		nightOnly = true,
		rewards = {
			['herb_blood_flower'] = { min = 1, max = 2, chance = 1.0 },
			['seed_blood_flower'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 8,
		},
	},
	chanterelles = {
		name = 'Chanterelles',
		eagleEyeTint = { r = 230, g = 170, b = 40 },
		rewards = {
			['mushroom_chanterelles'] = { min = 1, max = 2, chance = 1.0 },
			['seed_chanterelles'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 8,
			RemoveStress = 2,
		},
	},
	common_bulrush = {
		name = 'Bulrush',
		eagleEyeTint = { r = 140, g = 160, b = 70 },
		rewards = {
			['herb_common_bulrush'] = { min = 1, max = 3, chance = 1.0 },
		},
		eat = {
			AddHunger = 4,
			AddThirst = 6,
			RemoveStress = 2,
		},
	},
	creeping_thyme = {
		name = 'Creeping Thyme',
		eagleEyeTint = { r = 100, g = 180, b = 90 },
		rewards = {
			['herb_creeping_thyme'] = { min = 1, max = 3, chance = 1.0 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 4,
		},
	},
	desert_sage = {
		name = 'Desert Sage',
		eagleEyeTint = { r = 200, g = 190, b = 90 },
		rewards = {
			['herb_desert_sage'] = { min = 1, max = 2, chance = 1.0 },
			['seed_desert_sage'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 5,
		},
	},
	english_mace = {
		name = 'English Mace',
		eagleEyeTint = { r = 240, g = 230, b = 180 },
		rewards = {
			['herb_english_mace'] = { min = 1, max = 1, chance = 1.0 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 3,
		},
	},
	evergreen_huckleberry = {
		name = 'Evergreen Huckleberry',
		eagleEyeTint = { r = 70, g = 50, b = 180 },
		rewards = {
			['herb_evergreen_huckleberry'] = { min = 1, max = 2, chance = 1.0 },
			['seed_evergreen_huckleberry'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	golden_currant = {
		name = 'Golden Currant',
		eagleEyeTint = { r = 250, g = 200, b = 40 },
		rewards = {
			['herb_golden_currant'] = { min = 1, max = 2, chance = 1.0 },
			['seed_golden_currant'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	hummingbird_sage = {
		name = 'Hummingbird Sage',
		eagleEyeTint = { r = 180, g = 80, b = 200 },
		rewards = {
			['herb_hummingbird_sage'] = { min = 1, max = 2, chance = 1.0 },
			['seed_hummingbird_sage'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 5,
		},
	},
	indian_tobacco = {
		name = 'Indian Tobacco',
		eagleEyeTint = { r = 170, g = 140, b = 60 },
		rewards = {
			['herb_indian_tobacco'] = { min = 1, max = 1, chance = 1.0 },
			['seed_indian_tobacco'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 2,
			RemoveStress = 2,
		},
	},
	milkweed = {
		name = 'Milk Weed',
		eagleEyeTint = { r = 220, g = 210, b = 160 },
		rewards = {
			['herb_milkweed'] = { min = 1, max = 2, chance = 1.0 },
			['seed_milk_weed'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 2,
		},
	},
	oleander_sage = {
		name = 'Oleander Sage',
		eagleEyeTint = { r = 200, g = 50, b = 120 },
		rewards = {
			['herb_oleander_sage'] = { min = 1, max = 2, chance = 1.0 },
			['seed_oleander_sage'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			RemoveHunger = 10,
			AddStress = 20,
		},
	},
	oregano = {
		name = 'Oregano',
		eagleEyeTint = { r = 90, g = 170, b = 70 },
		rewards = {
			['herb_oregano'] = { min = 1, max = 3, chance = 1.0 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 3,
		},
	},
	parasol_mushroom = {
		name = 'Parasol Mushroom',
		eagleEyeTint = { r = 200, g = 180, b = 140 },
		rewards = {
			['mushroom_parasol_mushroom'] = { min = 1, max = 2, chance = 1.0 },
			['seed_parasol_mushroom'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 8,
			RemoveStress = 2,
		},
	},
	prairie_poppy = {
		name = 'Prairie Poppy',
		eagleEyeTint = { r = 240, g = 160, b = 40 },
		rewards = {
			['herb_prairie_poppy'] = { min = 1, max = 2, chance = 1.0 },
			['seed_prairie_poppy'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 3,
			RemoveStress = 6,
		},
	},
	rams_head = {
		name = 'Rams Head',
		eagleEyeTint = { r = 180, g = 120, b = 80 },
		rewards = {
			['herb_rams_head'] = { min = 1, max = 2, chance = 1.0 },
			['seed_rams_head'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 8,
			RemoveStress = 2,
		},
	},
	red_raspberry = {
		name = 'Red Raspberry',
		eagleEyeTint = { r = 230, g = 50, b = 70 },
		rewards = {
			['red_raspberry'] = { min = 1, max = 2, chance = 1.0 },
			['seed_red_raspberry'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	red_sage = {
		name = 'Red Sage',
		eagleEyeTint = { r = 210, g = 70, b = 50 },
		rewards = {
			['herb_red_sage'] = { min = 1, max = 2, chance = 1.0 },
			['seed_red_sage'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 5,
		},
	},
	wild_carrots = {
		name = 'Wild Carrot',
		eagleEyeTint = { r = 240, g = 140, b = 40 },
		rewards = {
			['carrots'] = { min = 1, max = 2, chance = 1.0 },
			['seed_wild_carrot'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 12,
			RemoveStress = 2,
		},
	},
	wild_feverfew = {
		name = 'Wild Feverfew',
		eagleEyeTint = { r = 250, g = 245, b = 200 },
		rewards = {
			['herb_wild_feverfew'] = { min = 1, max = 2, chance = 1.0 },
			['seed_wild_feverfew'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 4,
		},
	},
	wild_mint = {
		name = 'Wild Mint',
		eagleEyeTint = { r = 80, g = 220, b = 160 },
		rewards = {
			['herb_wild_mint'] = { min = 1, max = 2, chance = 1.0 },
			['seed_wild_mint'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 3,
			AddThirst = 4,
			RemoveStress = 6,
		},
	},
	wintergreen_berry = {
		name = 'Wintergreen Berry',
		eagleEyeTint = { r = 40, g = 160, b = 90 },
		rewards = {
			['herb_wintergreen_berry'] = { min = 1, max = 2, chance = 1.0 },
			['seed_wintergreen_berry'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 10,
			AddThirst = 5,
			RemoveStress = 5,
		},
	},
	yarrow = {
		name = 'Yarrow',
		eagleEyeTint = { r = 250, g = 240, b = 120 },
		rewards = {
			['herb_yarrow'] = { min = 1, max = 2, chance = 1.0 },
			['seed_yarrow'] = { min = 1, max = 1, chance = 0.25 },
		},
		eat = {
			AddHunger = 4,
			RemoveStress = 5,
		},
	},
}
