requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'IO::K8s';
requires 'Moo';
requires 'MooX::Cmd';
requires 'MooX::Options';
requires 'Type::Tiny';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';
requires 'YAML::XS';
requires 'Path::Tiny';
requires 'Module::Runtime';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'KubeBuilder', '>= 0.02';
}
