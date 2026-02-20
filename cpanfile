requires 'LWP::UserAgent';
recommends 'LWP::ConsoleLogger';
recommends 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'IO::K8s', '1.000';
requires 'Moo';
requires 'MooX::Cmd';
requires 'MooX::Options';
requires 'Types::Standard';
requires 'JSON::MaybeXS';
requires 'YAML::XS';
requires 'Path::Tiny';
requires 'Module::Runtime';
requires 'namespace::clean';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
