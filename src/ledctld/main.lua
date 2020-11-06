
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

local argparse = require("argparse")
local json = require("json")

local Color = require("common.color")
local Serial = require("ledctld.connector.serial")
local Loop = require("ledctld.loop")
local Client = require("ledctld.client")

local dctl = require("ledctld.control")

local bright = 0.2

local out = io.stderr

local parser = argparse("script", "An example.")
parser:flag("--replace-current")
parser:argument("comport", "Serial port")
parser:argument("ctlport", "Control port")

local args = parser:parse()

local config_path = os.getenv("HOME") .. "/.ledctl"
local config = nil

local config_h, config_err = io.open(config_path, "r")
if not config_h then
    print("Cant load config!")
else
    local config_string = config_h:read("*a")
    config_h:close()
    
    print("Config was loaded!")
    config = json.decode(config_string)
end

dctl.init(args.ctlport)
local sp = Serial:new(args.comport, 23, config and config.color or nil)

dctl.registerHooks({
    uc = function(d)
        local clr
        if d.ct then
            clr = Color:new(d.ct[1], d.ct[2], d.ct[3])
        elseif d.name then
            clr = Color[d.name]
            if not clr then
                return "No such color", 3
            end
        end
        sp.uniformColor = clr
        sp:sendColors()
        return clr:tostring(), 0
    end,

    s = function()
        dctl.run = false
        sp.run = false
        return "Stopping", 0
    end,

    b = function(d)
        local val = tonumber(d.v)

        if val < 0 or val > 100 then
            return "Out of range", 4
        end

        sp.brightness = val / 100
        sp:sendColors()

        if not config then
            config = {}
        end

        if not config.color then
            config.color = {}
        end

        config.color.brightness = sp.brightness

        return val, 0
    end,

    cx = function(d)
        local tc = sp.uniformColor
        if d.ct then
            tc = Color:new(d.ct[1], d.ct[2], d.ct[3])
        elseif d.n then
            local clr = Color[d.n]
            if not clr then
                return "No such color", 3
            end
            tc = clr
        end
        local tb = sp.brightness
        if d.b then
            local val = tonumber(d.b)

            if val < 0 or val > 100 then
                return "Brightness out of range", 4
            end
    
            tb = val / 100
        end

        local steps = {r= (sp.uniformColor.r - tc.r)/100, g=(sp.uniformColor.g -tc.g)/100, b=(sp.uniformColor.b-tc.b)/100, br=(sp.brightness - tb)/100}
        for i=1, 100 do
            local nc = {}
            for k,v in pairs(sp.uniformColor) do
                nc[k] = math.floor(v - steps[k])
                if nc[k] < 0 then
                    nc[k] = 0
                end
                print(k, v, steps[k])
            end
            sp.uniformColor = Color:new(nc.r, nc.g, nc.b)
            sp:sendColors()
            sp:flush()
        end
        sp.uniformColor = tc
        sp.brightness = tb
        sp:sendColors()
        sp:flush()

        if not config then
            config = {}
        end

        if not config.color then
            config.color = {}
        end

        config.color.brightness = sp.brightness
        config.color.uniformColor = sp.uniformColor
        
        return {c=sp.uniformColor,b=sp.brightness}, 0
    end
})



local loop = Loop:new("main")
loop:addClient(Client:new("COM", function() return sp:tick() end ))
--loop:addClient(Client:new("CTL", dctl.loop))

loop:run()

if config then
    local han = io.open(config_path, "w")
    han:write(json.encode(config))
    han:close()
end
