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
    return model->list( param('start'), param('size') );
  };

  get '/asset/:id' => sub {
    return model->asset( param('id') );
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

post '/update' => sub {
  my $model = model;
  $model->update( param('redux_reference'), param('in'), param('out') );
  my $next = $model->random;
  redirect '/p/' . $next;
};

post '/lock' => sub {
  model->lock( param('redux_reference'), request->remote_address );
  return {};
};

get '/' => sub {
  my $list = model->list();
  template 'index', { title => "Tones & Bars", stash => $list };
};

true;
