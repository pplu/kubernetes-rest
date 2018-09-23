requires 'HTTP::Tiny';
requires 'Moo';
requires 'Type::Tiny';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';
requires 'Module::Runtime';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
