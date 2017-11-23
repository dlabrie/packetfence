package pf::provisioner::jamf;

=head1 NAME

pf::provisioner::jamf

=cut

=head1 DESCRIPTION

Allows to validate installation of management client using the JAMF API

=cut

use strict;
use warnings;

use Moo;
extends 'pf::provisioner';

use pf::error qw(is_error is_success);
use pf::constants;
use pf::log;

use JSON::MaybeXS qw(decode_json);
use LWP::UserAgent;
use HTTP::Request::Common;


=head1 Atrributes

=head2 api_username

Username to connect to the API

=cut

has api_username => ( is => 'rw', required => $TRUE );

=head2 api_password

Password to connect to the API

=cut

has api_password => ( is => 'rw', required => $TRUE );

=head2 host

Host of the JAMF web API

=cut

has host => ( is => 'rw', required => $TRUE );

=head2 port

Port to connect to the JAMF web API

=cut

has port => ( is => 'rw', default => sub { $HTTPS_PORT } );

=head2 protocol

Protocol to connect to the JAMF web API

=cut

has protocol => ( is => 'rw', default => sub { $HTTPS } );

=head2 device_type_detection

Option to automacally detects device type

=cut

has device_type_detection => ( is => 'rw', default => sub { $FALSE } );

=head2 query_computers

Option to query the "computers" inventory

=cut

has query_computers => ( is => 'rw', default => sub { $TRUE } );

=head2 query_mobiledevices

Option to query the "mobile devices" inventory

=cut

has query_mobiledevices => ( is => 'rw', default => sub { $TRUE } );


=head1 Methods

=head2 authorize

Check whether the device exists or not in the JAMF API

=cut

sub authorize {
    my ( $self, $mac ) = @_;
    my $logger = get_logger;

    my ( $status, $device_type, $device_information ) = $self->get_device_information($mac);

    unless ( is_sucess($status) ) {
        $logger->info("Unable to complete a JAMF query for MAC address '$mac'");
        return $FALSE;
    }

    my $result = $self->parse_device_information($device_type, $device_information);
}


=head2 get_device_information

=cut

sub get_device_information {
    my ( $self, $mac ) = @_;
    my $logger = get_logger;

    # JAMF API separates realms for "computers" and "mobiledevices" assets. Therefore, a different API call is required whether it is a computer or a mobile device.
    # To ease the configuration and the flow, different implementation options are offered:
    # - Automatically detect device type using Fingerbank
    # - Query both JAMF realms subsequently (query "computers" and if there is no answer, query "mobiledevices")
    # - Query only "computers" JAMF realm
    # - Query only "mobiledevices" JAMF realm
    my ( $status, $device_type, $device_information ) = 0;    # Initiating "status" to 0 not to trigger a success clause
    if ( is_enabled($self->device_type_detection) ) {
        $device_type = $self->detect_device_type($mac);
        ( $status, $device_information ) = $self->execute_request($mac, $device_type) if defined $device_type;
    }
    unless ( is_success($status) ) {
        if ( is_enabled($self->query_computers) ) {
            $device_type = 'computers';
            ( $status, $device_information ) = $self->execute_request($mac, $device_type);
        }
        if ( (is_enabled($self->query_mobiledevices)) && (!is_success($status)) ) {
            $device_type = 'mobiledevices';
            ( $status, $device_information ) = $self->execute_request($mac, $device_type);
        }
    }

    return ($status, $device_type, $device_information);
}


=head2 detect_device_type

Detects whether it is an Apple computer or an Apple Mobile device.

NOT YET IMPLEMENTED

=cut

sub detect_device_type {
    my ( $self, $mac ) = @_;
    my $logger = get_logger;
}


=head2 execute_request

Execute a request to the JAMF API

=cut

sub execute_request {
    my ( $self, $mac, $realm ) = @_;
    my $logger = get_logger;

    my $ua = LWP::UserAgent->new();
    my $request = $self->build_request($mac, $realm);
    $request->authorization_basic($self->api_username, $self->api_password);
    $request->header( 'content-type' => 'application/json' );
    $request->header( 'Accept'       => 'application/json' );

    my $response = $ua->request($request);

    if ( $response->is_success ) {
        $logger->info("Successfully queried JAMF API for '$realm' with MAC address '$mac'");
    } else {
        $logger->info("Failure while querying JAMF API for '$realm' with MAC address '$mac'. Return code: '$response->status_line'");
    }

    return ( $response->code, $response->decoded_content );
}


=head2 build_request

Build the request to be executed base of the MAC address and the JAMF realm

=cut

sub build_request {
    my ( $self, $mac, $realm ) = @_;
    my $logger = get_logger;

    my $method = 'GET';
    my $escaped_mac_address = uri_escape($mac);
    my $uri = $self->protocol . "://" . $self->host . "/JSSResource/" . $realm . "/macaddress/" . $escaped_mac_address;

    my $request = "$method '$uri'";
    $logger->debug("Request to query: '$request'");

    return $request;
}


=head2 parse_device_information

=cut

sub parse_device_information {
    my ( $self, $device_type, $device_information ) = @_;
    my $logger = get_logger;

    my $json = decode_json($device_information);

    if ( $device_type eq 'computers' ) {
        return $json->{'computer'}{'general'}{'remote_management'}{'managed'};
    }
    elsif ( $device_type eq 'mobiledevices' ) {
        return $json->{'mobile_device'}{'general'}{'managed'};
    }
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2017 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
