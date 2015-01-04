local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa = myschema.isa('int32');
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
    -- int32 min - 1, int32 max + 1
        -2147483649, 2147483648,
    -- uint32
        4294967295
}) do
    _, err = isa( val );
    ifNil( err );
    ifNotEqual( err.errno, errno.ETYPE );
    ifNotEqual( err.etype, 'ETYPE' );
end

-- valid
for val = -2147483648, 2147483647 do
    _, err = isa( val );
    ifNotNil( err );
    ifNotEqual( _, val );
end
