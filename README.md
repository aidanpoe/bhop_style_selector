# BHOP Style Selector

A Garry's Mod bunny hop gamemode addon that provides an elegant, feature-rich style selection system for players. This addon allows players to browse, select, and set default bunny hop movement styles through an intuitive UI interface.

## Features

- **Interactive Style Selector UI**: Beautiful Cinzel-themed interface matching the gamemode aesthetic
- **Random Style Selection**: Quick random style picker for variety
- **Default Style System**: Persist player's preferred style across server sessions using MySQL database
- **Multiple Access Methods**: Open selector via chat commands, console commands, or server-side triggers
- **Responsive Layout**: Dynamic button layout that adapts to screen size and number of available styles
- **Current & Last Style Highlighting**: Visual indicators for currently active style and previously selected style
- **Cookie-Based Session Tracking**: Remember last selected style during current session
- **Gold & Dark Theme**: Premium dark theme with gold accents matching bunny hop aesthetics
- **Automatic Style Detection**: Automatically detects and accommodates new styles added to the gamemode without requiring addon updates

## Installation

1. Clone or download this addon to your Garry's Mod addons folder:
   ```
   garrysmod/addons/bhop_style_selector/
   ```

2. Ensure your server has MySQLOO installed for default style persistence:
   ```lua
   require("mysqloo")
   ```

3. Configure the database credentials in `lua/autorun/server/sv_cs_style_selector.lua`:
   ```lua
   local DB_CONFIG = {
       HOST = "your_host",
       PORT = 3306,
       NAME = "your_database",
       USER = "your_user",
       PASS = "your_password"
   }
   ```

4. Restart your server to load the addon.

## Usage

### Opening the Style Selector

Players can open the style selector using any of these methods:

**Chat Commands:**
- `!style`
- `!styles`
- `!mode`
- `!modes`

**Console Commands:**
- `cs_styles`
- `cs_styles_cl` (client-side)

**Server-side Trigger:**
- Via network message `cs_open_style_selector`

### Selecting a Style

- **Left-Click**: Switch to selected style immediately (remembers choice during session)
- **Right-Click**: Set selected style as your default (saved to database for future joins)

### Random Style

- Click the **RANDOM** button to be randomly assigned a style from all available options

## Functions

### Client-Side Functions (`cl_cs_style_selector.lua`)

#### `FetchStyles()`
Retrieves all available styles from `Core.Config.Style` table, sorts by ID, and returns formatted style data.

**Returns:** `table` - Array of style tables with `id` and `name` properties

---

#### `OpenSelector()`
Creates and displays the main style selector frame. Handles UI layout, button creation, and event management.

**Triggers:**
- Network message `cs_open_style_selector`
- Console command `cs_styles` or `cs_styles_cl`
- Chat commands: `!style`, `!styles`, `!mode`, `!modes`

---

#### `AddStyleButton(index, data)`
Creates an individual style button with dynamic coloring, hover effects, and click handlers.

**Parameters:**
- `index` (number): Button index for color cycling
- `data` (table): Style data with `id` and `name` fields

**Features:**
- Dynamic font sizing based on text width
- Color-coded buttons for visual distinction
- Current style highlighting with cyan border
- Last selected style highlighting with gold border

---

#### `LayoutButtons()`
Intelligently positions all style buttons in rows, handling wrapping and centering based on available screen width.

**Auto-adjusts:**
- Button positions to center horizontally
- Frame height based on content
- Row wrapping based on button widths

---

#### Chat & Console Hooks

**Hook:** `OnPlayerChat` event listener
- Detects chat commands: `!style`, `!styles`, `!mode`, `!modes`
- Triggers `OpenSelector()` if frame not already visible

**Console Commands:**
- `cs_styles_cl`: Client-side command to open selector
- `cs_styles`: Server/Client shared command to open selector

---

#### UI Paint Functions

**Frame Paint:**
- Draws background with gradient and texture overlay
- Renders elegant gold borders with accent lines
- Displays title "BHOP STYLE SELECTOR" in Cinzel font

**Close Button Paint:**
- Custom styled close button with hover effects
- Gold borders and background matching theme

**Header Paint:**
- Displays player nickname and current style
- Darkened background with gold border

**Button Paint:**
- Individual button styling with per-button colors
- Texture overlay effects
- Dynamic font selection (CSStyle_Item / CSStyle_ItemSmall / CSStyle_ItemTiny)

---

### Server-Side Functions (`sv_cs_style_selector.lua`)

#### `InitDatabase()`
Initializes MySQL connection using MySQLOO library. Establishes connection to configured database.

**Configuration Required:**
```lua
HOST = "mysql_server_address"
PORT = 3306
NAME = "database_name"
USER = "database_user"
PASS = "database_password"
```

**Callbacks:**
- `onConnected`: Sets `DB_READY = true` and calls `CreateTable()`
- `onConnectionFailed`: Logs connection error and sets `DB_READY = false`

