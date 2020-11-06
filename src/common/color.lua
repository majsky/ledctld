local json = require("json")

local Color = {
    __prototype={r=0,g=0,b=0}, 
    __meta={},
    __named={},
    __RGB={[1]="r", [2]="g", [3]="b"}
}

function Color.__meta.__index(s, k)
  if k == 1 or k == 2 or k == 3 then
    return s[Color.__RGB[k]]
  end
  return Color.__prototype[k] or Color[k]
end

function Color:new(r, g, b)
    local c = {}

    if type(r) ~= "nil" and type(g) ~= "nil" and type(b) ~= "nil" then
        c.r = tonumber(r)
        c.g = tonumber(g)
        c.b = tonumber(b)
    else
        if type(r) ~= "nil" then
        error("Bad type " .. type(r))
        end
    end

    setmetatable(c, Color.__meta)
    return c
end

function Color:shade(bright)
    self.r = math.floor(self.r*bright)
    self.g = math.floor(self.g*bright)
    self.b = math.floor(self.b*bright)
end

function Color:shadeCopy(bright)
    return Color(
        math.floor(self.r*bright),
        math.floor(self.g*bright),
        math.floor(self.b*bright)
    )
end

function Color:bytes()
    for _, k in pairs(Color.__RGB) do
        if self[k] == 62 then
            self[k] = 61
        end
    end
    return {self.r, self.g, self.b}
end

function Color:tostring()
    return json.encode({r=self.r, g=self.g, b=self.b})
end

Color.__named.WARM_WHITE = Color:new(255, 172, 68)

return setmetatable(Color, {__call = function(t, r, g, b) return t:new(r, g, b) end, __index=Color.__named})