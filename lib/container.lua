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
  
  
  lib/container.lua
  lua-schema
  Created by Masatoshi Teruya on 14/06/12.

--]]

local halo = require('halo');
local typeof = require('util.typeof');
local Container, Method = halo.class('lschema.poser');
local inspect = require('util').inspect;

local CLASS_OF = 'CLASS_OF';

--[[
    MARK: Metatable
--]]
function Container:__call( name )
    local self = self;
    
    self:isValidIdent( name );
    return function( ... )
        local private = self:getPrivate();
        local instance, swap = rawget( private, CLASS_OF ).new( ... );
        
        rawset( private, name, swap or instance );
    end
end

function Method:init( class )
    rawset( self:getPrivate(), CLASS_OF, require( class ) );
end


return Container.constructor;
