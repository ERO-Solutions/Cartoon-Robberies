# FiveM Cash Register Robbery Script

![Robbery Demo] (https://www.youtube.com/watch?v=hCUFaY3nf_4)

A realistic cash register robbery system with fingerprint investigation mechanics for FiveM RP servers.

## Features

- **Interactive Robbery System**
  - 40-second robbery animation with progress display
  - Cancelable at any time with X key
  - 7-minute cooldown between robberies
  - Automatic 911 call notification to police

- **Forensic Investigation**
  - Fingerprint analysis with `/fingerprintregister` command
  - Displays time since last robbery and suspect ID
  - Realistic 3-second inspection animation

- **Visual Feedback**
  - Clear 3D text prompts at interaction points
  - Progress percentage display during actions
  - GTA V notification system integration

## Installation

1. Place the folder in your `resources` directory
2. Add this to your `server.cfg`:


## Configuration

Edit these values in the script:

```lua
-- Location of the cash register (vector3)
local robberyCoords = vector3(373.0461, 328.8553, 103.5665)

-- Robbery duration in milliseconds (40 seconds)
local robberyDuration = 40000

-- Cooldown time in milliseconds (7 minutes)
local cooldownTime = 420000

-- Cash reward amount
local rewardAmount = 500
