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
  lua-lschema
  Created by Masatoshi Teruya on 14/06/11.

--]]
local LUA_VERS = tonumber( _VERSION:match( 'Lua (.+)$' ) );
local halo = require('halo');
local eval = require('util').eval;
local inspect = require('util').inspect;
local typeof = require('util.typeof');
local Check = halo.class.Check;

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


function Check:init( isa )
    self.tmpl = TMPL_FUNC;
    self.minmax = {};
    self.repls = {
        ['%NOTNULL']    = '',
        ['%DEFAULT']    = 'return true',
        ['%ISA']        = '',
        ['%MINMAX']     = '',
        ['%PATTERN']    = '',
        ['%ENUM']       = ''
    };
    self.env = {
        ENULL       = 1,
        ETYPE       = 2,
        EMIN        = 3,
        EMAX        = 4,
        EPAT        = 5,
        EENUM       = 6,
        type        = type,
        typeof      = typeof
    };
    
    if PRIMITIVE_ISA_TYPE[isa] then
        self.repls['%ISA'] = TMPL_LOC.isa.primitive:format( isa );
    else
        self.repls['%ISA'] = TMPL_LOC.isa.custom:format( isa );
    end
    
    return self;
end

function Check:notNull()
    self.repls['%NOTNULL'] = TMPL_LOC.notNull;
    self.repls['%DEFAULT'] = '';
end

function Check:default( val )
    self.repls['%NOTNULL'] = '';
    self.repls['%DEFAULT'] = TMPL_LOC.default:format( 
        typeof.string( val ) and '"'..val..'"' or val
    );
end

function Check:min( val )
    rawset( self.minmax, #self.minmax + 1, TMPL_LOC.min:format( val ) );
end

function Check:max( val )
    rawset( self.minmax, #self.minmax + 1, TMPL_LOC.max:format( val ) );
end

function Check:pattern( val )
    self.repls['%PATTERN'] = TMPL_LOC.pattern;
    rawset( self.env, 'pattern', val );
end

function Check:enum( val )
    self.repls['%ISA'] = TMPL_LOC.isa.primitive:format('string');
    self.repls['%ENUM'] = TMPL_LOC.enum;
    self.tmpl = TMPL_ENUM:format( 
        inspect( val )
    ) .. self.tmpl;
end


function Check:make()
    local tmpl = self.tmpl;
    local repls = self.repls;
    local minmax = self.minmax;
    local err;
    
    if #minmax > 0 then
        minmax = table.concat( minmax, 'else' );
        repls['%MINMAX'] = TMPL_MINMAX:format( minmax );
    end
    
    tmpl = tmpl:gsub( '%%[A-Z]+', repls );
    -- create function
    tmpl, err = eval( tmpl, self.env );
    assert( not err, err );
    
    return tmpl;
end


return Check.exports;

