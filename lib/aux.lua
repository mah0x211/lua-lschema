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
  
  
  lib/aux.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/25.

--]]

local halo = require('halo');
local typeof = require('util.typeof');
local AUX = halo.class.AUX;


--[[
    MARK: Metatable
--]]
function AUX:__newindex( prop )
    error( ('attempted to assign to readonly property: %q'):format( prop ), 2 );
end

function AUX:__index( prop )
    error( ('attempted to access to undefined value: %q'):format( prop ), 2 );
end

--[[
    MARK: Class Method
--]]
local function abort( exp, fmt, ... )
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

local function getIndex( obj )
    return rawget( getmetatable( obj ), '__index' );
end

local function setCallMethod( obj, fn )
    rawset( getmetatable( obj ), '__call', fn );
end

local function hasCallMethod( obj )
    return type( rawget( getmetatable( obj ), '__call' ) ) == 'function';
end

local PAT_IDENT     = '^[_a-zA-Z][_a-zA-Z0-9]*$';
local function isValidIdent( obj, id )
    local index = getIndex( obj );
    
    abort( 
        not typeof.Nil( rawget( index, id ) ), 
        'identifier %q is reserved word', id 
    );
    abort( 
        not typeof.string( id ), 
        'identifier must be type of string: %q', id 
    );
    abort( 
        not id:find( PAT_IDENT ), 
        'identifier format must be %q : %q', PAT_IDENT, id 
    );
end


--- remove all methods
local function discardMethods( obj )
    local index = getIndex( obj );
    local fields = {};
    local k,v;
    
    for k,v in pairs( index ) do
        if k ~= 'constructor' then
            if typeof.Function( v ) then
                rawset( index, k, nil );
            else
                rawset( fields, k, v );
            end
        end
    end
    
    return fields;
end


local function posing( instance, target )
    local index = getIndex( target );
    local mt = getmetatable( instance );
    
    rawset( mt, 'constructor', target.constructor );
    setmetatable( mt.__index, getmetatable( index ) );
    
    return instance;
end


AUX {
    isValidIdent    = isValidIdent,
    getIndex        = getIndex,
    setCallMethod   = setCallMethod,
    hasCallMethod   = hasCallMethod,
    abort           = abort,
    discardMethods  = discardMethods,
    posing          = posing
};


return AUX.exports;
