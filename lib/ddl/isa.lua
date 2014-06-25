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
local Enum = require('lschema.ddl.enum');
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

local ISA_TYPE = {
    ['string']      = {},
    ['number']      = { 'pattern' },
    ['unsigned']    = { 'pattern' },
    ['int']         = { 'pattern' },
    ['uint']        = { 'pattern' },
    ['boolean']     = { 'min', 'max', 'pattern', 'unique' },
    ['enum']        = { 'min', 'max', 'pattern' },
    --['struct']  = { 'min', 'max', 'pattern', 'default' }
};

local CONSTRAINT_NUMBER = {
    ['unsigned']    = true,
    ['int']         = true,
    ['uint']        = true
};

--- initializer
-- @param   ddl     ddl
-- @param   isa     string | number | unsigned | int | uint | boolean | enum | array
-- @param   rel     relation name if isa is table | enum
function ISA:init( isa, rel )
    local index = AUX.getIndex( self );
    local methods = ISA_TYPE[isa];
    local check, i, method;
    
    AUX.abort( 
        not methods, 
        'data type must be typeof %s',
        'string | number | unsigned | int | uint | boolean | enum'
    );
    
    -- set isa
    rawset( index, 'isa', isa );
    -- create instance of Check class
    check = Check.new( isa );
    rawset( index, '_check', check );
    -- check relation
    if isa == 'enum' then
        self:abort( 
            not halo.instanceof( rel, Enum ), 
            '%s %q is not defined', isa, rel
        );
        -- set reference of related instance
        rawset( index, 'rel', rel );
    end

    -- remove unused methods
    for i, method in ipairs( methods ) do
        rawset( index, method, nil );
    end
    
    return self;
end


--- not null
function ISA:notNull( ... )
    AUX.abort( #{...} > 0, 'should not pass argument' );
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
    
    self._check:min( val );
    rawset( AUX.getIndex( self ), 'min', val );
    
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
    
    self._check:max( val );
    rawset( AUX.getIndex( self ), 'max', val );
    
    return self;
end


-- pattern
function ISA:pattern( val )
    AUX.abort( 
        not halo.instanceof( val, Pattern ), 
        'pattern must be instance of Pattern'
    );
    self._check:pattern( val );
    rawset( AUX.getIndex( self ), 'pattern', val );
    
    return self;
end


--- default
-- @param   val default value
function ISA:default( val )
    local isa = self.isa == 'enum' and 'string' or 
                self.isa == 'number' and 'finite' or
                self.isa;
    
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
    
    rawset( self:getIndex(), 'default', val );
    self._check:default( val );
    
    return self;
end


function ISA:makeCheck()
    local check = index._check;
    local index = AUX.getIndex( self );
    local fn;
    
    if rawget( index, 'rel' ) then
        check[index.isa]( check, index.rel.fields );
        -- remove related instance
        rawset( index, 'rel', nil );
    end
    
    -- make check function
    fn = check:make();
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );
    -- remove instance of Check class
    rawset( index, '_check', nil );
    -- remove unused methods
    -- save check function
    rawset( index, 'check', fn );
    AUX.discardMethods( self );
end


return ISA.exports;

