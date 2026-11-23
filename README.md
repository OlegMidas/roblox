# Bubble Gum Simulator

A Roblox bubble simulator built with Luau. The current gameplay foundation includes four generated floating worlds, server-authoritative economy, player XP/levels, gum upgrades, world unlocks, and rebirths. Pets and eggs are intentionally not part of this version.

## Play in Roblox Studio

Download [BubbleGumSimulator.rbxl](BubbleGumSimulator.rbxl), open it in Roblox Studio, and press **Play** (F5). The four islands generate when the server starts. Click or tap to blow a bubble, then use **SELL** or walk onto a marked sell platform. Visit the **GUM SHOP** to buy upgrades.

The place includes the server and client scripts. Local play works without DataStore access, with progress lasting for the current session.

## Gameplay loop

1. Click or tap to blow a bubble.
2. Sell the bubble for Coins and XP.
3. Buy stronger gum to increase bubble power and capacity.
4. Level up through blowing and selling.
5. Unlock new worlds and earn larger coin/XP multipliers.
6. Rebirth at the level and coin requirement to gain a permanent earning multiplier.

## Worlds and progression

| World | Unlock cost | Required level | Coin multiplier | XP multiplier |
|---|---:|---:|---:|---:|
| Grassland | Free | 1 | x1.0 | x1.0 |
| Frozen World | 5,000 Coins | 5 | x1.5 | x1.25 |
| Candy World | 50,000 Coins | 12 | x2.5 | x1.6 |
| Galaxy World | 500,000 Coins | 20 | x4.0 | x2.2 |

Worlds are generated procedurally by `WorldBuilder.server.luau`. Use the portal prompts or the Worlds menu to unlock and travel. The server checks the required level, previous-world unlock, and coin balance; client requests cannot grant access for free.

Rebirth requires Level 20 and 250,000 Coins. It resets Coins, bubble size, gum ownership/equipment, Level, and XP. Unlocked worlds and previous Rebirth count are retained. Each Rebirth adds +0.5 to the coin multiplier.

## Build the place from source

Run this command from the repository root with [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1):

```sh
rojo build --output BubbleGumSimulator.rbxl
```

`default.project.json` maps `src/server/*.server.luau` to Scripts under `ServerScriptService` and `src/client/*.client.luau` to LocalScripts under `StarterPlayer/StarterPlayerScripts`. Use `rojo serve` and the Rojo Studio plugin to sync edits during development. `place.rbxl` is the earlier Studio project.

The server creates `ReplicatedStorage/Remotes` and its RemoteEvents automatically, including animated gameplay notifications for sales, level-ups, gum upgrades, world unlocks, and Rebirth. WorldBuilder creates `Workspace/BubbleWorld`, four themed islands with paths, lamps, trees/crystals, portal frames, the starter wooden gum-shop kiosk, `ShopZone`, and a marked bubble-selling platform with `SellZone`. The gum shop UI opens when the player enters the shop area; the server independently validates the player's position before accepting a purchase. The XP/level widget is positioned compactly on the left side of the screen. WorldBuilder replaces the generated `BubbleWorld` folder each time the server starts.

## DataStore setup

1. Publish the experience.
2. In Studio, open **Game Settings → Security**.
3. Enable **Studio Access to API Services** for a separate test experience.
4. Test saving and loading before releasing publicly.

The server keeps the existing `BubbleGumSim_Save_v1` DataStore name to preserve the original Coins, bubble, and gum save data. New XP, Level, Rebirth, and unlocked-world fields are added to the same player record.

## Studio validation checklist

- Run **Start Server** with at least two clients.
- Confirm WorldBuilder creates four islands and portal prompts.
- Confirm the player spawns on Grassland and cannot walk across decorative bridges to skip unlocks.
- Test world unlocks at the required level and coin balance.
- Test XP, Level, gum purchases, selling, and Rebirth.
- Test that a player cannot unlock a world by sending a forged remote request.
- Test leave/rejoin and DataStore failures.
- Test on a phone-sized emulator and a low-end device.

## Current scope / next polish

The generated world now has a more complete low-poly art blockout and a physical starter gum-shop kiosk, but it still needs custom meshes, terrain detailing, music, sound effects, particles, world-specific shop/sell stations, more quests, balancing, and full in-Studio playtesting. Pets and eggs are deliberately excluded.
