requires 'HTTP::Tiny';
requires 'Moo';
requires 'Type::Tiny';
requires 'Throwable::Error';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
