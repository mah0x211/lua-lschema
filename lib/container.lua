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
  lua-lschema
  Created by Masatoshi Teruya on 14/06/12.

--]]

local halo = require('halo');
local typeof = require('util.typeof');
local Container = halo.class.Container;

Container.inherits {
    'lschema.poser.Poser'
};

local CLASS_OF = 'CLASS_OF';

--[[
    MARK: Metatable
--]]
function Container:__call( name )
    local self = self;
    
    self:isValidIdent( name );
    return function( ... )
        local index = self:getIndex();
        local instance = rawget( index, CLASS_OF ).new( ... );
        
        rawset( index, name, instance );
    end
end

function Container:init( class )
    rawset( self:getIndex(), CLASS_OF, require( class ) );
    
    return self;
end


return Container.exports;
