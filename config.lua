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
Config.Plants = {
	alaskan_ginseng = {
		name = 'Alaskan Ginseng',
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
	chanterelles = {
		name = 'Chanterelles',
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
