local rs232 = require "rs232"

local Color = require("common.color")

local Serial = {
    __meta = {}
}

Serial.__prototype = {
    run = true,
    brightness = 0.5,
    uniformColor = Color.WARM_WHITE
}

function Serial.__meta.__index(s, k)
    return Serial.__prototype[k] or Serial[k]
end

function Serial:new(port_name, led_count, initial_values)
    local e, readport = rs232.open(port_name)

    if e ~= rs232.RS232_ERR_NOERROR then
        error(rs232.error_tostring(e))
    end

    assert(readport:set_baud_rate(rs232.RS232_BAUD_38400) == rs232.RS232_ERR_NOERROR)
    assert(readport:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
    assert(readport:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
    assert(readport:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
    assert(readport:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)

    --local writePort = io.open(port_name,"w")

    --assert(writePort ~= nil)

    local o = {
        name = port_name,
        readport = readport,
        count = led_count,
      --  writePort = writePort,
        _wbuff = {}
    }

    if initial_values then
        for k, v in pairs(initial_values) do
            o[k] = v
        end
    end

    return setmetatable(o, Serial.__meta)
end

function Serial:send(data)
  local function _send(c, data)
    if type(data) == "table" then
      for i=1, #data do
        _send(c, data[i])
      end
    else
      table.insert(c._wbuff, type(data) == "number" and string.char(data) or data)
    end
  end

  _send(self, data)
  return self
--self.readport:open("/dev/ttyUSB0")
--[[
    err, len_written = self.readport:write(data, 0)
    if err ~= rs232.RS232_ERR_NOERROR then
      print(err)
    end
    --print(len_written)
    ]]
end

function Serial:flush()
  err, len_written = self.readport:write(table.concat(self._wbuff),10)
  if err ~= rs232.RS232_ERR_NOERROR then
    print(err)
  end
  --self.writePort:setvbuf("no", 0)
  --self.writePort:write(table.concat(self._wbuff))
  --self.writePort:flush()
  self._wbuff = {}
end

function Serial:sendColors()
    local data={60, self.count, 0}
    if self.colors and #self.colors == self.count then
        for _, c in ipairs(self.colors) do
            table.insert(data, c:shadeCopy(self.brightness):bytes())
        end
    else
        local b = self.uniformColor:shadeCopy(self.brightness):bytes()
        for i=1, self.count do
          table.insert(data, b)
        end
    end
    table.insert(data, 62)
    self:send(data)

    self:flush()
end

function Serial:tick()
--print(string.format("tick %d:%d", self.readport:in_queue()))

  --  local tim = os.time()
    self.msgBuff = self.msgBuff or {len = -1}
    local err, recieve, rlen = self.readport:read(150)
 --   print(err, recieve, rlen)

    if err ~= rs232.RS232_ERR_NOERROR and err ~= 9 then
        error(rs232.error_tostring(err))
    end

    for n=1, rlen do
        local b = string.byte(recieve, n)

        if (b == 97 and self.msgBuff.len == -1) or b == 60 then  --char == a or <
            self.msgBuff.len = b == 97 and 1 or 0
            self.msgBuff.data = {}
        elseif self.msgBuff.len >= 0 and (b == 10 or b == 63 or b == 62 ) then --char == ? or >
            local final = ""
            for i, ch in ipairs(self.msgBuff.data ) do
                final = final .. string.char(ch)
            end
            self:handle(final)
            self.msgBuff.len = -1
            self.msgBuff.data = {}
        elseif self.msgBuff.len > -1 then
            self.msgBuff.len = self.msgBuff.len + 1
            table.insert(self.msgBuff.data, b)
        end

    end

    if not self.run then
        self.readport:close()
    end

--    print("Serial", os.difftime(os.time(), tim), "start", tim)
    return self.run
end

function Serial:handle(msg)
    if msg == "live" then
        self:send("<a>"):flush()

    elseif msg == "Arduino is ready" then
        cols = {}
        for i=1, 24 do
            table.insert(cols, i, Color:new(Serial.color))
        end
        self:sendColors(cols)
    end
end

return Serial
