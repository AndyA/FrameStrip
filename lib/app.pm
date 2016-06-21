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
  my ($id)  = splat;
  my $model = model;
  my $prog  = $model->asset($id);
  unless ($prog) {
    status 404;
    return halt;
  }
  my $stash = {
    programme => $prog,
    stats     => $model->stats,
    title     => $prog->{programme_name},
  };
  $stash->{stash} = JSON->new->encode($stash);
  $stash->{scripts} = ['framestore', 'framestrip', 'edit'];
  template 'programme', $stash;
};

sub go_next {
  my $model = model;
  my $next  = $model->random;
  my $stats = $model->stats;
  if ( $stats->{pending} == 0 ) {
    template 'all-done', { title => 'All Done', stats => $stats };
  }
  elsif ( !defined $next ) {
    template 'please-wait', { title => 'Please Wait', stats => $stats };
  }
  else {
    redirect 'https://framestrip.hexten.net/p/' . $next;
  }
}

post '/update' => sub {
  my $model = model;
  $model->update( param('redux_reference'), param('in'), param('out') );
  go_next();
};

post '/lock' => sub {
  my $model = model;
  $model->lock( param('redux_reference'), request->remote_address );
  return $model->stats;
};

get '/' => sub {
  go_next();
};

true;
