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
  
  
  lib/poser.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/12.

--]]

local halo = require('halo');
local typeof = require('util.typeof');
local Poser = halo.class.Poser;

--[[
    MARK: Patterns
--]]
local PAT_IDENT     = '^[_a-zA-Z][_a-zA-Z0-9]*$';


--[[
    MARK: Metatable
--]]
function Poser:__newindex( prop )
    error( ('attempted to assign to readonly property: %q'):format( prop ), 2 );
end

function Poser:__index( prop )
    error( ('attempted to access to undefined value: %q'):format( prop ), 2 );
end

--[[
    MARK: Method
--]]
-- for reserved word
function Poser:fields()
end

function Poser:getPrivate()
    return getmetatable( self ).__index;
end


function Poser:abort( exp, fmt, ... )
    if exp then
        error( string.format( fmt, ... ) );
        --[[
        local i = 0;
        local line;
        
        fmt = string.format( fmt, ... );
        for line in string.gmatch( debug.traceback(), '[^\n]+' ) do
            if i > 0 and not line:find( '/lschema/', 1, true ) then
                fmt = line:gsub( '%s*(.+)([%d]+:%s*).+', '%1%2' .. fmt );
                break;
            end
            i = i + 1;
        end
        
        error( fmt, 0 );
        --]]
    end
end


function Poser:isValidIdent( id )
    local private = self:getPrivate();
    
    self:abort( 
        not typeof.Nil( rawget( private, id ) ), 
        'identifier %q is reserved word', id 
    );
    self:abort( 
        not typeof.string( id ), 
        'identifier must be type of string: %q', id 
    );
    self:abort( 
        not id:find( PAT_IDENT ), 
        'identifier format must be %q : %q', PAT_IDENT, id 
    );
end


--- remove all methods
function Poser:discardMethods()
    local private = self:getPrivate();
    local fields = {};
    local k,v;
    
    for k,v in pairs( private ) do
        if k ~= 'constructor' then
            if typeof.Function( v ) then
                rawset( private, k, nil );
            else
                rawset( fields, k, v );
            end
        end
    end
    
    -- replace fields
    rawset( private, 'fields', fields );
end


function Poser:posing( instance )
    local private = self:getPrivate();
    local mt = getmetatable( instance );
    
    rawset( mt, 'constructor', self.constructor );
    setmetatable( mt.__index, getmetatable( private ) );
    
    return instance;
end



return Poser.exports;
