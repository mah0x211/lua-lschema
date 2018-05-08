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

-- module
local isNil = require('isa').Nil;
local AUX = require('lschema.aux');
-- constants
local RESERVED_IDENT = {
    constructor = true,
    CLASS_OF = true
};
-- class
local Container = require('halo').class.Container;

Container.inherits {
    'lschema.unchangeable.Unchangeable'
};

local CLASS_OF = 'CLASS_OF';

--[[
    MARK: Metatable
--]]
function Container:__call( name )
    local index = AUX.getIndex( self );

    AUX.isValidIdent( name );
    AUX.abort(
        RESERVED_IDENT[name],
        'identifier %q is reserved word', tostring(name)
    );
    AUX.abort(
        not isNil( rawget( index, name ) ),
        'idenifier %q already defined', tostring(name)
    );
    return function( ... )
        local instance = rawget( index, CLASS_OF ).new( name, ... );

        instance['@'].name = name;
        rawset( index, name, instance );
    end
end

function Container:init( class )
    local index = AUX.getIndex( self );
    rawset( index, CLASS_OF, require( class ) );
    -- remove init method
    rawset( index, 'init', nil );

    return self;
end


return Container.exports;
