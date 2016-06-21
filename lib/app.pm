package app;

use Dancer ':syntax';
use Dancer::Plugin::Database;

use Framestrip::Model;
use JSON ();

our $VERSION = '0.1';

sub model() {
  Framestrip::Model->new( dbh => database );
}

prefix '/data' => sub {
  get '/list/:start/:size' => sub {
    my $model = Framestrip::Model->new( dbh => database );
    return $model->list( param('start'), param('size') );
  };

  get '/asset/:id' => sub {
    my $model = Framestrip::Model->new( dbh => database );
    return $model->asset( param('id') );
  };
};

get qr{\/p\/(\d+)} => sub {
  my ($id) = splat;
  my $prog = model->asset($id);
  unless ($prog) {
    status 404;
    return halt;
  }
  my $stash = {
    programme => $prog,
    title     => $prog->{programme_name},
  };
  $stash->{stash} = JSON->new->encode($stash);
  $stash->{scripts} = ['framestore', 'framestrip', 'edit'];
  template 'programme', $stash;
};

get '/' => sub {
  template 'index', { title => "Tones & Bars" };
};

true;
