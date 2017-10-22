requires "Carp" => "0";
requires "Data::Dumper" => "0";
requires "Module::Runtime" => "0";
requires "Scalar::Util" => "0";
requires "Sub::Exporter" => "0";
requires "constant" => "0";
requires "parent" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.89";
  requires "Test::Pod" => "0";
  requires "Test::Requires" => "0";
  requires "Test::Warn" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
