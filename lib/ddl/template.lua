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
-- module
local eval = require('util').eval;
local inspect = require('util').inspect;
local keys = require('util.table').keys;
local tsukuyomi = require('tsukuyomi');
-- constants
local INSPECT_OPT = { 
    depth = 0 
};
local ISA_AKA = {
    ['number']  = 'finite',
    ['enum']    = 'string',
    ['struct']  = 'table'
};

local ISA_TYPE_CONV = {
    ['string']      = 'tostring',
    ['number']      = 'tonumber',
    ['int8']        = 'tonumber',
    ['int16']       = 'tonumber',
    ['int32']       = 'tonumber',
    ['uint8']       = 'tonumber',
    ['uint16']      = 'tonumber',
    ['uint32']      = 'tonumber',
    ['boolean']     = 'toboolean'
};


local SANDBOX = {
    pairs       = pairs,
    table       = table,
    errno       = require('lschema.ddl.errno'),
    AKA         = ISA_AKA,
    TYPE_CONV   = ISA_TYPE_CONV
};

-- template chunks
local TMPL_CHUNKS = {
    ['#PREPARE'] = [[
-- ISA: <?put $.isa ?>
-- PREPARE
local tostring = tostring;
local tonumber = tonumber;
local toboolean = toboolean;
local type = type;
local typeof = typeof;
<?if $.struct ?>local struct = struct;<?end?>
<?if $.pattern ?>local pattern = pattern;<?end?>
<?if $.enum ?>local enum = enum;<?end?>

local VERIFIER = {};
]],

    ['#MINMAX'] = [[
<?if $.min or $.max ?>
        -- MINMAX
        len = <?if $.isa == 'string' ?>#<?end?>val;
<?if $.min == $.max ?>
        if len ~= <?put $.min ?> then
            return nil, {
                errno = <?put errno.EMIN ?>, 
                etype = 'EMIN',
                attr = <?put $.attr ?>
            };
        end
<?else?>
<?if $.min ?>
        if len < <?put $.min ?> then
            return nil, { 
                errno = <?put errno.EMIN ?>, 
                etype = 'EMIN',
                attr = <?put $.attr ?>
            };
        end
<?end?>
<?if $.max ?>
        if len > <?put $.max ?> then
            return nil, { 
                errno = <?put errno.EMAX ?>,
                etype = 'EMAX',
                attr = <?put $.attr ?>
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
                attr = <?put $.attr ?>
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
                attr = <?put $.attr ?>
            };
        end
<?end?>
]],
    
    ['#STRUCT'] = [[
<?if $.struct ?>
        -- struct
        return struct( val, typeconv, trim, split, _rel, _field, _idx );
<?else?>
        return val;
<?end?>
]],

    ['#TYPECONV'] = [[
<?code converter = TYPE_CONV[$.isa] ?>
<?if converter ?>
    -- <?put converter ?>
    if typeconv == true
       <?if $.isa == 'boolean' ?>and type( val ) ~= 'boolean'
       <?elseif $.isa == 'string' ?>and type( val ) ~= 'string'
       <?else?>and type( val ) ~= 'number'<?end?>
    then
        val = <?put converter ?>( val );
    end
<?end?>
]]
};


local ISA = ([[
#PREPARE
function VERIFIER:proc( val, typeconv, trim, split, _rel, _field, _idx )
    if val ~= nil then
<?if $.min or $.max ?>
        local len;
<?end?>

#TYPECONV

        if not typeof.<?put AKA[$.isa] or $.isa ?>( val ) then
            return nil, { 
                errno = <?put errno.ETYPE ?>, 
                etype = 'ETYPE',
                attr = <?put $.attr ?>
            };
        end

#MINMAX
#PATTERN
#ENUM
#STRUCT
    end
    
<?if $.default ~= nil ?>
    -- default
    return <?if $.isa == 'table' or $.isa == 'struct' 
    ?><?put $.default 
    ?><?else
    ?><?$put $.default 
    ?><?end?>;
<?elseif $.notNull ?>
    -- not null
    return nil, { 
        errno = <?put errno.ENULL ?>, 
        etype = 'ENULL',
        attr = <?put $.attr ?>
    };
<?else?>
    return val;
<?end?>
end

return VERIFIER.proc;
]]):gsub( '#%u+', TMPL_CHUNKS );

