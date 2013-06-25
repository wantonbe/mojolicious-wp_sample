#!/usr/bin/env perl

use Mojolicious::Lite;

use DBI;
use FormValidator::Lite;
use File::Spec;

FormValidator::Lite->load_constraints(qw/Email Japanese/);

app->log->handle(\*STDERR);

plugin 'Config' => {
    file => File::Spec->rel2abs( join("/", (
      "config",
      join(".", "environment", ($ENV{'MOJO_MODE'} || "development"), 'pl'),
    )))
  };
my $config = app->config;

plugin 'xslate_renderer' => {
    template_options => {
      cache => 0,
      cache_dir => File::Spec->rel2abs("./tmp"),
      die_handler => sub {
        Text::Xslate::mark_raw('<pre class="alert alert-error">');
        '[[', @_ , ']]',
        Text::Xslate::mark_raw('</pre>');
      },
      path => File::Spec->rel2abs("./views"),
    },
  };
app->renderer->default_handler('tx') ;

app->attr( dbh => sub { DBI->connect( @{$config->{db}} ) } );

sub check_error {
  my $c = shift;

  my $v = FormValidator::Lite->new($c->req);
  $v->set_message_data({
      message => {
        },
      param => {
          company_name => "会社名",
          user_name => "氏名",
          email => "メールアドレス",
        },
      function => {
          not_null => "[_1] を入力してください。",
          length => "[_1] が長過ぎます。",
          email_loose => "[_1] を正しいメールアドレスの形式で入力してください。",
        },
  });
  my $res = $v->check(
      company_name => [ 'NOT_NULL', [ 'LENGTH', 0, 100 ] ],
      user_name => [ 'NOT_NULL', [ 'LENGTH', 1, 32 ] ],
      email => [ 'NOT_NULL', [ 'LENGTH', 3, 256 ], 'EMAIL_LOOSE' ],
    );

  return $res;
}

app->hook( before_routes => sub {
  my $c = shift;
  for my $field (keys %{$c->req->params->to_hash}) {
    $c->stash->{$field} = $c->req->params->to_hash->{$field};
  }
} );

get '/' => sub {
  my $self = shift;
} => 'index';

get '/customer/register' => sub {
  my $self = shift;
} => 'customer/register';

post '/customer/confirm' => sub {
  my $self = shift;
  my $e = check_error($self);

  if ($e->has_error) {
    $self->stash( error => $e );
    $self->render("customer/register");
    return;
  }
} => 'customer/confirm';

post '/customer/confirmed' => sub {
  my $self = shift;
  my $e = check_error($self);

  if ($e->has_error) {
    return $self->rendered(403);
  }

  my $dbh = $self->app->dbh;
  eval {
    $dbh->begin_work;

    my $sth1 = $dbh->prepare(<<"...");
INSERT users
  (user_name, email)
  VALUES(?, ?)
...
    $sth1->execute($self->stash('user_name'), $self->stash('email'));

    my $sth2 = $dbh->prepare(<<"...");
INSERT customers
  (customer_id, company_name)
  VALUES(?, ?)
...
    $sth2->execute($dbh->{'last_insertid'}, $self->stash('company_name'));

    $dbh->commit;
  };
  if (my $e = $@) {
    $dbh->rollback;
    return $self->render_exception($e);
  }
  $dbh->disconnect;

} => 'customer/registered';

any '/customer/list/:page' => { page => 1 } => sub {
  my $self = shift;

  my $dbh = $self->app->dbh;

  my $limit = 5;
  my $offset = $limit * ($self->stash('page') - 1 );
  eval {
    my $sth = $dbh->prepare(<<"...");
SELECT
  user_id,
  company_name,
  user_name,
  email
FROM
  users
JOIN customers
  ON user_id = customer_id
ORDER BY
  customer_id
LIMIT ?, ?
...
    $sth->execute($offset, $limit);
    my $rs = $sth->fetchall_arrayref(+{});

    $self->stash( results => $rs );
  };
  if (my $e = $@) {
    return $self->render_exception($e);
  }
  $dbh->disconnect;
} => 'customer/list';

app->start;

# vi:set ts=2 sw=2 sts=2 et:
