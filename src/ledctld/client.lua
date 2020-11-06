local Client = {}
Client._prototype={}
Client.__meta={}

----------- Meta methods
Client.__meta.__index = Client

function Client.__meta.__call(t, name, funct)
    return t.new(name, funct)
end

----------- Client api

function Client:new(pname, pfunct)
    local c = setmetatable({}, Client.__meta)
    c.name = pname
    c.funct = pfunct
    return c
end

function Client:step(data)
    if self.co then
        if coroutine.status(self.co) == "suspended" then
            local ok, err = coroutine.resume(self.co, self._passdata)
            if not ok then
                error(err)
            end
            return ok
        end

        return false
    end

    if not self.funct then
        error(string.format("Client %s has no funct!", self.name))
    end

    if not self.co then
        local function runner()
            local pdata = nil
            while true do
                local rt, data = self.funct(pdata)
                if rt then
                    pdata = data
                    coroutine.yield()
                else
                    return 
                end
            end
        end

        self.co = coroutine.create(runner)

        if data ~= nil then
            self._passdata = data
        end

        return self:step()
    end
end

return setmetatable(Client, {__call = function(t, name, funct) return t:new(name, funct) end})