local lschema = require('lschema');
local myschema = ifNil( lschema.new('myschema') );
local pattern = myschema.pattern;

-- indentity pattern: ^[_a-zA-Z][_a-zA-Z0-9]*$
-- invalid ident
ifTrue(isolate(function()
    pattern '' {}
end));
ifTrue(isolate(function()
    pattern 'my-pattern' {}
end));
ifTrue(isolate(function()
    pattern 'my.pattern' {}
end));

-- test builtin email pattern
ifNotTrue(isolate(function()
    pattern 'email' {
        require('lschema.ddl.pattern').email
    }
end));


-- verify behavior
ifNil( pattern.email );
-- valid email
for _, email in ipairs({
    "niceandsimple@example.com",
    "very.common@example.com",
    "a.little.lengthy.but.fine@dept.example.com",
    "disposable.style.email.with+symbol@example.com",
    "other.email-with-dash@example.com",
    "l3tt3rsAndNumb3rs@domain.com",
    "has-dash@domain.com",
    "uncommonTLD@domain.museum",
    "uncommonTLD@domain.travel",
    "uncommonTLD@domain.mobi",
    "countryCodeTLD@domain.uk",
    "countryCodeTLD@domain.rw",
    "lettersInDomain@911.com",
    "underscore_inLocal@domain.net",
    "subdomain@sub.domain.com",
    "local@dash-inDomain.com",
    "dot.inLocal@foo.com",
    "a@singleLetterLocal.org",
    "singleLetterDomain@x.org",
    "foor@bar.newTLD",
    '"abcdefghixyz"@example.com',
    "foor@[127.0.0.1]",
    "foor@[172.31.255.255]",
    "foor@[255.31.197.255]",
    "with+plus@example.com"
}) do
    ifNil( pattern.email:match( email ) );
end

-- invalid email
for _, email in ipairs({
    "@missingLocal.org",
    "someone-else@127.0.0.1.26",
    "non-bracket-ip-addr@127.0.0.1.26",
    "missingdomain@.com",
    "missingatSign.net",
    "missingDot@com",
    "two@@signs.com",
    "colonButNoPort@127.0.0.1:",
    "",
    'abc"defghi"xyz@example.com',
    ".localStartsWithDot@domain.com",
    "localEndsWithDot.@domain.com",
    "two..consecutiveDots@domain.com",
    "domainStartsWithDash@-domain.com",
    "domainEndsWithDash@domain-.com",
    "mike!@gmail.com",
    "missingTLD@domain.",
    "! #$%(),/;<>[]`|@invalidCharsInLocal.org",
    "numbersInTLD@domain.c0m",
    "invalidCharsInDomain@! #$%(),/;<>_[]`|.org",
    "local@SecondLevelDomainNamesAreInvalidIfTheyAreLongerThan64Charactersss.org",
    "hasApostrophe.o'leary@domain.org",
    "&*=?^+{}'~@validCharsInLocal.net",
}) do
    ifNotNil( pattern.email:match( email ) );
end

