package = "ledctld"
version = "0.2-1"

source = {
   url = "git+ssh://git@github.com:majsky/ledctld.git",
   tag = "v0.2-1"
}

description = {
   homepage = "nedodali",
   license = "lic"
}
dependencies = {
   "supernova",
   "rs232",
   "json4lua >= 0.9",
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
