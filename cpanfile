requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'Moo';
requires 'Type::Tiny';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';
requires 'Module::Runtime';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'Moose';
  requires 'Template';
  requires 'Swagger::Schema';
  requires 'namespace::autoclean';
  requires 'Path::Class';
}
