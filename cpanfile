requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'Moo';
requires 'Type::Tiny';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';
requires 'Module::Runtime';
requires 'IO::K8s';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'KubeBuilder', '>= 0.02';
}
