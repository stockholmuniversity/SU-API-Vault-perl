package SU::API::Vault;

use strict;
use warnings;

use HTTP::Request;
use JSON;
use LWP::UserAgent;

sub new {
    my $class = shift;
    my $self = {
        url => shift,
        role_id => shift,
        secret_id => shift,
    };


    $self->{ua} = LWP::UserAgent->new;
    $self->{login_status} = "not logged in";
    $self->{exp_time} = 0;
    $self->{client_token} = undef;

    bless $self, $class;
    return $self;
};
