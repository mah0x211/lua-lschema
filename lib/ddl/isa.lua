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
-- module
local halo = require('halo');
local inspect = require('util').inspect;
local is = require('util.is');
local lastIndex = require('util.table').lastIndex;
local AUX = require('lschema.aux');
local Template = require('lschema.ddl.template');
local Pattern = require('lschema.ddl.pattern');
-- constants
local INSPECT_OPT = { 
    depth = 0 
};


--[[-----------------------------------------------------------------------
        | string | number | int | uint | boolean | enum   | struct | table
===========================================================================
datatype| string | double | integer    | boolean | string | table
===========================================================================
notNull |   y    |   y    |  y  |  y   |    y    |  y     |   y    |   y
---------------------------------------------------------------------------
default |   y    |   y    |  y  |  y   |    y    |  y     |        |   y
---------------------------------------------------------------------------
unique  |   y    |   y    |  y  |  y   |    y    |  y     |        |
---------------------------------------------------------------------------
min     |   y    |   y    |  y  |  y   |         |        |        |
---------------------------------------------------------------------------
max     |   y    |   y    |  y  |  y   |         |        |        |
---------------------------------------------------------------------------
pattern |   y    |        |     |      |         |        |        |
---------------------------------------------------------------------------
of      |        |        |     |      |         |  y     |   y    |
---------------------------------------------------------------------------
          array field []
---------------------------------------------------------------------------
len     |   y    |   y    |  y  |  y   |    y    |  y     |   y    |
---------------------------------------------------------------------------
noDup   |   y    |   y    |  y  |  y   |    y    |  y     |        |
-------------------------------------------------------------------------]]

local ISA_TYPE = {
    ['string']      = { 'of', 'len', 'noDup' },
    ['number']      = { 'of', 'len', 'noDup', 'pattern' },
    ['int8']        = { 'of', 'len', 'noDup', 'pattern' },
    ['int16']       = { 'of', 'len', 'noDup', 'pattern' },
    ['int32']       = { 'of', 'len', 'noDup', 'pattern' },
    ['uint8']       = { 'of', 'len', 'noDup', 'pattern' },
    ['uint16']      = { 'of', 'len', 'noDup', 'pattern' },
    ['uint32']      = { 'of', 'len', 'noDup', 'pattern' },
    ['boolean']     = { 'of', 'len', 'noDup', 'pattern', 'min', 'max' },
    ['table']       = { 'of', 'len', 'noDup', 'pattern', 'min', 'max', 'unique' },
    ['enum']        = {       'len', 'noDup', 'pattern', 'min', 'max' },
    ['struct']      = {       'len', 'noDup', 'pattern', 'min', 'max' }
};

local ISA_TYPE_NAMES = table.concat({
    'string',
    'number',
    'int8',
    'int16',
    'int32',
    'uint8',
    'uint16',
    'uint32',
    'boolean',
    'table',
    'enum',
    'struct'
}, ' | ' );

local ISA_ARRAY_ATTR = {
    ['len']     = true,
    ['noDup']   = true
};

local ISA_AKA = {
    ['number']  = 'finite',
    ['enum']    = 'string',
    ['struct']  = 'table'
};

local ISA_OF = {
    ['enum']    = require('lschema.ddl.enum'),
    ['struct']  = require('lschema.ddl.struct')
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


local function toboolean( arg )
    local t = type( arg );
    
    if t == 'boolean' then
        return arg;
    elseif t == 'string' then
        if arg == 'true' then
            return true;
        elseif arg == 'false' then
            return false;
        end
    elseif t == 'number' then
        return is.finite( arg ) and arg ~= 0;
    end
end


-- class
local ISA = halo.class.ISA;

ISA.inherits {
    'lschema.unchangeable.Unchangeable'
};


--- initializer
-- @param   ddl ddl
-- @param   isa string | number | int* | uint* | boolean | table | enum | struct
function ISA:init( typ )
    local index = AUX.getIndex( self );
    local isa, asArray, methods;

    AUX.abort( not is.string( typ ), 'argument must be type of string' );
    
    -- extract array symbol
    isa, asArray = typ:match( '^(%a+[%d]*)(.*)$' );
    
    methods = ISA_TYPE[isa];
    AUX.abort(
	    not methods,
	    'data type must be the following types; %s',
	    ISA_TYPE_NAMES
	);
	
    if asArray then
        if asArray == '' then
            asArray = nil;
        else
            AUX.abort( asArray ~= '[]', 'unknown data type %q', typ );
            AUX.abort( isa == 'table', 'table type does not support array' );
        end
    end
    
    -- set isa
    rawset( index, 'isa', isa );
    rawset( index, 'asArray', asArray ~= nil );
    -- remove unused methods
    for _, method in ipairs( methods ) do
        if not ISA_ARRAY_ATTR[method] or not asArray then
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
        'value must be instance of %q class', self.isa
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
        not is.uint( min ),
        'could not set len constraint: ' ..
        'minimum value must be type of uint'
    );
    if max ~= nil then
        AUX.abort( 
            not is.uint( max ),
            'could not set len constraint: ' ..
            'maximum value must be type of uint'
        );
        AUX.abort( 
            max < min, 
            'could not set len constraint: ' ..
            'maximum value #%d must be greater than ' .. 
            'minimum value #%d', max, min
        );
    end
    
    -- check default value length
    if is.table( self.default ) then
        local len = #self.default;
        
        AUX.abort( 
            len < min,
            'could not set len constraint: ' ..
            'default value length is less than ' ..
            'minimum value #%d',
            min
        );
        AUX.abort( 
            len > max,
            'could not set len constraint: ' ..
            'default value length is greater than ' .. 
            'maximum value #%d',
            max
        );
    end
    
    rawset( index, 'len', { min = min, max = max } );
    
    return self;
