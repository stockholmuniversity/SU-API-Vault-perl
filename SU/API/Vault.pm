package SU::API::Box;

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

    bless $self, $class;
    return $self;
};
