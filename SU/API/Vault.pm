package SU::API::Vault;

use strict;
use warnings;

use HTTP::Request;
use IO::File;
use JSON;
use LWP::UserAgent;
use open IO => ':raw';

sub new
{
    my $class = shift;
    my $self = {
                url       => shift,
                role_id   => shift,
                secret_id => shift,
               };

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->default_header('Accept' => 'application/json');
    $self->{login_status}  = "not logged in";
    $self->{logged_in}     = 0;
    $self->{exp_time}      = time;
    $self->{relative_path} = "/v1/secret/vaulttoolsecrets";
    $self->{client_token}  = undef;
    $self->{last_secret}   = undef;

    bless $self, $class;
    return $self;
}

sub login
{
    my ($self)  = @_;
    my $time    = time;
    my $timeout = $time + 300;

    if ($timeout > ($self->{exp_time}))
    {
        my $request_url = "$self->{url}/v1/auth/approle/login";
        my %post_data =
          ("role_id" => $self->{role_id}, "secret_id" => $self->{secret_id});
        my $req = HTTP::Request->new(POST => $request_url);
        my $data = encode_json(\%post_data);
        $req->content($data);
        $self->{res} = $self->{ua}->request($req);
        if (!$self->{res}->is_success)
        {
            return undef;
        }
        else
        {
            $self->{login_status} = "logged in";
            $self->{logged_in}    = 1;
            my $perl_data = decode_json($self->{res}->{_content});
            $self->{exp_time} = $time + $perl_data->{auth}->{lease_duration};
            $self->{client_token} = $perl_data->{auth}->{client_token};
        }
    }
    return $self->{login_status};

}

sub logout
{
    my ($self)  = @_;
    my $request_url = "$self->{url}/v1/auth/token/revoke-self";
    my $req = HTTP::Request->new(POST => $request_url);
    $req->header('X-Vault-Token' => $self->{client_token});
    $self->{res} = $self->{ua}->request($req);
    if (!$self->{res}->is_success)
    {
        return undef;
    }
    else
    {
        $self->{login_status}  = "not logged in";
        $self->{logged_in}     = 0;
        $self->{exp_time}      = time;
        $self->{client_token}  = undef;
        $self->{last_secret}   = undef;
    }
    return $self->{login_status};

}

sub get_secret
{
    my $time    = time;
    my $timeout = $time + 30;
    my ($self, $path) = @_;
    if (   !$self->{last_secret}
        or ($self->{last_secret}->{path} ne $path)
        or ($self->{last_secret}->{access_time} < ($time - 300)))
    {
        if (!$self->{logged_in} or ($timeout > $self->{exp_time}))
        {
            $self->login;
        }
        my $request_url = "$self->{url}$self->{relative_path}/$path";
        my $req = HTTP::Request->new(GET => $request_url);
        $req->header('X-Vault-Token' => $self->{client_token});
        $self->{res} = $self->{ua}->request($req);
        if (!$self->{res}->is_success)
        {
            return undef;
        }
        else
        {
            my $perl_data = decode_json($self->{res}->{_content})
              or die "Could not convert json: $!";
            $self->{last_secret}->{path}        = $path;
            $self->{last_secret}->{access_time} = $time;
            $self->{last_secret}->{data}        = $perl_data->{data};
            my @keys = keys %{$self->{last_secret}->{data}};
            $self->{last_secret}->{data_keys} = \@keys;
            return $self->{last_secret};

        }
    }

}

sub print_bindata
{
    my ($self, $filename) = @_;
    if (!$self->{last_secret} or !$filename)
    {
        return undef;
    }
    my $fh = IO::File->new();
    if ($fh->open("> $filename"))
    {
        print $fh pack('c*', @{$self->{last_secret}->{data}->{binaryData}});
        $fh->close;
    }

}

1;
