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
local AUX = require('lschema.aux');
local Container = require('lschema.container');
local ISA = require('lschema.ddl.isa');
local Schema = require('halo').class.Schema;

Schema.inherits {
    'lschema.unchangeable.Unchangeable'
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
local function createISA( ... )
    return ISA.new( ... )
end

function Schema:init( name )
    local index = AUX.getIndex( self );
    
    AUX.isValidIdent( name );
    self.name = name;
    rawset( index, 'isa', createISA );
    rawset( index, 'enum', Container.new('lschema.ddl.enum') );
    rawset( index, 'struct', Container.new('lschema.ddl.struct') );
    rawset( index, 'pattern', Container.new('lschema.ddl.pattern') );
    -- remove init method
    rawset( index, 'init', nil );
    
    return self;
end


function Schema:lock()
    local index = AUX.getIndex( self );
    local container;
    
    rawset( index, 'isa', nil );
    for _, k in ipairs({ 'enum', 'struct', 'pattern' }) do
        container = rawget( index, k );
        -- remove class
        rawset( AUX.getIndex( container ), 'CLASS_OF', nil );
        -- remove register function
        rawset( getmetatable( container ), '__call', nil );
    end
    -- remove lock method
    rawset( index, 'lock', nil );
end


return Schema.exports;

