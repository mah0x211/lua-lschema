package = "lschema"
version = "1.3.0-1"
source = {
    url = "git://github.com/mah0x211/lua-lschema.git",
    tag = "v1.3.0"
}
description = {
    summary = "lua data schema module",
    homepage = "https://github.com/mah0x211/lua-lschema", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "halo >= 1.1.0",
    "lrexlib-oniguruma >= 2.7.2",
    "tsukuyomi >= 1.0.0",
    "util >= 1.3.2"
}
build = {
    type = "builtin",
    modules = {
        lschema = "lschema.lua",
        ['lschema.unchangeable'] = "lib/unchangeable.lua",
        ['lschema.aux'] = "lib/aux.lua",
        ['lschema.container'] = "lib/container.lua",
        ['lschema.ddl.errno'] = "lib/ddl/errno.lua",
        ['lschema.ddl.template'] = "lib/ddl/template.lua",
        ['lschema.ddl.enum'] = "lib/ddl/enum.lua",
        ['lschema.ddl.pattern'] = "lib/ddl/pattern.lua",
        ['lschema.ddl.isa'] = "lib/ddl/isa.lua",
        ['lschema.ddl.struct'] = "lib/ddl/struct.lua"
    }
}

