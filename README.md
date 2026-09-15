# gs_plants

![example](https://static.glitchd.app/plants/gs_plants_sm.jpg)
![example tint](https://i.gyazo.com/a87471118c3490cbc95cd0054d2342f8.png)

Native herb composite plants for RedM. Stream world plants near the player, harvest with the game's pick / eat prompts, then grant inventory rewards or needs effects with a shared cooldown.

[Watch Eating & Looting Plants](https://youtu.be/HAYp_TXl4ok)

---

## Features
- **Syncronized** - Claimed plants are owned by the server and sync'd with every player
- **Native composites** - real RDR3 herb composites with built-in pick and eat scenarios
- **Distance streaming** - spawn / despawn plants around the player with a max active cap
- **Pick or eat** - pick rolls inventory rewards; eat applies hunger / thirst / stress effects
- **Shared harvest lock** - claimed plants stay down for all players until the timeout expires
- **Night herbs** - Agarita and Blood Flower only spawn during configurable night hours
- **Eagle Eye tints** - per-plant RGB glow while Eagle Eye is active
- **Configurable plants** - rewards, chances, amounts, and eat effects per plant key in `config.lua`
- **Soft needs support** - outsider_needs, stock VORP `vorp_metabolism`, or RSG `rsg-hud` when started (not a hard dependency)
- **Framework support** - VORP or RSG via `Config.Framework` (inventory, notify, player load)
- **Event providers** - listen via `gs_events` (default) or `vorp_lib`
- **Locales** - player-facing notifies via `locales/<lang>.json`
- **Pre Configured** - Over 5700 unique plant locations are pre configured.

---

## Requirements

Pick one framework via `Config.Framework`:

### VORP (`Config.Framework = 'vorp'`)

- RedM
- [VORP Core](https://github.com/VORPCORE/vorp_core-lua)
- [VORP Inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [gs_events](https://github.com/GlitchOo/gs_events) (default) **or** [vorp_lib](https://github.com/VORPCORE/vorp_lib) when `Config.EventProvider = 'vorp_lib'`

Optional eat effects (`Config.Needs = 'auto'` or pinned):

- outsider_needs **or** [vorp_metabolism](https://github.com/VORPCORE/vorp_metabolism-lua)

### RSG (`Config.Framework = 'rsg'`)

- RedM
- [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
- [rsg-inventory](https://github.com/Rexshack-RedM/rsg-inventory)
- [ox_lib](https://github.com/overextended/ox_lib) (notifies)
- [gs_events](https://github.com/GlitchOo/gs_events) (default) **or** vorp_lib when configured

Optional eat effects:

- [rsg-hud](https://github.com/Rexshack-RedM/rsg-hud) (`Config.Needs = 'rsg_hud'` or `'auto'`)

On RSG servers set `Config.Framework = 'rsg'` and preferably `Config.Needs = 'rsg_hud'` (defaults ship as VORP).

Ensure the needs resource starts **before** `gs_plants` if you want eat effects.

---

## Installation

1. Place `gs_plants` in your resources folder.
2. Set `Config.Framework` to `'vorp'` or `'rsg'`.
3. Add inventory items that match your plant `rewards` item names.
4. Add to `server.cfg` (after Core, Inventory, and your event / needs resources):

```cfg
ensure gs_events **or** vorp_lib
ensure gs_plants
```

When using `vorp_lib` instead of `gs_events`, set `Config.EventProvider = 'vorp_lib'` and uncomment `@vorp_lib/import.lua` in `fxmanifest.lua`.

---

## How it works

1. Client builds a stream list from `data/composites.lua` (`vec2` XY; Z resolved when the composite spawns).
2. Nearby composites spawn up to `Config.Composites.maxActive`. Far ones despawn. Night-only plants also despawn when day starts.
3. Bound plant entities get per-plant Eagle Eye tint/glow from `eagleEyeTint`.
4. Native plant loot events (`EVENT_LOOT_PLANT_START`, `EVENT_LOOT`, `EVENT_LOOT_COMPLETE`) detect pick vs eat.
5. Server validates distance and claim state, then either:
   - **pick** – rolls each reward by chance and adds items the player can carry, or
   - **eat** – notifies the client to apply needs effects for that plant key
6. The plant is claimed for `Config.Timeout` minutes for every player.

---

## Configuration

Edit `config.lua`:

| Key | Default | Notes |
|-----|---------|-------|
| `Locale` | `'en'` | Loads `locales/<Locale>.json` (falls back to `en`) |
| `Timeout` | `60` | Shared cooldown after pick / eat (minutes) |
| `Framework` | `'vorp'` | `'vorp'` or `'rsg'` (inventory, notify, character load) |
| `Needs` | `'auto'` | `'auto'`, `'outsider_needs'`, `'vorp_metabolism'`, `'rsg_hud'`, or `'none'` |
| `EventProvider` | `'gs_events'` | `'gs_events'` or `'vorp_lib'` |
| `Composites.spawnDistance` | `20.0` | Spawn when player is within this range |
| `Composites.despawnDistance` | `40.0` | Despawn beyond this range |
| `Composites.maxActive` | `20` | Cap on simultaneous composites |
| `NightHours.start` / `.finish` | `22` / `5` | Night window (start inclusive, finish exclusive; wraps midnight) |
| `DefaultEagleEyeTint` | `{ r=0, g=255, b=0 }` | Fallback tint, or `false` to disable |
| `LootBehaviors.pick` / `.eat` | `0` / `1` | Native looting behavior types |
| `DefaultEat` | table | Fallback eat effects when a plant has no `eat` table |
| `Plants` | table | Per-plant name, rewards, eat, nightOnly, eagleEyeTint |

### Needs (`Config.Needs`)

`'auto'` resolution:

1. `Framework == 'rsg'` -> `rsg_hud`
2. else if `outsider_needs` is started -> `outsider_needs`
3. else if `vorp_metabolism` is started -> stock `vorp_metabolism` (`vorpmetabolism:changeValue`)
4. else -> `none` (no eat effects)

Pin a provider explicitly when you do not want detection. Eat values stay on a 0–100 scale; `vorp_metabolism` multiplies hunger/thirst by 10; `rsg_hud` applies deltas to `LocalPlayer.state.hunger` / `.thirst` and uses `RelieveStress` / `GainStress`.

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
agarita = {
    name = 'Agarita',
    nightOnly = true,
    eagleEyeTint = { r = 180, g = 255, b = 80 },
    rewards = {
        ['herb_agarita'] = { min = 1, max = 2, chance = 1.0 },
    },
    eat = {
        AddHunger = 5,
        RemoveStress = 6,
    },
},
```

- `rewards` keys are inventory item names. Each item rolls independently (`chance` `1.0` = always).
- `eat` uses fields (`AddHunger`, `AddThirst`, `RemoveStress`, ...). Values are on a 0–100 scale.
- `nightOnly = true` only spawns during `Config.NightHours`.
- `eagleEyeTint` is RGB for Eagle Eye glow. Omit to use `DefaultEagleEyeTint`. Set `false` to skip Eagle Eye registration for that plant.

### Locations

`data/composites.lua` is an array of:

```lua
{ coords = vec2(x, y), composite = 'COMPOSITE_LOOTABLE_...', rewards = 'plant_key' }
```

`rewards` must match a key in `Config.Plants`.

Night herb dens (Agarita, Blood Flower) are unioned from all Jean Ropke collector flower cycles (map coords converted to game XY).

---

## Included plants

Agarita (night), Alaskan Ginseng, American Ginseng, Bay Bolete, Blackberry, Black Currant, Blood Flower (night), Chanterelles, Common Bulrush, Creeping Thyme, Desert Sage, English Mace, Evergreen Huckleberry, Golden Currant, Hummingbird Sage, Indian Tobacco, Milkweed, Oleander Sage, Oregano, Parasol Mushroom, Prairie Poppy, Ram's Head, Red Raspberry, Red Sage, Wild Carrots, Wild Feverfew, Wild Mint, Wintergreen Berry, Yarrow.

---

## License / author

**Author:** \_G\[S\]cripts  
**Version:** 1.0.1  
**License:** [PolyForm Noncommercial License 1.0.0](LICENSE)

Noncommercial use only. See [LICENSE](LICENSE) for full terms.
