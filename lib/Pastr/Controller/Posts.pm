package Pastr::Controller::Posts;
use Mojo::Base 'Mojolicious::Controller';

sub create {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});
    my $validation = $self->validation;

    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $validation->csrf_protect->has_error('csrf_token');

    my $title = $self->req->param('title') || 'Untitled';
    my $post = $self->req->param('post');
    my $delete = $self->req->param('delete');
    my $doc = {
        title => $title,
        post => $post,
        delete => $delete
    };

    $collection->insert($doc => sub {
        my ($collection, $err, $oid) = @_;

        return $self->reply->exception($err) if $err;

        $self->redirect_to('showoid', oid => $oid);
    });
    $self->render_later;
}

sub show {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $format = $stash->{format} || '';
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
            $self->render(doc => $doc)
        }
    });
    $self->render_later;
}


sub delete {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});
    my $oid = $self->req->param('oid') || $stash->{oid};
    my $delete = $self->req->param('delete') || $stash->{delete};

    if(not $oid or not $delete) {
        return $self->render;
    }

    eval {
        $oid = Mango::BSON::ObjectID->new($oid);
    };
    if($@) {
        $self->flash(msg => 'Invalid ID specified', type => 'danger');
        $self->redirect_to('delete');
        return;
    }

    $collection->find_one($oid => sub {
        my ($collection, $err, $doc) = @_;

        return $self->reply->exception($err) if $err;

        if(not $doc) {
            $self->flash(msg => 'Post not found', type => 'warning');
            $self->redirect_to('delete');
        }

        if($doc->{delete} and $doc->{delete} eq $delete) {
            $collection->remove($oid => sub {
                my ($collection, $err, $doc) = @_;

                return $self->reply->exception($err) if $err;

                $self->flash(msg => 'Post deleted', type => 'success');
                $self->redirect_to('index');
            });
        } else {
            $self->flash(msg => 'Wrong delete code', type => 'warning');
            $self->redirect_to('delete');
        }
    });
    $self->render_later;
}

sub search {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});
    my $search = $self->req->param('q') || $stash->{q};

    if(not $search) {
        return;
    }

    $collection->find({'$or' => [{title => qr/$search/}, {post => qr/$search/}]})->sort({_id => -1})->all(sub {
        my ($collection, $err, $docs) = @_;

        return $self->reply->exception($err) if $err;

        $self->render(docs => $docs);
    });
    $self->render_later;
}

sub latest {
    my $self = shift;
    my $stash = $self->stash;
    my $config = $stash->{config};
    my $collection = $self->mango->db->collection($config->{collection});
    my $search = $self->req->param('q') || $stash->{q};

    $collection->find()->sort({_id => -1})->limit(20)->all(sub {
        my ($collection, $err, $docs) = @_;

        return $self->reply->exception($err) if $err;

        $self->render(docs => $docs);
    });
    $self->render_later;
}


1;
