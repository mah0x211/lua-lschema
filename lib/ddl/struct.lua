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
local eval = require('util').eval;
local typeof = require('util.typeof');
local AUX = require('lschema.aux');
local Struct = halo.class.Struct;

Struct.inherits {
    'lschema.aux.AUX',
    except = {
        static = {
            'isValidIdent', 'getIndex', 'setCall', 'abort', 'discardMethods',
            'posing'
        }
    }
};

--[[
    MARK: Metamethod
--]]
function Struct:__call( tbl )
    if type( tbl ) == 'table' then
        local errtbl = {};
        local field, verify, val, err, gotError;
        
        for field, verify in pairs( self.fields ) do
            val, err = verify( tbl[field] );
            if err then
                rawset( errtbl, field, err );
                gotError = true;
            else
                tbl[field] = val;
            end
        end
        
        return tbl, gotError and errtbl or nil;
    end
    
    return nil, errno.ETYPE;
end


--[[
    MARK: Method
--]]
function Struct:init( tbl )
    local ISA = require('lschema.ddl.isa');
    local index = AUX.getIndex( self );
    local id, isa, tmpl, err;
    
    AUX.abort( 
        not typeof.table( tbl ), 
        'argument must be type of table'
    );
    for id, isa in pairs( tbl ) do
        AUX.isValidIdent( self, id );
        AUX.abort( 
            rawget( index, id ), 
            'identifier %q already defined', id 
        );
        AUX.abort( 
            not halo.instanceof( isa, ISA ), 
            'value %q must be instance of schema.ddl.ISA class', isa
        );
        
        if not AUX.hasCallMethod( isa ) then 
            isa:makeCheck();
        end
        
        rawset( index, id, isa );
    end
    
    AUX.discardMethods( self );

    return self;
end


return Struct.exports;
