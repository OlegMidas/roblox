# Bubble Gum Simulator

A Roblox bubble simulator starter project using Luau.

## Current gameplay

- Click / tap to inflate a bubble.
- Bubble size is capped by the equipped gum.
- Sell bubbles to earn coins.
- Buy and equip five gum upgrades.
- Player data is stored server-side using DataStore.
- Bubble visuals are replicated to clients.
- Shop purchases are checked on the server and require the player to be inside `ShopZone`.

## Project layout

```
place.rbxl
src/
  client/
    BubbleClient.luau
    BubbleHUD.luau
    GumShopUI.luau
  server/
    GameServer.luau
```

## Roblox Studio setup

The `.rbxl` file is a binary Studio place. The Luau files in `src` are source files and must be synced/installed into the matching script containers in Studio (or through your Rojo workflow):

| File | Roblox location | Class |
|---|---|---|
| `src/server/GameServer.luau` | `ServerScriptService/GameServer` | Script |
| `src/client/BubbleClient.luau` | `StarterPlayer/StarterPlayerScripts/BubbleClient` | LocalScript |
| `src/client/BubbleHUD.luau` | `StarterPlayer/StarterPlayerScripts/BubbleHUD` | LocalScript |
| `src/client/GumShopUI.luau` | `StarterPlayer/StarterPlayerScripts/GumShopUI` | LocalScript |

The server creates the `ReplicatedStorage/Remotes` folder and its RemoteEvents automatically.

Create two anchored parts in Workspace:
- `ShopZone`: the area where players can buy/equip gum. The client shows the shop nearby; the server independently validates the player's position.
- `SellZone`: optional touch-to-sell area.

Recommended properties for both zones: `CanCollide = false`, `CanTouch = true`, and `Transparency = 1`. Make sure `SellZone` is a BasePart.

## DataStore

1. Publish the experience.
2. In Studio, open **Game Settings → Security**.
3. Enable **Studio Access to API Services** for testing.
4. Test in a separate published test experience before production.

The server intentionally uses the existing `BubbleGumSim_Save_v1` DataStore name so existing player saves remain compatible. Do not change the store name unless you are intentionally migrating data.

## Important testing checklist

- Test with **Start Server** and at least two clients.
- Test click/tap inflation and max bubble limits for every gum.
- Test buying, equipping, selling, and leaving/rejoining.
- Test that a shop purchase is rejected when the player is outside `ShopZone`.
- Test DataStore failures in Studio; failed loads are marked and are not written back as fresh defaults.
- Test on a phone-sized emulator and a low-end device.

## Scope

This is a gameplay foundation, not a finished art-built world. The place file itself still needs a designed map, spawn area, decorations, sound, particles, pets/eggs, quests, and in-Studio playtesting. Those cannot be safely inferred from the source scripts alone.