end


--- no duplicate
function ISA:noDup( ... )
    local index = AUX.getIndex( self );
    
    checkOfAttr( index, self.isa );
    -- do not pass arguments
    AUX.abort( #{...} > 0, 'should not pass argument' );
    
    -- check default value duplication
    if is.table( self.default ) then
        local dupIdx = {};
        
        for idx, val in ipairs( self.default ) do
            val = inspect( val, INSPECT_OPT );
            AUX.abort( 
                dupIdx[val],
                'could not set noDup constraint: ' ..
                'default value#%d %q duplicated with #%d', 
                idx, val, dupIdx[val]
            );
            dupIdx[val] = idx;
        end
    end
    
    rawset( AUX.getIndex( self ), 'noDup', true );
    
    return self;
end


--- not null(empty array will be interpreted as a null)
function ISA:notNull( ... )
    local index = AUX.getIndex( self );
    
    checkOfAttr( index, self.isa );
    -- do not pass arguments
    AUX.abort( #{...} > 0, 'should not pass argument' );
    rawset( index, 'notNull', true );
    
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
function ISA:min( min )
    local numType = self.isa == 'string' and 'uint' or 
                    self.isa == 'number' and 'finite' or
                    self.isa;
    -- check type
    AUX.abort( 
        not is[numType]( min ), 
        'could not set min constraint: ' .. 
        'value %q must be %s number', 
        min, numType
    );
    -- check max constraint
    AUX.abort( 
        is[numType]( self.max ) and min > self.max, 
        'could not set min constraint: ' ..
        'value must be less than max constraint value #%d',
        self.max
    );
    -- check default value size
    if not is.Function( self.default ) then
        local defval = self.default;
        
        if self.asArray then
            for idx, val in ipairs( defval ) do
                AUX.abort(
                    ( is.string( val ) and #val or val ) < min,
                    'could not set min value constraint: ' .. 
                    'default value#%d is less than min constraint value #%d',
                    idx, min
                );
            end
        else
            AUX.abort(
                ( is.string( defval ) and #defval or defval ) < min,
                'could not set min value constraint: ' .. 
                'default value is less than min constraint value #%d',
                min
            );
        end
    end
    
    rawset( AUX.getIndex( self ), 'min', min );
    
    return self;
end


--- max
-- @param   val number of maxium
function ISA:max( max )
    local numType = self.isa == 'string' and 'uint' or 
                    self.isa == 'number' and 'finite' or
                    self.isa;
    -- check type
    AUX.abort( 
        not is[numType]( max ), 
        'could not set max constraint: ' .. 
        '%q must be %s number', max, numType
    );
    -- check min constraint
    AUX.abort( 
        is[numType]( self.min ) and max < self.min, 
        'could not set max constraint: ' .. 
        'value must be greater than min constraint value #%d', 
        self.min
    );
    -- check default value size
    if not is.Function( self.default ) then
        local defval = self.default;
        
        if self.asArray then
            for idx, val in ipairs( defval ) do
                AUX.abort(
                    ( is.string( val ) and #val or val ) > max,
                    'could not set max value constraint: ' .. 
                    'default value#%d is greater than max constraint #%d',
                    idx, max
                );
            end
        else
            AUX.abort(
                ( is.string( defval ) and #defval or defval ) > max,
                'could not set max value constraint: ' .. 
                'default value is greater than max constraint #%d',
                max
            );
        end
    end

    rawset( AUX.getIndex( self ), 'max', max );
    
    return self;
end


-- pattern
function ISA:pattern( pat )
    AUX.abort(
        not halo.instanceof( pat, Pattern ), 
        'could not set pattern constraint: ' ..
        'value must be instance of Pattern'
    );
    
    -- check default value
    if not is.Function( self.default ) then
        if self.asArray then
            for idx, val in ipairs( self.default ) do
                AUX.abort(
                    not pat:exec( val ),
                    'could not set pattern constraint: ' ..
                    'default value#d %q does not match to pattern %q',
                    idx, val, pat['@'].name
                );
            end
        else
            AUX.abort(
                not pat:exec( self.default ),
                'could not set pattern constraint: ' ..
                'default value %q does not match to pattern %q',
                self.default, pat['@'].name
            );
        end
    end
    
    rawset( AUX.getIndex( self ), 'pattern', pat );
    
    return self;
end


--- default
-- @param   val default value
function ISA:default( val )
    local index = AUX.getIndex( self );
    local isa = self.isa;
    local aka = ISA_AKA[isa] or isa;
    local tail = 1;
    local arr, len, errmsgPrefix, noDup, dupIdx, err, _;
    
    checkOfAttr( index, isa );
    if self.asArray then
        arr = val;
        
        -- manipulate error message
        errmsgPrefix = ('could not set default value %q: '):format( 
            tostring( val )
        );
        
        AUX.abort( 
            not is.table( arr ),
            errmsgPrefix .. 'value must be type of array(table)'
        );
        
        -- check last index
        tail = lastIndex( arr );
        AUX.abort( 
            tail and tail < 1,
            errmsgPrefix .. 'index must be start at 1'
        );
        
        -- check array length constraint
        if is.table( self.len ) then
            len = self.len;
            AUX.abort( 
                not tail or tail < len.min, 
                errmsgPrefix .. 'minimum length constraint #%d violated',
                len.min
            );
            AUX.abort( 
                len.max and ( not tail or tail > len.max ),
                errmsgPrefix .. 'maximum length constraint #%d violated',
                len.max
            );
        end
        
        -- init noDup constraint check variables
        if is.boolean( self.noDup ) and self.noDup then
            dupIdx = {};
            noDup = true;
        end
    
    -- wrap to table
    else
        arr = { val };
    end
    
    -- check value
    for i = 1, tail or 0 do
        len = nil;
        val = arr[i];
        
        -- manipulate error message
        errmsgPrefix = 'could not set default value' .. 
                       ( self.asArray and '#' .. i or '' ) .. 
                       (' %q: '):format( tostring( val ) );
        -- check type
        AUX.abort( 
            not is[aka]( val ), 
            errmsgPrefix .. 'must be type of %s', aka 
        );
        
        if isa == 'enum' then
            AUX.abort( 
                not self.enum( val ), 
                errmsgPrefix .. 'value is not defined at enum %q',
                self.enum['@'].name
            );
        elseif isa == 'struct' then
            _, err = self.struct( val );
            AUX.abort(
                err,
                errmsgPrefix .. 'value does not match to struct %q',
                self.struct['@'].name
            );
        else
            -- for string
            if isa == 'string' then
                -- check pattern constraint
                if halo.instanceof( self.pattern, Pattern ) then
                    AUX.abort(
                        not self.pattern:exec( val ),
                        errmsgPrefix .. 'pattern constraint %q violated',
                        self.pattern['@'].name
                    );
                end
                len = #val;
            -- for number
            elseif is.finite( val ) then
                len = val;
            end
            
            -- check min/max constraint
            if len then
                -- min check
                if is.finite( self.min ) then
                    AUX.abort(
                        len < self.min,
                        errmsgPrefix .. 'min constraint #%d violated',
                        self.min
                    );
                end
                -- max check
                if is.finite( self.max ) then
                    AUX.abort(
                        len > self.max,
                        errmsgPrefix .. 'max constraint #%d violated',
                        self.max
                    );
                end
            end
        end
        
        -- check noDup constraint
        if noDup then
            val = inspect( val, INSPECT_OPT );
            AUX.abort(
                dupIdx[val],
                errmsgPrefix ..
                'noDup constraint violated - ' ..
                'value duplicated with #%d',
                dupIdx[val]
            );
            dupIdx[val] = i;
        end
    end
    
    rawset( index, 'default', self.asArray and arr or arr[1] );
    
    return self;
end


function ISA:makeCheck()
    local index = AUX.getIndex( self );
    local isa = self.isa;
    local env, fields, fn;
    
    checkOfAttr( index, isa );
    -- remove unused methods
    fields = AUX.discardMethods( self );
    -- create environment
    env = {
        rawset      = rawset, 
        rawget      = rawget,
        tonumber    = tonumber,
        tostring    = tostring,
        toboolean   = toboolean,
        type        = type,
        is          = is,
        pattern     = rawget( fields, 'pattern' ),
        enum        = rawget( fields, 'enum' ),
        struct      = rawget( fields, 'struct' ),
        lastIndex   = self.asArray and require('util.table').lastIndex or nil
    };
    fields.attr = inspect( index['@'].attr, INSPECT_OPT );
    -- serialize table type default value
    if is.table( fields.default ) then
        fields.default = inspect( fields.default, INSPECT_OPT );
    end
    
    -- make check function
    fn = Template.renderISA( fields, env );
    -- set generated function to __call metamethod
    AUX.setCallMethod( self, fn );
end


return ISA.exports;

