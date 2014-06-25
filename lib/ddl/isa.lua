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
local Check = require('lschema.ddl.check');
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
    ['string']      = { 'of' },
    ['number']      = { 'of', 'pattern' },
    ['unsigned']    = { 'of', 'pattern' },
    ['int']         = { 'of', 'pattern' },
    ['uint']        = { 'of', 'pattern' },
    ['boolean']     = { 'of', 'min', 'max', 'pattern', 'unique' },
    ['enum']        = { 'min', 'max', 'pattern' },
    ['struct']      = { 'min', 'max', 'pattern', 'default' }
};

local ISA_OF = {
    ['enum']        = require('lschema.ddl.enum'),
    ['struct']      = require('lschema.ddl.struct')
};

local CONSTRAINT_NUMBER = {
    ['unsigned']    = true,
    ['int']         = true,
    ['uint']        = true
};

--- initializer
-- @param   ddl ddl
-- @param   isa string | number | unsigned | int | uint | boolean | enum | struct
function ISA:init( isa )
    local internal = protected( self );
    local index = AUX.getIndex( self );
    local methods = ISA_TYPE[isa];
    local i, method;
    
    AUX.abort( 
        not methods, 
        'data type must be typeof %s',
        'string | number | unsigned | int | uint | boolean | enum'
    );
    
    -- set isa
    rawset( index, 'isa', isa );
    -- create instance of Check class
    rawset( internal, 'check', Check.new( isa ) );
    -- remove unused methods
    for i, method in ipairs( methods ) do
        rawset( index, method, nil );
    end
    
    return self;
end

--- of: enum, struct
function ISA:of( val )
    local class = ISA_OF[self.isa];
    
    -- check instanceof
    AUX.abort( 
        not halo.instanceof( val, class ), 
        'value must be instance of %q class', isa
    );
    
    rawset( AUX.getIndex( self ), 'of', val );
    
    return self;
end


--- not null
function ISA:notNull( ... )
    AUX.abort( 
        ISA_OF[self.isa] and typeof.Function( self.of ), 
        ('%q must be set "of" attribute before other attributes'):format( self.isa )
    );
    AUX.abort( 
        #{...} > 0, 
        'should not pass argument' 
    );
    rawset( AUX.getIndex( self ), 'notNull', true );
    protected( self ).check:notNull();
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
    AUX.abort( 
        not typeof.finite( val ), 
        'min %q must be finite number', val 
    );
    AUX.abort( 
        typeof.finite( self.max ) == 'number' and val > self.max, 
        'min %d must be less than max: %d', val, self.max
    );
    
    if CONSTRAINT_NUMBER[self.isa] then
        AUX.abort( 
            not typeof[self.isa]( val ), 
            'min %d must be type of %d', val, self.isa
        );
    end
    
    rawset( AUX.getIndex( self ), 'min', val );
    protected( self ).check:min( val );
    
    return self;
end


--- max
-- @param   val number of maxium
function ISA:max( val )
    AUX.abort( 
        not typeof.finite( val ), 
        'max %q must be finite number', val 
    );
    AUX.abort( 
        typeof.finite( self.min ) and val < self.min, 
        'max %d must be greater than min: %d', val, self.min
    );
    
    if CONSTRAINT_NUMBER[self.isa] then
        AUX.abort( 
            not typeof[self.isa]( val ), 
            'max %d must be type of %d', val, self.isa
        );
    end
    
    rawset( AUX.getIndex( self ), 'max', val );
    protected( self ).check:max( val );
    
    return self;
end


-- pattern
function ISA:pattern( val )
    AUX.abort( 
        not halo.instanceof( val, Pattern ), 
        'pattern must be instance of Pattern'
    );
    rawset( AUX.getIndex( self ), 'pattern', val );
    protected( self ).check:pattern( val );
    
    return self;
end


--- default
-- @param   val default value
function ISA:default( val )
    local isa = self.isa == 'enum' and 'string' or 
                self.isa == 'number' and 'finite' or
                self.isa;
    
    AUX.abort( 
        ISA_OF[self.isa] and typeof.Function( self.of ), 
        ('%q must be set "of" attribute before other attributes'):format( self.isa )
    );
    AUX.abort( 
        val == nil and self.notNull, 
        'default value must not be nil' 
    );
    AUX.abort( 
        val ~= nil and not typeof[isa]( val ), 
        'default value %q must be type of %s', val, isa 
    );
    
    if self.isa == 'enum' then
        AUX.abort( 
            not rawget( self.of.fields, val ), 
            'default value %q is not defined at enum', val 
        );
    end
    
    rawset( AUX.getIndex( self ), 'default', val );
    protected( self ).check:default( val );
    
    return self;
end

function ISA:makeCheck()
    local index = AUX.getIndex( self );
    local internal = protected( self );
    local check = rawget( internal, 'check' );
    local valof = rawget( index, 'of' );
    local fn;
    
    if valof then
        check[index.isa]( check, valof );
        -- remove related instance
        rawset( index, 'of', nil );
    end
    
    -- make check function
    fn = check:make();
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );
    -- remove instance of Check class
    rawset( internal, 'check', nil );
    -- remove unused methods
    AUX.discardMethods( self );
end


return ISA.exports;

