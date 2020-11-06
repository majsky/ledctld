local socket = require("socket")
local json = require("json")

local _CS = {
    run = true
}

function _CS.init(listenport)
    local server = assert(socket.bind("*", listenport))
    local ip, port = server:getsockname()

    server:settimeout(1)
    print(string.format("Listening on: %s:%s", ip, port))

    _CS.server = server
end

function _CS.addHook(cmd, hook)
    if not _CS.hooks then
        _CS.hooks = {}
    end
    _CS.hooks[cmd] = hook
end

function _CS.registerHooks(hooks)
    for k, v in pairs(hooks) do 
        _CS.addHook(k, v)
    end
end

function _CS.loop()
    --local tim = os.time()
    local c = _CS.server:accept()
    
    if c then
        c:settimeout(5)
        local line, err = c:receive("*l")
        --print(line, err)
        if not err then
            local cmdj = json.decode(line)

            local function respond(code, data)
                c:send(json.encode({code=code,data=data}).."\n")
            end

            if cmdj.cmd then
                if _CS.hooks[cmdj.cmd] then
                    local data = {_CS.hooks[cmdj.cmd](cmdj)}
                    respond(data[2] or 1, data[1])
                else
                    respond(2, string.format("Unknown command: '%s'", cmdj.cmd))
                end
            else
                respond(1, "No command")
            end

        end
        c:close()
    end

    if not _CS.run then
        _CS.server:close()
    end

    --print("Control", os.difftime(os.time(), tim))
    return _CS.run
end

return _CS