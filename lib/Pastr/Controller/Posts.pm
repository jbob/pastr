package Pastr::Controller::Posts;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    $self->render();
}


sub create {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});

    $collection->insert($self->req->params->to_hash => sub {
        my ($collection, $err, $oid) = @_;

        return $self->reply->exception($err) if $err;

        $self->redirect_to("/$oid");
    });
}

sub show {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $format = $stash->{format};
    my $collection = $self->mango->db->collection($config->{collection});
    my $oid = Mango::BSON::ObjectID->new($stash->{oid});

    $collection->find_one($oid => sub {
        my ($collection, $err, $doc) = @_;

        return $self->reply->exception($err) if $err;
        if($format eq 'json') {
            # Don't leak secret delete code!
            delete $doc->{delete};
            $self->render(json => $doc);
        } elsif($format eq 'raw') {
            $self->render(text => $doc->{post}, format => 'txt');
        } else {
            $self->render(doc => $doc);
        }
    });
    $self->render_later();
}


sub delete {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});
    my $oid = Mango::BSON::ObjectID->new($stash->{oid});
    my $delete = $stash->{delete} || '';

    $collection->find_one($oid => sub {
        my ($collection, $err, $doc) = @_;

        return $self->reply->exception($err) if $err;

        if($doc->{delete} and $doc->{delete} eq $delete) {
            $collection->remove($oid => sub {
                my ($collection, $err, $doc) = @_;

                return $self->reply->exception($err) if $err;

                $self->flash(msg => 'Post deleted');
                $self->redirect_to('/');
            });
        }
    });
    $self->render_later();
}


1;
