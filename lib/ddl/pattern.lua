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
  
  
  lib/ddl/pattern.lua
  lua-lschema
  Created by Masatoshi Teruya on 14/06/12.

--]]

local is = require('util.is');
local lrex = require('rex_pcre');
local unpack = unpack or table.unpack;
local AUX = require('lschema.aux');
local Pattern = require('halo').class.Pattern;

Pattern.inherits {
    'lschema.unchangeable.Unchangeable'
};


-- EMAIL REGEXP
do
    -- SPECIAL-CHARACTORS
    local SPECIAL_SYMBOLS   = "!#$%&'*/=?^`{|}~";
    local SYMBOLS           = "-_+"; -- .. SPECIAL_SYMBOLS;
    -- ALPHABETIC+DIGIT
    local ALPHANUM          = "[a-zA-Z0-9]";
    -- LOCAL-PART
    local ATEXT             = "(?:[" .. SYMBOLS .. "]*" .. ALPHANUM .. ")";
    local DOT_ATOM          = "(?:" .. ATEXT .. "+(?:\\." .. ATEXT .. "+)*)";
    -- QTEXT
    -- 0x21     : [!] 
    -- 0x23-0x5b: [#$%&'()*+,=./] [0-9] [:;<=>?@] [A-Z[]
    -- 0x5d-0x7e: []^_`] [a-z] [{|}~]
    local QTEXT             = "(?:\"(?:[\\x21\\x23-\\x5b\\x5d-\\x7e])*\")";
    local LOCAL_PART        = "(?:" .. DOT_ATOM .. "|" .. QTEXT .. ")";
    -- DOMAIN
    local DOMAIN_ATEXT      = "[a-zA-Z0-9](?:(?:-*[a-zA-Z0-9]){0,62})";
    local DOMAIN_TAIL       = "[a-zA-Z]+";
    local DOMAIN_DOT_ATOM   = "(?:" .. DOMAIN_ATEXT .. 
                              "(?:\\." .. DOMAIN_ATEXT .. "+)*\\." .. 
                              DOMAIN_TAIL .. ")";
    local IPV4_RANGE        = "(?:2[0-5]{2}|1[0-9]{2}|[0-9]{1,2})";
    local IPV4              = "(?:\\[" .. IPV4_RANGE .. 
                              "(?:\\." .. IPV4_RANGE .. "){3}\\])"
    local DOMAIN            = "(?:" .. 
                                DOMAIN_DOT_ATOM .. "|" .. 
                                IPV4 .. "|" .. 
                              ")";
    -- set ADDR-SPEC
    local ADDR_SPEC         = "^(?:" .. LOCAL_PART .. "@" .. DOMAIN .. ")$";
    
    -- set ADDR-SPEC-LOOSE
    local DOT_ATOM_LOOSE    = "(?:" .. ATEXT .. "+(?:\\.|" .. ATEXT .. ")*)";
    local LOCAL_PART_LOOSE  = "(?:" .. DOT_ATOM_LOOSE .. "|" .. QTEXT .. ")";
    local ADDR_SPEC_LOOSE   = "^(?:" .. LOCAL_PART_LOOSE .. "@" .. DOMAIN .. ")$";
    
    Pattern.property {
        email = ADDR_SPEC,
        emailLoose = ADDR_SPEC_LOOSE
    };
end

--[[
    MARK: Method
--]]
function Pattern:init( _, tbl )
    local own = protected( self );
    local index = AUX.getIndex( self );
    
    AUX.abort( 
        not is.table( tbl ),
        'argument must be type of table'
    );
    AUX.abort( 
        not is.string( tbl[1] ),
        'pattern[1] must be type of string'
    );
    
    index['@'] = {
        attr = {
            regex = tbl[1],
            opts = select( 2, tbl )
        }
    };
    own.regex = lrex.new( unpack( tbl ) );
    
    return self;
end


function Pattern:exec( ... )
    return protected( self ).regex:exec( ... );   
end


function Pattern:match( ... )
    return protected( self ).regex:match( ... );   
end


return Pattern.exports;
