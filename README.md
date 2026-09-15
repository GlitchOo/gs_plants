# gs_plants

![example](https://static.glitchd.app/plants/gs_plants_sm.jpg)

Native herb composite plants for RedM. Stream world plants near the player, harvest with the game's pick / eat prompts, then grant inventory rewards or needs effects with a shared cooldown.

[Watch Eating & Looting Plants](https://youtu.be/HAYp_TXl4ok)

---

## Features
- **Syncronized** - Claimed plants are owned by the server and sync'd with every player
- **Native composites** - real RDR3 herb composites with built-in pick and eat scenarios
- **Distance streaming** - spawn / despawn plants around the player with a max active cap
- **Pick or eat** - pick rolls inventory rewards; eat applies hunger / thirst / stress effects
- **Shared harvest lock** - claimed plants stay down for all players until the timeout expires
- **Configurable plants** - rewards, chances, amounts, and eat effects per plant key in `config.lua`
- **Soft needs support** - works with outsider_needs or stock VORP `vorp_metabolism` when started (not a hard dependency)
- **Event providers** - listen via `gs_events` (default) or `vorp_lib`
- **Locales** - player-facing notifies via `locales/<lang>.json`
- **Pre Configured** - Over 5000 unique plant locations are pre configured.

---

## Requirements

- RedM
- [VORP Core](https://github.com/VORPCORE/vorp_core-lua)
- [VORP Inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [gs_events](https://github.com/GlitchOo/gs_events) (default) **or** [vorp_lib](https://github.com/VORPCORE/vorp_lib) when `Config.EventProvider = 'vorp_lib'`

Optional (eat effects):

- outsider_needs **or** [vorp_metabolism](https://github.com/VORPCORE/vorp_metabolism-lua)

Ensure the needs resource starts **before** `gs_plants` if you want eat effects.

---

## Installation

1. Place `gs_plants` in your resources folder.
2. Add inventory items that match your plant `rewards` item names.
3. Add to `server.cfg` (after Core, Inventory, and your event / needs resources):

```cfg
ensure gs_events **or** vorp_lib
ensure gs_plants
```

When using `vorp_lib` instead of `gs_events`, set `Config.EventProvider = 'vorp_lib'` and uncomment `@vorp_lib/import.lua` in `fxmanifest.lua`.

---

## How it works

1. Client builds a stream list from `data/composites.lua` (`vec2` XY; Z resolved when the composite spawns).
2. Nearby composites spawn up to `Config.Composites.maxActive`. Far ones despawn.
3. Native plant loot events (`EVENT_LOOT_PLANT_START`, `EVENT_LOOT`, `EVENT_LOOT_COMPLETE`) detect pick vs eat.
4. Server validates distance and claim state, then either:
   - **pick** – rolls each reward by chance and adds items the player can carry, or
   - **eat** – notifies the client to apply needs effects for that plant key
5. The plant is claimed for `Config.Timeout` minutes for every player.

---

## Configuration

Edit `config.lua`:

| Key | Default | Notes |
|-----|---------|-------|
| `Locale` | `'en'` | Loads `locales/<Locale>.json` (falls back to `en`) |
| `Timeout` | `60` | Shared cooldown after pick / eat (minutes) |
| `EventProvider` | `'gs_events'` | `'gs_events'` or `'vorp_lib'` |
| `Composites.spawnDistance` | `20.0` | Spawn when player is within this range |
| `Composites.despawnDistance` | `40.0` | Despawn beyond this range |
| `Composites.maxActive` | `20` | Cap on simultaneous composites |
| `LootBehaviors.pick` / `.eat` | `0` / `1` | Native looting behavior types |
| `DefaultEat` | table | Fallback eat effects when a plant has no `eat` table |
| `Plants` | table | Per-plant name, rewards, and eat effects |

### Locales

Copy `locales/en.json` to e.g. `locales/fr.json`, translate the strings, then set `Config.Locale = 'fr'`.

| Key | Args | Used for |
|-----|------|----------|
| `harvested_recently` | — | Plant already claimed |
| `ate_plant` | `%s` plant name | Eat success |
| `found_nothing` | — | Pick rolled no items |
| `cant_carry` | `%s` plant name | Inventory full |
| `got_items` | `%s` reward list | Pick success |

Plant display names stay in `Config.Plants[*].name` so owners can rename without touching locale files.

### Plant entry

```lua
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
```

- `rewards` keys are inventory item names. Each item rolls independently (`chance` `1.0` = always).
- `eat` uses fields (`AddHunger`, `AddThirst`, `RemoveStress`, ...). Values are on a 0–100 scale.

### Locations

`data/composites.lua` is an array of:

```lua
{ coords = vec2(x, y), composite = 'COMPOSITE_LOOTABLE_...', rewards = 'plant_key' }
```

`rewards` must match a key in `Config.Plants`.

---

## Included plants

Alaskan Ginseng, American Ginseng, Bay Bolete, Blackberry, Black Currant, Chanterelles, Common Bulrush, Creeping Thyme, Desert Sage, English Mace, Evergreen Huckleberry, Golden Currant, Hummingbird Sage, Indian Tobacco, Milkweed, Oleander Sage, Oregano, Parasol Mushroom, Prairie Poppy, Ram's Head, Red Raspberry, Red Sage, Wild Carrots, Wild Feverfew, Wild Mint, Wintergreen Berry, Yarrow.

---

## License / author

**Author:** \_G\[S\]cripts  
**Version:** 1.0.0  
**License:** [PolyForm Noncommercial License 1.0.0](LICENSE)

Noncommercial use only. See [LICENSE](LICENSE) for full terms.
