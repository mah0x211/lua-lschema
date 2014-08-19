--[[
  
  Copyright (C) 2014 Masatoshi Teruya
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  
  
  lib/ddl/template.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/27.

--]]
local halo = require('halo');
local eval = require('util').eval;
local inspect = require('util').inspect;
local keys = require('util.table').keys;
local tsukuyomi = require('tsukuyomi');

local ISA_AKA = {
    ['number']  = 'finite',
    ['enum']    = 'string',
    ['struct']  = 'table'
};
local SANDBOX = {
    pairs = pairs,
    table = table,
    errno = require('lschema.ddl.errno'),
    AKA = ISA_AKA
};

-- template chunks
local TMPL_CHUNKS = {
    ['#PREPARE'] = [[
-- PREPARE
local type = type;
local typeof = typeof;
local ATTR = <?put $.attr ?>;
<?if $.struct ?>local struct = struct;<?end?>
<?if $.pattern ?>local pattern = pattern;<?end?>
<?if $.enum ?>local enum = enum;<?end?>

local VERIFIER = {};
]],

    ['#MINMAX'] = [[
<?if $.min or $.max ?>
        -- MINMAX
        len = #val;
<?if $.min == $.max ?>
        if len ~= <?put $.min ?> then
            return nil, {
                errno = <?put errno.EMIN ?>, 
                etype = 'EMIN',
                attr = ATTR
            };
        end
<?else?>
<?if $.min ?>
        if len < <?put $.min ?> then
            return nil, { 
                errno = <?put errno.EMIN ?>, 
                etype = 'EMIN',
                attr = ATTR
            };
        end
<?end?>
<?if $.max ?>
        if len > <?put $.max ?> then
            return nil, { 
                errno = <?put errno.EMAX ?>,
                etype = 'EMAX',
                attr = ATTR
            };
        end
<?end?>
<?end?>
<?end?>
]],

    ['#PATTERN'] = [[
<?if $.pattern ?>
        -- PATTERN
        if not pattern:exec( val ) then
            return nil, {
                errno = <?put errno.EPAT ?>, 
                etype = 'EPAT',
                attr = ATTR
            };
        end
<?end?>
]],

    ['#ENUM'] = [[
<?if $.enum ?>
        -- ENUM
        if not enum( val ) then
            return nil, { 
                errno = <?put errno.EENUM ?>,
                etype = 'EENUM',
                attr = ATTR
            };
        end
<?end?>
]],
    
    ['#STRUCT'] = [[
<?if $.struct ?>
        -- struct
        return struct( val );
<?else?>
        return val;
<?end?>
]]
};


local ISA = ([[
-- ISA: <?put $.isa ?>

#PREPARE
function VERIFIER:proc( val )
    if val ~= nil then
<?if $.min or $.max ?>
        local len;
<?end?>
        if not typeof.<?put AKA[$.isa] or $.isa ?>( val ) then
            return nil, { 
                errno = <?put errno.ETYPE ?>, 
                etype = 'ETYPE',
                attr = ATTR
            };
        end

#MINMAX
#PATTERN
#ENUM
#STRUCT
    end
    
<?if $.notNull ?>
    -- not null
    return nil, { 
        errno = <?put errno.ENULL ?>, 
        etype = 'ENULL',
        attr = ATTR
    };
<?elseif $.default ?>
    -- default
    return <?$put $.default ?>;
<?else?>
    return val;
<?end?>
end

return VERIFIER.proc;
]]):gsub( '#%u+', TMPL_CHUNKS );

local ISA_ARRAY = ([[
#PREPARE

local function checkVal( val )
    if not typeof.<?put AKA[$.isa] or $.isa ?>( val ) then
        return nil, { 
            errno = <?put errno.ETYPE ?>,
            etype = 'ETYPE',
            attr = ATTR
        };
    end

#MINMAX
#PATTERN
#ENUM
#STRUCT

end

function VERIFIER:proc( arr )
    if arr ~= nil then
        local errtbl = {};
        local len, idx, val, res, err, gotError;
        
        if type( arr ) ~= 'table' then
            return nil, { 
                errno = <?put errno.ETYPE ?>,
                etype = 'ETYPE',
                attr = ATTR
            };
        end
        
        len = #arr;
<?if $.len ?>
        -- length 
        if len < <?put $.len.min ?> <?if $.len.max 
        ?>or len > <?put $.len.max ?><?end?> then
            return nil, { 
                errno = <?put errno.ELEN ?>,
                etype = 'ELEN',
                attr = ATTR
            };
        end
<?end?>
        for idx = 1, len do
            val = rawget( arr, idx );
            res, err = checkVal( val );
            if err then
                rawset( errtbl, idx, err );
                gotError = true;
            elseif val ~= res then
                rawset( arr, idx, res );
            end
        end
        
        return arr, gotError and errtbl or nil;
    end
    
<?if $.notNull ?>
    -- not null
    return nil, { 
        errno = <?put errno.ENULL ?>,
        etype = 'ENULL',
        attr = ATTR
    };
<?else?>
    return arr;
<?end?>
end

return VERIFIER.proc;
]]):gsub( '#%u+', TMPL_CHUNKS );


local ENUM = [[
local ENUM = <?put $.fields ?>;
local VERIFIER = {};
function VERIFIER:proc( val )
    if not ENUM[val] then
        return nil, <?put errno.EENUM ?>;
    end
    
    return val;
end

return VERIFIER.proc;
]];
local ENUM_ENV = {};

local STRUCT = [[
local FIELDS = <?put $.fields ?>
local NFIELDS = #FIELDS;
local VERIFIER = {};
function VERIFIER:proc( tbl )
    if type( tbl ) == 'table' then
        local errtbl = {};
        local idx, field, val, err, gotError;
        
        for idx = 1, NFIELDS do
            field = rawget( FIELDS, idx );
            val, err = self[field]( tbl[field] );
            if err then
                rawset( errtbl, field, err );
                gotError = true;
            else
                tbl[field] = val;
            end
        end
        
        return tbl, gotError and errtbl or nil;
    end
    
    return nil, errno.ETYPE;
end

return VERIFIER.proc;
]];
local STRUCT_ENV = {
    type = type,
    rawget = rawget,
    rawset = rawset
};


local function put( val )
    return type( val ) == 'string' and ('%q'):format( val ) or val;
end

local Template = tsukuyomi.new( nil, SANDBOX );
-- register custom command $put
Template:setCommand( 'put', put, true );

-- register template
do
    local _, err;
    
    _, err = Template:setPage( 'ISA', ISA );
    assert( not err, err );
    _, err = Template:setPage( 'ISA_ARRAY', ISA_ARRAY );
    assert( not err, err );
    _, err = Template:setPage( 'ENUM', ENUM );
    assert( not err, err );
    _, err = Template:setPage( 'STRUCT', STRUCT );
    assert( not err, err );
end

local function render( label, data, env )
    local fn, ok = Template:render( label, data );
    
    assert( ok, fn );
    fn, ok = eval( fn, env );
    assert( not ok, ok );
    
    return fn();
end

local function renderISA( fields, env )
    return render( fields.asArray and 'ISA_ARRAY' or 'ISA', fields, env );
end

local function renderEnum( fields )
    return render( 'ENUM', {
        fields = inspect( fields )
    }, ENUM_ENV );
end

local function renderStruct( fields )
    fields = keys( fields );
    return render( 'STRUCT', {
        fields = inspect( fields )
    }, STRUCT_ENV );
end

return {
    renderISA = renderISA,
    renderEnum = renderEnum,
    renderStruct = renderStruct
};
