package pf::dal::tenant;

=head1 NAME

pf::dal::tenant - pf::dal module to override for the table tenant

=cut

=head1 DESCRIPTION

pf::dal::tenant

pf::dal implementation for the table tenant

=cut

use strict;
use warnings;

use base qw(pf::dal::_tenant);
use pf::dal::person;
use pf::error qw(is_error);
use pf::ConfigStore::Radiusd::EAPProfile;
use pf::ConfigStore::Realm;
use pf::config::tenant;

sub after_create_hook {
    my ($self) = @_;
    my $status = pf::dal::person->create({
        pid => "default",
        notes => "Default User for tenant $self->{name}",
        tenant_id => $self->{id},
        -no_auto_tenant_id => 1,
    });
    if (is_error($status)) {
        $self->logger->error("Unable to create default user for the tenant");
    }
    # Create a eap profile
    my $cs = pf::ConfigStore::Radiusd::EAPProfile->new();
    my $default = pf::ConfigStore::Radiusd::EAPProfile->new->read("default");
    $default->{peap_virtual_server} = "packetfence-tunnel-".$self->{name};
    $default->{ttls_virtual_server} = "packetfence-tunnel-".$self->{name};
    $cs->update_or_create("default-".$self->{name}, $default);
    $cs->commit();

    # Create each realm
    $cs = pf::ConfigStore::Realm->new();
    pf::config::tenant::set_tenant(1);
    foreach my $realm (qw( DEFAULT LOCAL NULL)) {
        $default = pf::ConfigStore::Realm->new->read($realm);
        pf::config::tenant::set_tenant($self->{id});
        $default->{eap} = "default-".$self->{name};
        $cs->update_or_create($realm, $default);
        $cs->commit();
        pf::config::tenant::set_tenant(1);
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2021 Inverse inc.

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
