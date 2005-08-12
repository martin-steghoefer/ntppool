package NTPPool::Server;
use strict;
use base qw(NTPPool::DBI);
use NTPPool::Server::Score;
use NTPPool::Zone;

__PACKAGE__->set_up_table('servers');
__PACKAGE__->has_a('admin' => 'NTPPool::Admin');
__PACKAGE__->has_many('log_scores' => 'NTPPool::Server::LogScore');
__PACKAGE__->has_many('locations' => 'NTPPool::Location');
__PACKAGE__->might_have('_score'  => 'NTPPool::Server::Score');

sub zones {
  my $self = shift;
  sort { $a->name cmp $b->name } map { $_->zone } $self->locations;
}

sub score {
  my $self = shift;
  my ($score) = $self->_score;
  if (@_) {
      $score ||= NTPPool::Server::Score->create({ server => $self });
      $score->score(shift @_);
      $score->update;
  }
  $score = $score ? $score->score : 0;
  sprintf "%0.1f", $score;
}

sub history {
  my ($self, $count) = @_;

  $count ||= 50;

  my $pager = NTPPool::Server::LogScore->pager;
  $pager->page(1);
  $pager->per_page($count);
  $pager->order_by('ts desc');
  $pager->search_where({ server => $self->id });

}

sub find_server {
  my ($class, $arg) = @_;
  my ($server) = $class->search(ip => $arg);
  ($server)    = $class->search(hostname => $arg) unless $server;
  $server;
}

1;