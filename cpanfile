requires 'HTTP::Tiny';
requires 'Moo';
requires 'Type::Tiny';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
