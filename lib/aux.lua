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
local is = require('util.is');
local lastIndex = require('util.table').lastIndex;
local split = require('util.string').split;
local AUX = require('halo').class.AUX;

AUX.inherits {
    'lschema.unchangeable.Unchangeable'
};

--[[
    MARK: Class Method
--]]
local function getUserStackIndex()
    local list = split( debug.traceback(), '\n' );
    local line;
    
    for idx = 2, #list do
        line = list[idx];
        if not line:find( '(tail call)', 1, true ) and
           not line:find( '/lschema.lua', 1, true ) and
           not line:find( '/lschema/', 1, true ) then
            return idx - 2;
        end
    end
    
    return nil;
end


local function abort( exp, fmt, ... )
    if exp then
        local msg = fmt;
        local args = {...};
        local len = lastIndex( args );
        
        if len then
            for i = 1, len do
                args[i] = tostring( args[i] );
            end
            msg = msg:format( unpack( args ) );
        end
        
        error( msg, getUserStackIndex() );
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
local function isValidIdent( id )
    abort( 
        not is.string( id ),
        'identifier must be type of string: %q', tostring(id) 
    );
    abort( 
        not id:find( PAT_IDENT ), 
        'identifier format must be %q : %q', PAT_IDENT, tostring(id)
    );
end


local function getAttrs( fields )
    local attr = {};

    -- create attribute table
    for k,v in pairs( fields ) do
        if k == 'pattern' then
            attr[k] = v['@'].attr;
        elseif is.table( v ) then
            attr[k] = v['@'] and v['@'].attr or v;
        elseif k == 'default' then
            attr[k] = v;
        elseif is.boolean( v ) then
            if v then
                attr[k] = v;
            end
        else
            attr[k] = v;
        end
    end
    
    return attr;
end

--- remove all methods
local function discardMethods( obj )
    local index = getIndex( obj );
    local fields = {};
    local attr = {};
    
    for k,v in pairs( index ) do
        if k ~= 'constructor' then
            if is.Function( v ) then
                rawset( index, k, nil );
            else
                rawset( fields, k, v );
            end
        end
    end
    
    attr.attr = getAttrs( fields );
    rawset( index, '@', attr );
    
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
