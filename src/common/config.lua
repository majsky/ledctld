local json = require("json")
local Config = {
  __cache={},
  [directory]="/home/majsky4/.config"
}

function Config.load(filepath)
  local h, err = io.open(filepath,"r")
  if not h then
    return nil, err
  end
  
  local c = json.decode(h:read("*a"))
  h:close()
  return c
end

function Config.save(config, filepath)
  local h, err = io.open(filepath, "w")
      
  if not h then
    return false, err
  end
  
  h:write(json.encode(config))
  h:flush()
  h:close()
  
  return true
end

function Config.new(name, default, file)
  local filepath=Config.getpath(name, file)
  
  if not Config.__cache[filepath] then
    local c, err = Config.load(filepath)
    if not c then
      print(string.format("Cant load config from '%s' (%s). Generating new...", name, err))
      c, err = Config.save(default,filepath)
      if not c then
        print(string.format("\tCannot save config to file '%s' (%s).", filepath, err))
        c = default  
      end
    end
    
    Config.__cache[filepath] = c
  end
  
  return Config.__cache[filepath]
end

function Config.getpath(name, file)
  return string.format("%s/%s.json", Config.directory, file or name)
end

return setmetatable(Config, {__call=function(s, ...) return Config.new(...) end})