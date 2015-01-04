local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa = myschema.isa('int8');
local err, _;

isa:makeCheck();
-- invalid
for _, val in ipairs({
    -- boolean
        true, false,
    -- string
        'string', '',
    -- function
        function()end,
    -- table
        {},
    -- thread
        coroutine.create(function() end),
    -- inf
        -(1/0), 1/0,
    -- nan
        0/0,
    -- float
        0.1,
    -- negative float
        -0.1,
    -- int8 min - 1, int8 max + 1
        -129, 128,
    -- int16
        -32768, 32767,
    -- int32
        -2147483648, 2147483647,
    -- uint8
        255,
    -- uint16
        65535,
    -- uint32
        4294967295
}) do
    _, err = isa( val );
    ifNil( err );
    ifNotEqual( err.errno, errno.ETYPE );
    ifNotEqual( err.etype, 'ETYPE' );
end

-- valid
for val = -128, 127 do
    _, err = isa( val );
    ifNotNil( err );
    ifNotEqual( _, val );
end
