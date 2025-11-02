-- BHOP Style Selector - Server
-- Provides chat commands !style / !styles / !mode / !modes to open client UI

if SERVER then
    -- Ensure client file is sent
    AddCSLuaFile("autorun/client/cl_cs_style_selector.lua")
    util.AddNetworkString("cs_open_style_selector")
    util.AddNetworkString("cs_set_default_style")
    util.AddNetworkString("cs_get_default_style")

    -- Database configuration (server-side only)
    local DB_CONFIG = {
        HOST = "",
        PORT = 3306,
        NAME = "",
        USER = "",
        PASS = ""
    }

    local DB = nil
    local DB_READY = false

    -- Create the mydefaultstyle table
    local function CreateTable()
        if not DB_READY then return end
        
        local query = DB:query([[
            CREATE TABLE IF NOT EXISTS mydefaultstyle (
                steamid VARCHAR(64) PRIMARY KEY,
                style_id INT NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]])
        
        query.onSuccess = function()
            print("[CS Style Selector] Table 'mydefaultstyle' ready!")
        end
        
        query.onError = function(q, err)
            print("[CS Style Selector] Error creating table: " .. err)
        end
        
        query:start()
    end

    -- Initialize MySQL connection
    local function InitDatabase()
        require("mysqloo")
        
        DB = mysqloo.connect(DB_CONFIG.HOST, DB_CONFIG.USER, DB_CONFIG.PASS, DB_CONFIG.NAME, DB_CONFIG.PORT)
        
        DB.onConnected = function()
            print("[CS Style Selector] Database connected successfully!")
            DB_READY = true
            CreateTable()
        end
        
        DB.onConnectionFailed = function(db, err)
            print("[CS Style Selector] Database connection failed: " .. err)
            DB_READY = false
        end
        
        DB:connect()
    end

    -- Save default style for player
    local function SaveDefaultStyle(steamid, styleID)
        if not DB_READY then return end
        
        -- If style is Normal (ID 1), delete the record instead
        if styleID == 1 then
            local query = DB:prepare("DELETE FROM mydefaultstyle WHERE steamid = ?")
            query:setString(1, steamid)
            
            query.onSuccess = function()
                print("[CS Style Selector] Cleared default style for " .. steamid)
            end
            
            query.onError = function(q, err)
                print("[CS Style Selector] Error clearing default style: " .. err)
            end
            
            query:start()
            return
        end
        
        local query = DB:prepare([[
            INSERT INTO mydefaultstyle (steamid, style_id) 
            VALUES (?, ?) 
            ON DUPLICATE KEY UPDATE style_id = ?
        ]])
        
        query:setString(1, steamid)
        query:setNumber(2, styleID)
        query:setNumber(3, styleID)
        
        query.onSuccess = function()
            print("[CS Style Selector] Saved default style " .. styleID .. " for " .. steamid)
        end
        
        query.onError = function(q, err)
            print("[CS Style Selector] Error saving default style: " .. err)
        end
        
        query:start()
    end

    -- Load default style for player
    local function LoadDefaultStyle(ply)
        if not DB_READY or not IsValid(ply) then return end
        
        local steamid = ply:SteamID64()
        local query = DB:prepare("SELECT style_id FROM mydefaultstyle WHERE steamid = ?")
        query:setString(1, steamid)
        
        query.onSuccess = function(q, data)
            if data and #data > 0 then
                local styleID = tonumber(data[1].style_id)
                if styleID then
                    -- Apply the style to the player
                    timer.Simple(1, function()
                        if IsValid(ply) then
                            -- Make the player run the style command
                            ply:ConCommand("style " .. styleID)
                            
                            timer.Simple(0.1, function()
                                if IsValid(ply) then
                                    ply:ChatPrint("[Style Selector] Your default style has been applied: " .. (Core.StyleName and Core.StyleName(styleID) or styleID))
                                end
                            end)
                        end
                    end)
                end
            end
        end
        
        query.onError = function(q, err)
            print("[CS Style Selector] Error loading default style: " .. err)
        end
        
        query:start()
    end

    -- Network message to set default style
    net.Receive("cs_set_default_style", function(len, ply)
        if not IsValid(ply) then return end
        
        local styleID = net.ReadInt(32)
        local steamid = ply:SteamID64()
        
        SaveDefaultStyle(steamid, styleID)
        
        -- Different message for Normal style
        if styleID == 1 then
            ply:ChatPrint("[Style Selector] Default style cleared! You will now start with Normal on join.")
        else
            ply:ChatPrint("[Style Selector] Style " .. (Core.StyleName and Core.StyleName(styleID) or styleID) .. " set as your default!")
        end
    end)

    -- Load default style on player spawn
    hook.Add("PlayerInitialSpawn", "CS_LoadDefaultStyle", function(ply)
        LoadDefaultStyle(ply)
    end)

    local Triggers = {
        ["!mode"] = true,
        ["!modes"] = true,
        ["!style"] = true,
        ["!styles"] = true,
    }

    hook.Add("PlayerSay", "CS_StyleSelector_PlayerSay", function(ply, text)
        if not IsValid(ply) then return end
        local low = string.Trim(string.lower(text or ""))
        if Triggers[ low ] then
            net.Start("cs_open_style_selector")
            net.Send(ply)
            return "" -- hide typed command
        end
    end)

    -- Optional console command for bind compatibility
    concommand.Add("cs_styles", function(ply)
        if IsValid(ply) then
            net.Start("cs_open_style_selector")
            net.Send(ply)
        end
    end, nil, "Opens the BHOP style selector (same as !mode / !style / !styles / !modes)")

    -- Initialize database on server start
    InitDatabase()
end
