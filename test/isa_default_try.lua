local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa, err, _;
local NOSUP_MINMAX = {
    ['boolean'] = true,
    ['table'] = true,
    ['enum'] = true,
    ['struct'] = true
};

myschema.pattern 'mypattern' {
    '^str$'
};

myschema.enum 'myenum' {
    'name1',
    'name2'
};

myschema.struct 'mystruct' {
    field = myschema.isa('string')
};


local function createISA( typ )
    local isa = myschema.isa( typ );
    
    if typ:find('^enum') then
        isa:of(myschema.enum.myenum);
    elseif typ:find('^struct') then
        isa:of(myschema.struct.mystruct);
    end
    
    return isa;
end


local function withMinConstraint( typ, min, val )
    createISA( typ ):min( min ):default( val );
end


local function withMaxConstraint( typ, max, val )
    createISA( typ ):max( max ):default( val );
end


local function withPatternConstraint( typ, val )
    createISA( typ ):pattern( myschema.pattern.mypattern ):default( val );
end


local function withLenConstraint( typ, min, max, val )
    createISA( typ ):len( min, max):default( val );
end


local function withNoDupConstraint( typ, val )
    createISA( typ ):noDup():default( val );
end


-- isa type
for typ, val in pairs({
    ['string'] = 'str',
    ['number'] = 1,
    ['int8'] = 126,
    ['int16'] = 32766,
    ['int32'] = 2147483646,
    ['uint8'] = 254,
    ['uint16'] = 65534,
    ['uint32'] = 4294967294,
    ['boolean'] = true,
    ['table'] = { a = 'b', c = 'd' },
    ['enum'] = 'name1',
    ['struct'] = { field = 'str' }
}) do
    -- invalid definition
    -- no argument
    isa = createISA( typ );
    ifTrue(isolate(function()
        isa:default();
    end));
    
    -- min/max constraint violation
    if not NOSUP_MINMAX[typ] then
        local len;
        
        if typ == 'string' then
            len = #val;
            -- pattern constraint violation
            ifTrue(isolate(function()
                withPatternConstraint( typ, val .. val );
            end));
        else
            len = val;
        end
        
        -- min
        ifTrue(isolate(function()
            withMinConstraint( typ, len + 1, val );
        end));
        -- max
        ifTrue(isolate(function()
            withMaxConstraint( typ, len - 1, val );
        end));
    end

    -- valid defintion
    isa = createISA( typ );
    ifNotTrue(isolate(function()
        isa:default( val );
        isa:makeCheck();
    end));
    -- valid validation
    _, err = isa();
    ifNotNil( err );
    ifNotEqual( inspect(_), inspect(val) );
    
    -- array
    -- does not support array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' );
        end));
    else
        -- invalid definition
        -- no argument
        isa = createISA( typ .. '[]' );
        ifTrue(isolate(function()
            isa:default();
        end));
        
        -- length constraint violation
        -- min len
        ifTrue(isolate(function()
            withLenConstraint( typ .. '[]', 3, 3, { val, val } );
        end));
        -- max len
        ifTrue(isolate(function()
            withLenConstraint( typ .. '[]', 1, 1, { val, val } );
        end));
        
        -- noDup constraint violation
        ifTrue(isolate(function()
            withNoDupConstraint( typ .. '[]', { val, val } );
        end));
        
        if not NOSUP_MINMAX[typ] then
            local len;
            
            -- pattern constraint
            if typ == 'string' then
                len = #val;
                ifTrue(isolate(function()
                    withPatternConstraint( typ, { val, val .. val } );
                end));
            else
                len = val;
            end
            
            -- min constraint violation
            ifTrue(isolate(function()
                withMinConstraint( typ .. '[]', len + 1, { val, val } );
            end));
            -- max constraint violation
            ifTrue(isolate(function()
                withMaxConstraint( typ .. '[]', len - 1, { val, val } );
            end));
        end
        
        -- valid defintion
        isa = createISA( typ .. '[]' );
        val = { val, val };
        ifNotTrue(isolate(function()
            isa:default( val );
            isa:makeCheck();
        end));
        
        -- valid validation
        _, err = isa();
        ifNotNil( err );
        ifNotEqual( inspect( _ ), inspect( val ) );
    end
end
