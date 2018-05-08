--[[

  Copyright (C) 2015 Masatoshi Teruya

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


  lib/ddl/dict.lua
  lua-lschema
  Created by Masatoshi Teruya on 15/10/01.

--]]
-- module
local halo = require('halo');
local isString = require('isa').String;
local isTable = require('isa').Table;
local AUX = require('lschema.aux');
local Template = require('lschema.ddl.template');
-- constants
local FIELD_IDENT = {
    key = true,
    val = true
};


-- class
local Dict = halo.class.Dict;

Dict.inherits {
    'lschema.unchangeable.Unchangeable'
};

--[[
    MARK: Method
--]]

function Dict:init( name, tbl )
    local ISA = require('lschema.ddl.isa');
    local index = AUX.getIndex( self );
    local fields = {};
    local fn;

    AUX.abort(
        not isTable( tbl ),
        'argument must be type of table'
    );
    for id, isa in pairs( tbl ) do
        AUX.abort(
            not isString( id ) or not FIELD_IDENT[id],
            'identifier must be "key" or "val" : %q', tostring(id)
        );
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
        fields[id] = true;
    end

    -- verify
    for id in pairs( FIELD_IDENT ) do
        AUX.abort( not fields[id], '%q field is not defined', id );
    end

    -- make check function
    fn = Template.renderDict( AUX.discardMethods( self ), name, index['@'].attr );
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );

    return self;
end


return Dict.exports;