local ISA_ARRAY = ([[
#PREPARE
local lastIndex = lastIndex;

local function checkVal( val, typeconv, trim, split, _rel, _field, _idx )

#TYPECONV

    if not typeof.<?put AKA[$.isa] or $.isa ?>( val ) then
        return nil, { 
            errno = <?put errno.ETYPE ?>,
            etype = 'ETYPE',
            attr = <?put $.attr ?>
        };
    end

#MINMAX
#PATTERN
#ENUM
#STRUCT

end

function VERIFIER:proc( arr, typeconv, trim, split, _rel, _field, _idx )
    if arr ~= nil then
        local len;
        
        if type( arr ) ~= 'table' then
            return nil, { 
                errno = <?put errno.ETYPE ?>,
                etype = 'ETYPE',
                attr = <?put $.attr ?>
            };
        end
        
        -- get last index
        len = lastIndex( arr );
        
<?if $.len ?>
        -- length 
        if not len or len < <?put $.len.min ?> <?if $.len.max 
        ?>or len > <?put $.len.max ?><?end?> then
            return nil, { 
                errno = <?put errno.ELEN ?>,
                etype = 'ELEN',
                attr = <?put $.attr ?>
            };
        end
<?end?>

        if len and len > 0 then
            local result = trim == true and {} or arr;
            local errtbl = {};
            local val, res, err, gotError;
<?if $.noDup ?>
            local dupIdx = {};
            local dupVal;
<?end?>
            for idx = 1, len do
                val = arr[idx];
                res, err = checkVal( 
                    val, typeconv, trim, split, _rel, _field, idx 
                );
<?if $.noDup ?>
                dupVal = tostring( res );
<?end?>
                if err then
                    errtbl[idx] = err;
                    gotError = true;
<?if $.noDup ?>
                elseif dupIdx[dupVal] then
                    errtbl[idx] = {
                        errno = <?put errno.EDUP ?>,
                        etype = 'EDUP',
                        attr = <?put $.attr ?>
                    };
                    gotError = true;
<?end?>
                elseif trim == true or val ~= res then
                    result[idx] = res;
                end
<?if $.noDup ?>
                dupIdx[dupVal] = true;
<?end?>
            end
            
            return result, gotError and errtbl or nil;
        end
    end
    
<?if $.default ~= nil ?>
    -- default
    return <?put $.default ?>;
<?elseif $.notNull ?>
    -- empty array will be interpreted as a null
    return nil, { 
        errno = <?put errno.ENULL ?>,
        etype = 'ENULL',
        attr = <?put $.attr ?>
    };
<?else?>
    return trim == true and {} or arr;
<?end?>
end

return VERIFIER.proc;
]]):gsub( '#%u+', TMPL_CHUNKS );


local ENUM = [[
-- enum
local ENUM = <?put $.fields ?>;
local VERIFIER = {};
function VERIFIER:proc( val )
    if not ENUM[val] then
        return nil, {
            errno = <?put errno.EENUM ?>,
            etype = 'EENUM',
            attr = <?put $.attr ?>
        };
    end
    
    return val;
end

return VERIFIER.proc;
]];
local ENUM_ENV = {};


local STRUCT = [=[
-- struct: <?put $.name ?>
local FIELDS = <?put $.fields ?>
local NFIELDS = #FIELDS;
local VERIFIER = {};

function VERIFIER:proc( tbl, typeconv, trim, split, _rel, _field, _idx )
    if type( tbl ) == 'table' then
        local result = trim == true and {} or tbl;
        local errtbl = {};
        local field, val, err, gotError;
        
        -- split struct members
        if split then
            local rel = {};
            local data = {};
            local nstack;
            
            for idx = 1, NFIELDS do
                field = FIELDS[idx];
                nstack = #split;
                val, err = self[field]( 
                    tbl[field], typeconv, trim, split, rel, field 
                );
                if err then
                    errtbl[field] = err;
                    result[field] = tbl[field];
                    gotError = true;
                else
                    result[field] = val;
                    if #split == nstack then
                        data[field] = val;
                    end
                end
            end
            
            if gotError then
                return result, errtbl;
            elseif _rel then
                split[#split+1] = {
                    struct = <?put $.name ?>,
                    -- relation
                    rel = {
                        field = _field,
                        idx = _idx
                    },
                    -- field data
                    data = data
                };
                -- set stack-index to parent relation table
                _rel[#_rel+1] = #split;
            else
                split[#split+1] = {
                    struct = <?put $.name ?>,
                    data = data
                };
            end
            
            -- add current stack-index into related struct
            for i = 1, #rel do
                split[rel[i]].rel.stack = #split;
            end
            
            return result;
        end
        
        -- non-split verify
        for idx = 1, NFIELDS do
            field = FIELDS[idx];
            val, err = self[field]( tbl[field], typeconv, trim );
            if err then
                errtbl[field] = err;
                result[field] = tbl[field];
                gotError = true;
            else
                result[field] = val;
            end
        end
        
        if gotError then
            return result, errtbl;
        end
        
        return result;
    end
    
    return nil, { 
        errno = <?put errno.ETYPE ?>,
        etype = 'ETYPE',
        attr = <?put $.attr ?>
    };
end

return VERIFIER.proc;
]=];
local STRUCT_ENV = {
    type = type
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


local function renderEnum( fields, attr )
    return render( 'ENUM', {
        fields = inspect( fields, INSPECT_OPT ),
        attr = inspect( attr, INSPECT_OPT )
    }, ENUM_ENV );
end


local function renderStruct( fields, name, attr )
    fields = keys( fields );
    return render( 'STRUCT', {
        name = ('%q'):format( name ),
        fields = inspect( fields, INSPECT_OPT ),
        attr = inspect( attr, INSPECT_OPT )
    }, STRUCT_ENV );
end


return {
    renderISA = renderISA,
    renderEnum = renderEnum,
    renderStruct = renderStruct
};
