local Client = require("ledctld.client")

local Loop = {}

local _meta = {}

function _meta.__index(t, k)
    return Loop[k]
end

function Loop:new(loop_name)
    return setmetatable({name = loop_name}, _meta)
end

function Loop:isEmpty()
    for k,v in pairs(self.clients) do
        return false
    end
    return true
end

function Loop:run()
    if not self.clients then return end
    local clis = self.clients
    while not self:isEmpty() do
        local ct = {}

        for k, v in pairs(self.clients) do
            table.insert(ct, v)
        end

        table.sort(ct, function(c1, c2) return c1.name < c2.name end)

        for k, c in pairs(ct) do
            if not c:step() then
                self:removeClient(c)
            end
        end
    end
end

function Loop:addClient(cli)
    if not self.clients then 
        self.clients = {}
    end

    if self.clients[cli.name] ~= nil then
        error(string.format("Client %s is registered!", cli.name))
    end

    self.clients[cli.name] = cli
end

function Loop:removeClient(cli)
    local n = nil
    if type(cli) == "table" then
        n = cli.name
    elseif type(cli) == "string" then
        n = cli
    end

    if n == nil then
        error(string.format("Could'n resolve client with name: '%s'", n))
    end

    self.clients[n] = nil
end

return Loop