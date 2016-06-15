package app;

use Dancer ':syntax';
use Dancer::Plugin::Database;

use Framestrip::Model;

our $VERSION = '0.1';

prefix '/data' => sub {
  get '/asset/:id' => sub {
    my $model = Framestrip::Model->new( dbh => database );
    return $model->asset( param('id') );
  };
};

get '/' => sub {
  template 'index';
};

true;
