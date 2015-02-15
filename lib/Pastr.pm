package Pastr;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON::ObjectID;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');

  $self->secrets($config->{secret});
  $self->helper(mango => sub {
    state $mango = Mango->new($config->{mongouri})
  });
  $self->types->type(json => 'application/json; charset=utf-8');

  # Router
  my $r = $self->routes;

  $r->get('/')->to('posts#index');
  $r->any('/create')->to('posts#create');
  $r->get('/:oid')->to('posts#show');
  $r->any('/delete/:oid/:delete')->to('posts#delete');

}

1;
