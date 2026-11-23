# Bubble Gum Simulator

A Roblox bubble simulator built with Luau. The current gameplay foundation includes four generated floating worlds, server-authoritative economy, player XP/levels, gum upgrades, world unlocks, and rebirths. Pets and eggs are intentionally not part of this version.

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

## Project layout

```
place.rbxl
src/
  client/
    BubbleClient.luau
    BubbleHUD.luau
    GumShopUI.luau
    ProgressionUI.luau
  server/
    GameServer.luau
    WorldBuilder.server.luau
```

## Roblox Studio installation

The `.rbxl` file is a binary Studio place. The Luau source files must be installed into the following containers (or synced using your Rojo project):

| File | Roblox location | Class |
|---|---|---|
| `src/server/GameServer.luau` | `ServerScriptService/GameServer` | Script |
| `src/server/WorldBuilder.server.luau` | `ServerScriptService/WorldBuilder` | Script |
| `src/client/BubbleClient.luau` | `StarterPlayer/StarterPlayerScripts/BubbleClient` | LocalScript |
| `src/client/BubbleHUD.luau` | `StarterPlayer/StarterPlayerScripts/BubbleHUD` | LocalScript |
| `src/client/GumShopUI.luau` | `StarterPlayer/StarterPlayerScripts/GumShopUI` | LocalScript |
| `src/client/ProgressionUI.luau` | `StarterPlayer/StarterPlayerScripts/ProgressionUI` | LocalScript |

The server creates `ReplicatedStorage/Remotes` and its RemoteEvents automatically. WorldBuilder creates `Workspace/BubbleWorld`, the four islands, portal prompts, bridges, the starter `ShopZone`, and `SellZone`. It replaces the generated `BubbleWorld` folder each time the server starts.

**Important:** Do not place `WorldBuilder.server.luau` in Workspace or StarterPlayer. It must run as a server Script under ServerScriptService.

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

The generated world is a playable low-poly blockout, not a finished art pass. It still needs custom meshes, terrain detailing, music, sound effects, particles, world-specific shop/sell stations, more quests, balancing, and full in-Studio playtesting. Pets and eggs are deliberately excluded.
