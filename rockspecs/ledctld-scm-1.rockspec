package = "ledctld"
version = "0.2-2"
source = {
   url = "git+https://github.com/majsky/ledctld.git",
   branch = "dev"
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
      ["common.color"] = "src/common/color.lua",
      ["ledctld.client"] = "src/ledctld/client.lua",
      ["ledctld.connector.serial"] = "src/ledctld/connector/serial.lua",
      ["ledctld.control"] = "src/ledctld/control.lua",
      ["ledctld.loop"] = "src/ledctld/loop.lua"
   },
   install = {
      bin = {
         ledctl = "src/ledctl/main.lua",
         ledctld = "src/ledctld/main.lua"
      }
   }
}
