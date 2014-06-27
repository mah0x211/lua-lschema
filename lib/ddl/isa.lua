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
  
  
  lib/ddl/isa.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/08.

--]]
local halo = require('halo');
local typeof = require('util.typeof');
local AUX = require('lschema.aux');
local Template = require('lschema.ddl.template');
local Pattern = require('lschema.ddl.pattern');
local ISA = halo.class.ISA;

ISA.inherits {
    'lschema.aux.AUX',
    except = {
        static = {
            'isValidIdent', 'getIndex', 'setCall', 'abort', 'discardMethods',
            'posing'
        }
    }
};


--[[
-------------------------------------------------------------------------
            | of | notNull | unique | min | max | pattern | default | len
-------------------------------------------------------------------------
 string     |    | y       | y      | y   | y   | y       | y
-------------------------------------------------------------------------
 number     |    | y       | y      | y   | y   |         | y
-------------------------------------------------------------------------
 unsigned   |    | y       | y      | y   | y   |         | y
-------------------------------------------------------------------------
 int        |    | y       | y      | y   | y   |         | y
-------------------------------------------------------------------------
 uint       |    | y       | y      | y   | y   |         | y
-------------------------------------------------------------------------
 boolean    |    | y       |        |     |     |         | y
-------------------------------------------------------------------------
 enum       | y  | y       |        |     |     |         | y
-------------------------------------------------------------------------
 struct     | y  | y       |        |     |     |         |
-------------------------------------------------------------------------
--]]
local ISA_TYPE = {
    ['string']      = { 'of', 'len' },
    ['number']      = { 'of', 'len', 'pattern' },
    ['unsigned']    = { 'of', 'len', 'pattern' },
    ['int']         = { 'of', 'len', 'pattern' },
    ['uint']        = { 'of', 'len', 'pattern' },
    ['boolean']     = { 'of', 'len', 'min', 'max', 'pattern', 'unique' },
    ['enum']        = { 'len', 'min', 'max', 'pattern' },
    ['struct']      = { 'len', 'min', 'max', 'pattern', 'default' }
};

local ISA_AKA = {
    ['number']  = 'finite',
    ['enum']    = 'string'
};

local ISA_OF = {
    ['enum']        = require('lschema.ddl.enum'),
    ['struct']      = require('lschema.ddl.struct')
};

local function checkOfAttr( index, isa )
    if isa == 'enum' or isa == 'struct' then
        AUX.abort( 
            rawget( index, isa ) == nil, 
            ('%q must be set "of" attribute before other attributes')
            :format( isa )
        );
    end
end


--- initializer
-- @param   ddl ddl
-- @param   isa string | number | unsigned | int | uint | boolean | enum | struct
function ISA:init( isa )
    local index = AUX.getIndex( self );
    local asArray, methods, i, method;

    AUX.abort( 
        not typeof.string( isa ), 
        'argument must be type of string'
    );
    
    -- extract array symbol
    isa, asArray = isa:match( '^(%a+)([^%a]*)$' );
    if asArray == '' then
        asArray = nil;
    end
    
    methods = ISA_TYPE[isa];
    AUX.abort( 
        not methods or asArray and asArray ~= '[]', 
        'data type must be typeof %s',
        'string | number | unsigned | int | uint | boolean | enum'
    );
    
    -- set isa
    rawset( index, 'isa', isa );
    rawset( index, 'asArray', asArray ~= nil );
    -- remove unused methods
    for i, method in ipairs( methods ) do
        if method ~= 'len' or not asArray then
            rawset( index, method, nil );
        end
    end
    
    return self;
end

--- of: enum, struct
function ISA:of( val )
    local index = AUX.getIndex( self );
    local class = ISA_OF[self.isa];
    
    -- check instanceof
    AUX.abort( 
        not halo.instanceof( val, class ), 
        'value must be instance of %q class', isa
    );
    
    rawset( index, self.isa, val );
    rawset( index, 'of', nil );
    
    return self;
end


--- len
function ISA:len( min, max )
    local index = AUX.getIndex( self );
    
    checkOfAttr( index, self.isa );
    AUX.abort( 
        not typeof.uint( min ), 
        'min value of array length must be type of unsigned integer'
    );
    if max ~= nil then
        AUX.abort( 
            max and not typeof.uint( max ), 
            'max value of array length must be type of unsigned integer'
        );
        AUX.abort( 
            max < min, 
            'max value of array length must be greater than min value of length'
        );
    end
    
    rawset( index, 'len', { min = min, max = max } );
    
    return self;
end

--- not null
function ISA:notNull( ... )
    local index = AUX.getIndex( self );
    
    checkOfAttr( index, self.isa );
    AUX.abort( 
        #{...} > 0, 
        'should not pass argument' 
    );
    rawset( index, 'notNull', true );
    rawset( index, 'default', nil );
    
    return self;
end


--- unique
function ISA:unique( ... )
    AUX.abort( #{...} > 0, 'should not pass argument' );
    rawset( AUX.getIndex( self ), 'unique', true );
    
    return self;
end


--- min
-- @param   val number of minimum
function ISA:min( val )
    local numType = self.isa == 'string' and 'uint' or 
                    self.isa == 'number' and 'finite' or
                    self.isa;
    
    AUX.abort( 
        not typeof[numType]( val ), 
        'min %q must be %s number', val, numType
    );
    AUX.abort( 
        typeof[numType]( self.max ) and val > self.max, 
        'min %d must be less than max: %d', val, self.max
    );
    
    rawset( AUX.getIndex( self ), 'min', val );
    
    return self;
end


--- max
-- @param   val number of maxium
function ISA:max( val )
    local numType = self.isa == 'string' and 'uint' or 
                    self.isa == 'number' and 'finite' or
                    self.isa;
    
    AUX.abort( 
        not typeof[numType]( val ), 
        'max %q must be %s number', val, numType
    );
    AUX.abort( 
        typeof[numType]( self.min ) and val < self.min, 
        'max %d must be greater than min: %d', val, self.min
    );
    
    rawset( AUX.getIndex( self ), 'max', val );
    
    return self;
end


-- pattern
function ISA:pattern( val )
    AUX.abort( 
        not halo.instanceof( val, Pattern ), 
        'pattern must be instance of Pattern'
    );
    rawset( AUX.getIndex( self ), 'pattern', val );
    
    return self;
end


--- default
-- @param   val default value
function ISA:default( val )
    local index = AUX.getIndex( self );
    local isa = self.isa;
    local aka = ISA_AKA[isa] or isa;
    
    checkOfAttr( index, isa );
    AUX.abort( 
        not typeof[aka]( val ), 
        'default value %q must be type of %s', val, aka 
    );
    
    if isa == 'enum' then
        AUX.abort( 
            not self.enum( val ), 
            'default value %q is not defined at enum', val 
        );
    end
    
    rawset( index, 'default', val );
    rawset( index, 'notNull', nil );
    
    return self;
end


function ISA:makeCheck()
    local index = AUX.getIndex( self );
    local isa = self.isa;
    local env, fields, fn;
    
    checkOfAttr( index, isa );
    -- remove unused methods
    AUX.discardMethods( self );
    fields = rawget( index, 'fields' );
    -- create environment
    env = {
        rawset = rawset, 
        rawget = rawget,
        type = type,
        typeof = typeof,
        pattern = rawget( fields, 'pattern' ),
        enum = rawget( fields, 'enum' ),
        struct = rawget( fields, 'struct' )
    };
    -- make check function
    fn = Template.renderISA( fields, env );
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );
end


return ISA.exports;

