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
  
  
  schema.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/08.
  
--]]
local halo = require('halo');
local typeof = require('util.typeof');
local AUX = require('lschema.aux');
local DDL = require('lschema.ddl');
local Schema = halo.class.Schema;

Schema.inherits {
    'lschema.aux.AUX',
    except = {
        static = {
            'isValidIdent', 'getIndex', 'setCall', 'abort', 'discardMethods',
            'posing'
        }
    }
};


--[[
    MARK: Property
--]]
Schema:property {
    public = {
        name = ''
    }
};


--[[
    MARK: Metatable
--]]
function Schema:init( name )
    local index = AUX.getIndex( self );
    local ddl;
    
    AUX.isValidIdent( self, name );
    self.name = name;
    ddl = DDL.new();
    rawset( index, 'ddl', ddl );
    
    return self;
end

function Schema:dml()

end

function Schema:dcl()

end


return Schema.exports;

