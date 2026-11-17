# Publishing and screenshots — the steps only the account owner can do

Everything in this repo except the live experience and the four screenshots is
finished: `game.rbxl` builds from this Linux machine with Rojo, all Luau
compiles, and the local dossier validation matches 100% of the place's script
bytes to `src/`. What remains needs a Roblox account and Roblox Studio
(Windows/Mac), which is why it is yours:

## 0. Account prerequisites (Roblox's own rules for this bounty)

- The Roblox account must be at least **2 days old**, in good standing, and
  must have passed Roblox's **age check** (facial age estimation or a
  government ID in account settings). A brand-new account cannot publish for
  this bounty — start the age check early, approval can take time.

## 1. Publish the experience

1. Install **Roblox Studio** on your Windows PC and sign in with your account.
2. Open `game.rbxl` from this repo (Studio → Open from file).
3. **File → Publish to Roblox As…** → create a NEW experience. Name it
   e.g. "Goofy Grove — Brainrot Harvest".
4. In the **Creator Dashboard** for the experience:
   - **Description:** write a short blurb and include this play code exactly:
     `makefun-schooner-buckle-clarinet`
   - Set the **genre**, and complete the **content questionnaire** Roblox asks
     for (this is what gives the experience its maturity rating).
   - **Access / Audience:** set the experience to **Public**. (Private is
     refused by the bounty — only the account owner can flip this switch.)
5. Note the two numbers from the experience/place page: the **place id** and
   the **universe id**. Send them back so `PLAY.json` can be filled in (they
   are public identifiers, not credentials).

## 2. Icon and thumbnail

- Upload an **icon** (512×512) and at least one **thumbnail** in the Creator
  Dashboard, and wait until Roblox's review approves them — default images do
  not count for the bounty.
- The thumbnail must be **the same image file as `screenshots/1-cover.png`**
  below: capture the cover first, then upload that exact file as thumbnail #1.

## 3. Capture the four screenshots (in Studio, game running)

Set the Studio viewport to **1280×720** (16:9). Press **Play**, then stage
each shot from the **Server** command bar (View → Command Bar, switch it to
Server) with:

```lua
require(game.ServerScriptService.Server.ScreenshotStage).showcase()
```

| File | Stage call | What to frame |
| --- | --- | --- |
| `screenshots/1-cover.png` | `showcase()` | Spawn view: grove, cast statues, your base behind you loaded with brainrots |
| `screenshots/2-hunt.png` | `hunt()` | The Gobbler mid-hunt chasing you while you carry the Golden Bagel |
| `screenshots/3-base.png` | `showcase()` | Stand on your base pads: full collection on display, name plates up |
| `screenshots/4-shop.png` | `rich()` | Open the SHOP panel in front of the shop stall and egg nests |

Save each capture into this repo's `screenshots/` folder with exactly those
names, each **≤ 256 KiB** (the kit re-encodes to JPEG; if a file is still too
big, save it as a quality-85 JPEG but keep the `.png` name). The first file by
name is the cover, and it must be the same image as the Roblox thumbnail.

## 4. Hand back

Send back: the place id, the universe id, and the four screenshot files (or
drop the screenshots into `screenshots/` here). Then, from this repo:

```sh
# fill PLAY.json with the two ids first
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts   # sanity: builds the dossier locally
```

Submission itself runs through the kit during a recorded build session (see
README.md, "How this entry is submitted").
