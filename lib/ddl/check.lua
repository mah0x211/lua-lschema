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
  
  
  lib/ddl/check.lua
  lua-schema
  Created by Masatoshi Teruya on 14/06/11.

--]]
local LUA_VERS = tonumber( _VERSION:match( 'Lua (.+)$' ) );
local halo = require('halo');
local inspect = require('util').inspect;
local typeof = require('util.typeof');
local Check, Method, Property = halo.class();

local PRIMITIVE_ISA_TYPE = {
    ['string']  = true,
    ['number']  = true,
    ['boolean'] = true
};

local TMPL_LOC = {
    isa     = {
        primitive   = [[type( val ) ~= %q]],
        custom      = [[not typeof.%s( val )]]
    },
    
    notNull = [[-- NOT NULL
        return ENULL;]],
    
    default = [[-- DEFALUT
        rawset( tbl, field, %s );
        return true;]],
    
    min = [[if len < %d then
        return EMIN;
    ]],
    max = [[if len > %d then
        return EMAX;]],
    
    enum = [[-- enum
    if not ENUM[val] then
        return EENUM;
    end
    ]],
    
    pattern = [[-- PATTERN
    if not pattern:exec( val ) then
        return EPAT;
    end
    ]]
};

local TMPL_MINMAX = [[-- string or number
    -- MIN-MAX
    local len = #val;
    %s
    end
]];

local TMPL_ENUM = [[
local ENUM = %s;
]];

local TMPL_FUNC = [[
local type = type;
local typeof = typeof;

local function check( tbl, field, val )
    if val == nil then
        %NOTNULL
        %DEFAULT
    elseif %ISA then
        return ETYPE;
    end
    
    %MINMAX
    %PATTERN
    %ENUM
    
    return true;
end

return check;
]];

Property({
    tmpl = '',
    minmax = {},
    repls = {
        ['%NOTNULL']    = '',
        ['%DEFAULT']    = 'return true',
        ['%ISA']        = '',
        ['%MINMAX']     = '',
        ['%PATTERN']    = '',
        ['%ENUM']       = ''
    },
    env = {
        ENULL       = 1,
        ETYPE       = 2,
        EMIN        = 3,
        EMAX        = 4,
        EPAT        = 5,
        EENUM       = 6,
        type        = type,
        typeof      = typeof
    }
});

function Method:init( isa )
    self.tmpl = TMPL_FUNC;
    
    if PRIMITIVE_ISA_TYPE[isa] then
        self.repls['%ISA'] = TMPL_LOC.isa.primitive:format( isa );
    else
        self.repls['%ISA'] = TMPL_LOC.isa.custom:format( isa );
    end
end

function Method:notNull()
    self.repls['%NOTNULL'] = TMPL_LOC.notNull;
    self.repls['%DEFAULT'] = '';
end

function Method:default( val )
    self.repls['%NOTNULL'] = '';
    self.repls['%DEFAULT'] = TMPL_LOC.default:format( 
        typeof.string( val ) and '"'..val..'"' or val
    );
end

function Method:min( val )
    rawset( self.minmax, #self.minmax + 1, TMPL_LOC.min:format( val ) );
end

function Method:max( val )
    rawset( self.minmax, #self.minmax + 1, TMPL_LOC.max:format( val ) );
end

function Method:pattern( val )
    self.repls['%PATTERN'] = TMPL_LOC.pattern;
    rawset( self.env, 'pattern', val );
end

function Method:enum( val )
    self.repls['%ISA'] = TMPL_LOC.isa.primitive:format('string');
    self.repls['%ENUM'] = TMPL_LOC.enum;
    self.tmpl = TMPL_ENUM:format( 
        inspect( val )
    ) .. self.tmpl;
end


function Method:make()
    local tmpl = self.tmpl;
    local repls = self.repls;
    local minmax = self.minmax;
    local ok, err;
    
    if #minmax > 0 then
        minmax = table.concat( minmax, 'else' );
        repls['%MINMAX'] = TMPL_MINMAX:format( minmax );
    end
    
    tmpl = tmpl:gsub( '%%[A-Z]+', repls );
    -- create function
    -- for Lua5.2
    if LUA_VERS > 5.1 then
        tmpl, err = load( tmpl, nil, 't', self.env );
        if not tmpl then
            error( err );
        end
        ok, tmpl = pcall( tmpl );
    -- for Lua5.1
    else
        tmpl, err = loadstring( tmpl );
        if not tmpl then
            error( err );
        end
        setfenv( tmpl, self.env );
        ok, tmpl = pcall( tmpl );
    end
    
    if not ok then
        error( tmpl );
    end
    
    return tmpl;
end


return Check.constructor;

