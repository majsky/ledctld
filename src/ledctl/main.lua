local argparse = require("argparse")
local socket = require("socket")
local json = require("json")
local sn = require("supernova")

local parser = argparse("ledctl", sn.green("Ovládanie svetielok"), sn.gradient("For more info, get up and please go see your doctor.", { '#FF0000', '#FF7F00', '#FFFF00', '#00FF00' }))

parser:option("-H --host", "Adresa hostiteľa ledctld", "localhost")
parser:option("-P --port", "Port služby ledctld", 4444)

parser:flag("-v --verbose", "Set verbosity level"):count("0-2"):target("verbosity")

local cmdGet = parser:command("get g", "Zobrazí hodnotu")
local cmdSet = parser:command("set s", "Nadstaví hodnotu")
local cmdStop = parser:command("stop", "Zastaví ledctld")
local cmdQS = parser:command("QS", "Rýchle nadstavenie farby a jasu")

cmdGet:argument("var", "názov premennej"):choices({"color", "c", "brightness", "b"})

cmdSet:argument("var", "názov premennej"):choices({"color", "c", "brightness", "b"})
cmdSet:argument("value", "Nová hodnota"):args("+")

cmdQS:argument("r", "Hodnota farby")
cmdQS:argument("g", "Hodnota farby")
cmdQS:argument("b", "Hodnota farby")
cmdQS:argument("br", "Hodnota jasu")

local args = parser:parse()

local _D = args.verbosity == 2

local function v(s)
    if args.verbosity >= 1 then
        print(sn.yellow(s))
    end
end

local function d(s)
    if _D then
        print(sn.cyan(s))
    end
end

v("Verbose logging enabled")
d("Debug logging enabled")

if _D then
    d("-parameters-------")
    for k, v in pairs(args) do 
        if type(v) == "table" then
            for _k, _v in pairs(v) do 
                print(sn.blue(k), sn.bold.yellow(_k),sn.yellow(_v))
            end
        else
            if k == "verbosity" then
                print(sn.blue(k),sn.yellow(tostring(v)))
            else
                print(sn.blue(k),"",sn.yellow(tostring(v)))
            end
        end
    end
    d("------------------\n\n")
end

local function passert(test, err, desc)
    if not test then 
        return true 
    end

    if desc then
        print(sn.red(desc))
        print("", sn.bold.red(err))
    else
        print(sn.red(err))
    end

    os.exit(1)
end

local function apass(sucess, err, ...)
    local a = table.pack(...)
    passert(a[1] == nil, a[2], err)
    if sucess then
        d(sucess)
    end
    return ...
end

local function ttos(t, sup)
    local s = ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            s = string.format("%s;%s={%s}", s, k, ttos(v))
        else
            if #s > 0 then
                s = string.format("%s;%s=%s",s,k,tostring(v))
            else
                s=string.format("%s=%s",k,tostring(v))
            end
        end
    end
    return s
end

local function send(js, sucMsg)
    d("sending raw data '"..ttos(js).."'")
    local jss = apass("Data encoded", "Error encoding data:", json.encode(js))

    local sock = apass("Connected, sending data", "Can't connect to daemon:", socket.connect(args.host, args.port))
    apass("Sending complete, awaiting response...", "Error while sending data:", sock:send(jss.."\n"))
    local data = apass("Transfer complete.", "Error while recieving data:", sock:receive("*l"))
    d("got data '" .. data .. "'")
    apass("Connection closed.", "Cant close connection", sock:close())

    ddata = apass("Data decoded.", "Cant decode data:", json.decode(data))

    if ddata.code ~= 0 then
        print(sn.red("Daemon returned non-zero exit code: "))
        print("", sn.red("Code ") .. sn.bold.red(tostring(ddata.code) ) .. sn.red(" - ") .. sn.bold.red(ddata.data))
        print(sn.yellow("\nYou should chcek your command"))
        os.exit(ddata.code)
    else
        print(sn.green("Sucess:"))
        if sucMsg then
            print("", sucMsg)
        end
    end

    return ddata
end

if args.stop then
    send({cmd="s"}, sn.yellow("Stopping the daemon"))
elseif args.set then
    if args.var == "color" or args.var == "c" then
        if #args.value == 3 then
            send({cmd="uc", ct=args.value}, sn.color("Color is set!", args.value))
        elseif #args.value == 1 then
            local msg = send({cmd="uc", name=tostring(args.value[1])})
            local rgb = json.decode(msg.data)
            local irgb = {rgb.r, rgb.g, rgb.b}
            print("", sn.color("Color ", irgb) .. sn.bold.color(args.value[1], irgb) .. sn.color(" found and set!", {rgb.r, rgb.g, rgb.b}))
        else
            print(sn.red("Error: Unknown color format"))
            os.exit(1)
        end
    elseif args.var == "b" or args.var == "brightness" then
        send({cmd="b", v=args.value[1]}, sn.yellow("Brightness set to " .. args.value[1] .. "%"))
    end
elseif args.QS then
    local irgb = {args.r,args.g,args.b}
    send({cmd="cx", ct=irgb, b=args.br}, sn.color("Color is set, brightness " .. args.br .."%", irgb))
end
