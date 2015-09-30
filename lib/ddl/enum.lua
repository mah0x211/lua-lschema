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
  
  
  lib/ddl/enum.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/09.

--]]

local is = require('util.is');
local AUX = require('lschema.aux');
local Template = require('lschema.ddl.template');
local Enum = require('halo').class.Enum;

Enum.inherits {
    'lschema.unchangeable.Unchangeable'
};


--[[
    MARK: Metatable
--]]
function Enum:init( _, tbl )
    local index = AUX.getIndex( self );
    local hasFields, fn;
    
    AUX.abort( 
        not is.table( tbl ),
        'argument must be type of table'
    );
    for id, val in pairs( tbl ) do
        -- array
        if is.number( id ) then
            id, val = val, id;
        end
        AUX.isValidIdent( id );
        AUX.abort( 
            rawget( index, id ), 
            'idenifier %q already defined', id
        );
        AUX.abort( 
            not is.finite( val ),
            'identifier %q value must be finite number: %q', id, val
        );
        rawset( index, id, val );
        hasFields = true;
    end
    
    AUX.abort( 
        not hasFields,
        'cannot create empty enum'
    );

    -- make check function
    fn = Template.renderEnum( AUX.discardMethods( self ), index['@'].attr );
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );
    
    return self;
end


return Enum.exports;
