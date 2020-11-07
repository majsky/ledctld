package = "ledctld"
version = "0.1-0"

source = {
   url = "http://elektro-odpad.lan/rocks/leds-beta1-0.all.rock"
}

description = {
   homepage = "nedodali",
   license = "lic"
}
dependencies = {
   "supernova >= 0.0",
   "rs232",
   "json4lua >= 0.9.",
   "argparse >= 0.7",
   "luasocket >= 2.0"
}

build = {
   type = "builtin",
   modules = {
      ["ledctld.client"]="src/ledctld/client.lua",
      ["ledctld.control"]="src/ledctld/control.lua",
      ["ledctld.loop"]="src/ledctld/loop.lua",
      ["ledctld.connector.serial"]="src/ledctld/connector/serial.lua",
      ["common.color"]="src/common/color.lua"
   },
   install = {
      bin = {
         ["ledctl"]="src/ledctl/main.lua",
         ["ledctld"]="src/ledctld/main.lua",
      }
   }
}
