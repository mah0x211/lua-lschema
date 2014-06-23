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
local Check = require('lschema.ddl.check');
local Enum = require('lschema.ddl.enum');
local Pattern = require('lschema.ddl.pattern');
local ISA = halo.class.ISA;

ISA.inherits {
    'lschema.poser.Poser'
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
-- @param   isa     string | number | boolean | table | array
-- @param   rel     relation name if isa is table | enum
function ISA:init( isa, rel )
    local private = self:getPrivate();
    local methods = ISA_TYPE[isa];
    local check, i, method;
    
    self:abort( 
        not methods, 
        'data type must be typeof %s',
        'string | number | unsigned | int | uint | boolean | enum'
    );
    
    -- set isa
    rawset( private, 'isa', isa );
    -- create instance of Check class
    check = Check.new( isa );
    rawset( private, '_check', check );
    -- check relation
    if isa == 'enum' then
        self:abort( 
            not halo.instanceof( rel, Enum ), 
            '%s %q is not defined', isa, rel
        );
        -- set reference of related instance
        rawset( private, 'rel', rel );
    end
    
    -- remove unused methods
    for i, method in ipairs( methods ) do
        rawset( private, method, nil );
    end
    
    return self;
end


--- not null
function ISA:notNull( ... )
    self:abort( #{...} > 0, 'should not pass argument' );
    rawset( self:getPrivate(), 'notNull', true );
    self._check:notNull();
    return self;
end


--- unique
function ISA:unique( ... )
    self:abort( #{...} > 0, 'should not pass argument' );
    rawset( self:getPrivate(), 'unique', true );
    return self;
end


--- min
-- @param   val number of minimum
function ISA:min( val )
    self:abort( 
        not typeof.finite( val ), 
        'min %q must be finite number', val 
    );
    self:abort( 
        typeof.finite( self.max ) == 'number' and val > self.max, 
        'min %d must be less than max: %d', val, self.max
    );
    
    if CONSTRAINT_NUMBER[self.isa] then
        self:abort( 
            not typeof[self.isa]( val ), 
            'min %d must be type of %d', val, self.isa
        );
    end
    
    rawset( self:getPrivate(), 'min', val );
    self._check:min( val );
    
    return self;
end


--- max
-- @param   val number of maxium
function ISA:max( val )
    self:abort( 
        not typeof.finite( val ), 
        'max %q must be finite number', val 
    );
    self:abort( 
        typeof.finite( self.min ) and val < self.min, 
        'max %d must be greater than min: %d', val, self.min
    );
    
    if CONSTRAINT_NUMBER[self.isa] then
        self:abort( 
            not typeof[self.isa]( val ), 
            'max %d must be type of %d', val, self.isa
        );
    end
    
    rawset( self:getPrivate(), 'max', val );
    self._check:max( val );
    
    return self;
end


-- pattern
function ISA:pattern( val )
    self:abort( 
        not halo.instanceof( val, Pattern ), 
        'pattern must be instance of Pattern'
    );
    rawset( self:getPrivate(), 'pattern', val );
    self._check:pattern( val );
    
    return self;
end


--- default
-- @param   val default value
function ISA:default( val )
    local isa = self.isa == 'enum' and 'string' or 
                self.isa == 'number' and 'finite' or
                self.isa;
    
    self:abort( 
        val == nil and self.notNull, 
        'default value must not be nil' 
    );
    self:abort( 
        val ~= nil and not typeof[isa]( val ), 
        'default value %q must be type of %s', val, isa 
    );
    
    if self.isa == 'enum' then
        self:abort( 
            not rawget( self.rel.fields, val ), 
            'default value %q is not defined at enum', val 
        );
    end
    
    rawset( self:getPrivate(), 'default', val );
    self._check:default( val );
    
    return self;
end


function ISA:makeCheck()
    local private = self:getPrivate();
    local check = private._check;
    local fn;
    
    if rawget( private, 'rel' ) then
        check[private.isa]( check, private.rel.fields );
        -- remove related instance
        rawset( private, 'rel', nil );
    end
    
    -- make check function
    fn = check:make();
    -- remove instance of Check class
    rawset( private, '_check', nil );
    -- remove unused methods
    self:discardMethods();
    -- save check function
    rawset( private, 'check', fn );
end


return ISA.exports;

