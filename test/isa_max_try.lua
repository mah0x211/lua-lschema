local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local EXCEPTS = {
    ['boolean'] = true,
    ['table'] = true,
    ['enum'] = true,
    ['struct'] = true
};
local myschema = lschema.new('myschema');
local isa, err, len, _;

-- set enum
myschema.enum 'myenum' {
    'name1',
    'name2'
}

myschema.struct 'mystruct' {
    field = myschema.isa('string')
};

-- isa type
for typ, val in pairs({
    ['string'] = 'str',
    ['number'] = 1,
    ['unsigned'] = 1,
    ['int'] = 1,
    ['int8'] = 1,
    ['int16'] = 1,
    ['int32'] = 1,
    ['uint8'] = 1,
    ['uint16'] = 1,
    ['uint32'] = 1,
    ['boolean'] = true,
    ['table'] = {},
    ['enum'] = 'name1',
    ['struct'] = { field = 'str' }
}) do
    isa = myschema.isa( typ );
    if typ == 'enum' then
        isa:of( myschema.enum.myenum );
    elseif typ == 'struct' then
        isa:of( myschema.struct.mystruct );
    end
    
    -- does not support max constraint
    if EXCEPTS[typ] then
        -- attempt to access an undefined value
        ifTrue(isolate(function()
            local fn = isa.max;
        end));
    else
        -- invalid definition: no argument
        ifTrue(isolate(function()
            isa:max();
        end));
        
        -- valid defintion
        ifNotTrue(isolate(function()
            if typ == 'string' then
                len = #val;
            else
                len = val;
            end
            isa:max( len );
            -- should not redefine
            ifTrue(isolate(function()
                isa:max( len );
            end));
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa( val );
        ifNotNil( err );
        -- invalid validation
        if typ == 'string' then
            _, err = isa( val .. val );
        else
            _, err = isa( val + 1 );
        end
        ifNotEqual( err.errno, errno.EMAX );
        ifNotEqual( err.etype, 'EMAX' );
    end
    
    -- array
    -- does not support array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' );
        end));
    else
        isa = myschema.isa( typ .. '[]' );
        if typ == 'enum' then
            isa:of( myschema.enum.myenum );
        elseif typ == 'struct' then
            isa:of( myschema.struct.mystruct );
        end
    
        -- does not support max constraint
        if EXCEPTS[typ] then
            -- attempt to access an undefined value
            ifTrue(isolate(function()
                local fn = isa.max;
            end));
        else
            -- invalid definition: no argument
            ifTrue(isolate(function()
                isa:max();
            end));

            -- valid difinition
            ifNotTrue(isolate(function()
                if typ == 'string' then
                    len = #val;
                else
                    len = val;
                end
                isa:max( len );
                -- should not redefine
                ifTrue(isolate(function()
                    isa:max( len );
                end));
                isa:makeCheck();
            end));
            
            -- valid validation
            _, err = isa( {val} );
            ifNotNil( err );
            -- invalid validation
            if typ == 'string' then
                _, err = isa( {val .. val} );
            else
                _, err = isa( {val + 1} );
            end
            ifNotEqual( err[1].errno, errno.EMAX );
            ifNotEqual( err[1].etype, 'EMAX' );
        end
    end
end
