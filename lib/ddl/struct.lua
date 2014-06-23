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
  
  
  lib/ddl/struct.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/09.

--]]
local halo = require('halo');
local typeof = require('util.typeof');
local ISA = require('lschema.ddl.isa');
local Struct = halo.class.Struct;

Struct.inherits {
    'lschema.poser.Poser'
};

--[[
    MARK: Method
--]]
function Struct:init( tbl )
    local private = self:getPrivate();
    local id,isa;
    
    self:abort( 
        not typeof.table( tbl ), 
        'argument must be type of table'
    );
    for id, isa in pairs( tbl ) do
        self:isValidIdent( id );
        self:abort( 
            rawget( private, id ), 
            'identifier %q already defined', id 
        );
        self:abort( 
            not halo.instanceof( isa, ISA ), 
            'value %q must be instance of class schema.isa', isa
        );
        
        if typeof.Function( isa.fields ) then 
            isa:makeCheck();
        end
        rawset( private, id, isa );
    end
    
    self:discardMethods();
    
    return self;
end


return Struct.exports;