---

#### `CreateTable()`
Creates the `mydefaultstyle` table in the database if it doesn't exist.

**Table Schema:**
```sql
CREATE TABLE IF NOT EXISTS mydefaultstyle (
    steamid VARCHAR(64) PRIMARY KEY,
    style_id INT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
```

---

#### `SaveDefaultStyle(steamid, styleID)`
Saves or updates a player's default style in the database.

**Parameters:**
- `steamid` (string): Player's Steam64 ID
- `styleID` (number): Style ID to save as default

**Behavior:**
- If styleID is 1 (Normal), deletes the record (resets to default)
- Uses `INSERT ... ON DUPLICATE KEY UPDATE` for upsert functionality
- Logs success/error messages

---

#### `LoadDefaultStyle(ply)`
Loads and applies a player's saved default style on join.

**Parameters:**
- `ply` (Player): Player entity to load style for

**Process:**
1. Queries database for player's saved style
2. Applies style via `ply:ConCommand("style " .. styleID)`
3. Sends confirmation message to player chat
4. Uses `timer.Simple()` for proper timing

---

#### Network Message Handlers

**`cs_open_style_selector` Receive:**
- Triggered on client-side when player requests UI
- Calls `OpenSelector()` on client

**`cs_set_default_style` Receive:**
- Parameters: `styleID` (32-bit integer)
- Calls `SaveDefaultStyle()` with player's SteamID64
- Sends confirmation message to player

---

#### Chat Command Handler

**Hook:** `PlayerSay` event listener
- Detects triggers: `!mode`, `!modes`, `!style`, `!styles`
- Sends network message to open selector on client
- Hides command from chat (`return ""`)

---

#### Console Command

**Command:** `cs_styles`
- Availability: Server/admin only
- Opens selector for specified player
- Description: "Opens the BHOP style selector (same as !mode / !style / !styles / !modes)"

---

#### Automatic Hooks

**`PlayerInitialSpawn` Hook:**
- Triggered when player joins server
- Calls `LoadDefaultStyle(ply)` with 1-second delay
- Ensures proper style application timing

---

## Styling & Customization

### Colors
All colors can be customized in `cl_cs_style_selector.lua`:

```lua
local gold1 = Color(214, 177, 64)           -- Primary gold
local gold2 = Color(235, 205, 95)           -- Bright gold
local darkBg = Color(20, 18, 12)            -- Dark background
local darkBg2 = Color(35, 30, 18)           -- Dark title bg
local buttonLight = Color(50, 45, 30)       -- Light button
local buttonDark = Color(40, 35, 22)        -- Dark button
local textColor = Color(185, 185, 185)      -- Regular text
local textLight = Color(230, 230, 230)      -- Bright text
```

### Fonts
Three custom fonts are created for responsive text sizing:

- `CSStyle_Title`: 34px Cinzel (frame title)
- `CSStyle_Item`: 24px Cinzel (default buttons)
- `CSStyle_ItemSmall`: 20px Cinzel (fallback)
- `CSStyle_ItemTiny`: 16px Cinzel (last resort)

### Button Accent Colors
10 unique button colors cycle through for visual variety:

```lua
local buttonColors = {
    Color(70, 120, 150),   -- Blue
    Color(80, 140, 100),   -- Green
    Color(150, 110, 60),   -- Orange
    Color(140, 80, 80),    -- Red
    Color(120, 90, 140),   -- Purple
    Color(130, 130, 70),   -- Yellow-green
    Color(100, 120, 140),  -- Slate blue
    Color(120, 100, 80),   -- Brown
    Color(110, 130, 120),  -- Teal
    Color(130, 100, 110)   -- Mauve
}
```

## Requirements

- **Garry's Mod** (Server & Client)
- **MySQLOO** (for server default style persistence)
- **Core.Config.Style** table (from your bunny hop gamemode)
- **Core.StyleName()** function (recommended, from gamemode)

## Dependencies

- Core gamemode bunny hop utilities
- MySQLOO for database connectivity
- Cinzel font availability on server

## Troubleshooting

**Styles not appearing?**
- Ensure `Core.Config.Style` is properly populated by your gamemode
- Check that style IDs are numeric values
- New styles added to the gamemode are automatically detected and displayed—no addon update needed!
- If styles still don't appear, reload the addon or restart the server

**Default styles not saving?**
- Verify MySQLOO is installed: `require("mysqloo")`
- Check database credentials in server file
- Ensure `mydefaultstyle` table exists in database

**UI not opening?**
- Verify client file exists at `lua/autorun/client/cl_cs_style_selector.lua`
- Check that network strings are registered on server

**Styles not applying?**
- Ensure the gamemode's `style` console command is functioning
- Verify style IDs in database match gamemode configuration

## License

This addon is provided as-is for use with Garry's Mod bunny hop gamemodes.

## Credits

Developed for the BHOP community.
