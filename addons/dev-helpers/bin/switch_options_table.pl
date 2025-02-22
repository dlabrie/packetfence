#!/usr/bin/perl

=head1 NAME

switch_options -

=head1 DESCRIPTION

switch_options

=cut

use strict;
use warnings;
use lib qw(/usr/local/pf/lib);
use lib qw(/usr/local/pf/lib_perl/lib/perl5);
use Pod::Select;
use Pod::Find qw(pod_where);
use Data::Dumper;
use pf::SwitchFactory;

#
# Extract and prepare the data
#
#
pf::SwitchFactory->preloadAllModules();
my @groups = pf::SwitchFactory::form_options();

my %dict_name_infos=();
my @list_name_infos=();
for my $g (@groups) {
    for my $switch_info (@{$g->{options}}) {
        my $string="";

        my $name = $switch_info->{value};
        my $module = "pf::Switch::${name}";
        $switch_info->{related} = getRelated($module);
        if (not $switch_info->{is_template}) {
            my $file = pod_where({-inc => 1}, $module);
            my $snmp = '';
            open(my $fh, ">", \$snmp);
            podselect({-sections=>["SNMP"], -output => $fh}, $file);
            if ($snmp ne '') {
                $switch_info->{"SNMP"}="true";
            }
            close($fh);
        }
        my $aSupports= $switch_info->{supports};
        my $supports = join( ',', @$aSupports);
        if ($supports =~ /VPN/) {
          $switch_info->{"vpn"}="true";
        } elsif ($supports =~ /Wired/ && $supports =~ /Wireless/){
          $switch_info->{"wired_wireless"}="true";
        } elsif ($supports =~ /Wireless/){
          $switch_info->{"wireless"}="true";
        } elsif ($supports =~ /Wired/ || $supports =~ /RadiusDynamicVlanAssignment/){
          $switch_info->{"wired"}="true";
        } else {
          print("$name \t$supports\n");
        }
        $switch_info->{"WiredMacAuth"}="true"                if ($supports =~ /WiredMacAuth/ && $supports !~ /-WiredMacAuth/) ;
        $switch_info->{"WiredDot1x"}="true"                  if ($supports =~ /WiredDot1x/ && $supports !~ /-WiredDot1x/) ;
        $switch_info->{"WirelessMacAuth"}="true"             if ($supports =~ /WirelessMacAuth/ && $supports !~ /-WirelessMacAuth/) ;
        $switch_info->{"WirelessDot1x"}="true"               if ($supports =~ /WirelessDot1x/ && $supports !~ /-WirelessDot1x/) ;
        $switch_info->{"RadiusDynamicVlanAssignment"}="true" if ($supports =~ /RadiusDynamicVlanAssignment/ && $supports !~ /-RadiusDynamicVlanAssignment/) ;
        $switch_info->{"ExternalPortal"}="true"              if ($supports =~ /ExternalPortal/ && $supports !~ /-ExternalPortal/) ;
        $switch_info->{"MABFloatingDevices"}="true"          if ($supports =~ /MABFloatingDevices/ && $supports !~ /-MABFloatingDevices/) ;
        $switch_info->{"WebFormRegistration"}="true"         if ($supports =~ /WebFormRegistration/ && $supports !~ /-WebFormRegistration/) ;
        $switch_info->{"AccessListBasedEnforcement"}="true"  if ($supports =~ /AccessListBasedEnforcement/ && $supports !~ /-AccessListBasedEnforcement/) ;
        $switch_info->{"RadiusVoip"}="true"                  if ($supports =~ /RadiusVoip/ && $supports !~ /-RadiusVoip/) ;
        $switch_info->{"FloatingDevice"}="true"              if ($supports =~ /FloatingDevice/ && $supports !~ /-FloatingDevice/) ;
        $switch_info->{"Cdp"}="true"                         if ($supports =~ /Cdp/ && $supports !~ /-Cdp/) ;
        $switch_info->{"Lldp"}="true"                        if ($supports =~ /Lldp/ && $supports !~ /-Lldp/) ;
        $switch_info->{"RoamingAccounting"}="true"           if ($supports =~ /RoamingAccounting/ && $supports !~ /-RoamingAccounting/) ;
        $switch_info->{"SaveConfig"}="true"                  if ($supports =~ /SaveConfig/ && $supports !~ /-SaveConfig/) ;
        $switch_info->{"RoleBasedEnforcement"}="true"        if ($supports =~ /RoleBasedEnforcement/ && $supports !~ /-RoleBasedEnforcement/) ;
        #$switch_info->{"SNMP"}="true"                        if ($supports =~ /SNMP/ && $supports !~ /-SNMP/) ;

        $dict_name_infos{$name}=$switch_info;
        push(@list_name_infos,$name);
    }
}

#
# Create the table
#
my @list_of_types=("SNMP", "WiredMacAuth", "WiredDot1x","WirelessMacAuth", "WirelessDot1x", "ExternalPortal", "RadiusDynamicVlanAssignment", "AccessListBasedEnforcement", "RoleBasedEnforcement", "RadiusVoip", "MABFloatingDevices", "FloatingDevice" );

my %list_of_types_trans=("SNMP"=>"SNMP",
                         "WiredMacAuth"=>"Wired MAC Auth",
                         "WiredDot1x"=>"Wired 802.1x",
                         "WirelessMacAuth"=>"Wireless MAC Auth",
                         "WirelessDot1x"=>"Wireless 802.1x",
                         "ExternalPortal"=>"Web Auth",
                         "RadiusDynamicVlanAssignment"=>"RADIUS Dynamic VLAN",
                         "AccessListBasedEnforcement"=>"RADIUS Dynamic ACL",
                         "RoleBasedEnforcement"=>"RADIUS Dynamic Role",
                         "RadiusVoip"=>"RADIUS VOIP",
                         "MABFloatingDevices"=>"MAB Floating Device",
                         "FloatingDevice"=>"Floating Device",
                         "WebFormRegistration"=>"Web Form",
                         "Cdp"=>"CDP",
                         "Lldp"=>"LLDP",
                         "RoamingAccounting"=>"Roaming Accounting",
                         "SaveConfig"=>"Save Config");

my @list_of_wlc=("Bluesocket", "Cambium","Cisco::WLC", "Cisco::WiSM", "Aruba::Controller_200", "Aruba::Instant_Access", "Aruba::WirelessController", "Meru", "Huawei", "Ubiquiti::Unifi", "HP::Controller_MSM710");

my $nl="\n";
my $t2='  ';
my $t4='    ';
my $tab=$t4.$t2.''.$nl;
$tab .= $t4.$t2.'<table id="switches" class="ui very basic sticky-column celled table">'.$nl;
$tab .= $t4.$t4.'<thead>'.$nl;
$tab .= $t4.$t4.$t2.'<tr>'.$nl;
$tab .= $t4.$t4.$t4.'<th>Name</th>'.$nl;
for my $type (@list_of_types) {
  $tab .= $t4.$t4.$t4.'<th class="rotate"><div><span>'.$list_of_types_trans{$type}.'</span></div></th>'.$nl;
}
$tab .= $t4.$t4.$t2.'</tr>'.$nl;
$tab .= $t4.$t4.'</thead>'.$nl;
$tab .= $t4.$t4.'<tbody>'.$nl;

foreach my $name (@list_name_infos) {
  my $tr=''.$t4.$t4.$t2.'<tr id="'.$name.'"  class="device ui center aligned">'.$nl;

  my $switch_info = $dict_name_infos{$name};

  my $td=$t4.$t4.$t4.'<td class="single line ui left aligned"><a name="'.$name.'"></a>'.$switch_info->{"label"}.'<br>';
  if ($switch_info->{"wireless"} || $switch_info->{"wired_wireless"}) {
    $td.=' <i class="wifi icon"></i>';
  }
  for my $tname (@list_of_wlc) {
    if ($name =~ /$tname/ ) {
      $td.=' <i class="arrows alternate icon"></i>';
    }
  }
  if ($switch_info->{"wired"} || $switch_info->{"wired_wireless"}) {
    $td.=' <i class="sitemap icon"></i>';
  }
  if ($switch_info->{"vpn"}) {
    $td.=' <i class="th icon"></i>';
  }
  if ($switch_info->{is_template}) {
    $td.=' <i class="copy icon"></i>';
  }
  $td.="".$nl.$t4.$t4.$t4."</td>".$nl;
  for my $type (@list_of_types) {
    if ($switch_info->{"${type}"}) {
      $td.=$t4.$t4.$t4.'<td class="'.$type.'"><i class="check icon"></i></td>'.$nl
    } else {
      $td.=$t4.$t4.$t4.'<td class="'.$type.'"></td>'.$nl
    }
  }
  $tr.=$td.$t4.$t4.$t2.'</tr>'.$nl;
  $tab.=$tr
}
$tab.=$t4.$t4.'</tbody>'.$nl;
$tab.=$t4.$t2.'</table>'.$nl;

#
# create the html page
#

my $html = '
<div class="ui bottom attached tab segment" data-tab="material">

  <div class="ui stackable centered padded grid">

    <div class="row">
      <div class="ten wide column">
        <h1 class="ui huge header">Supported network devices</h1>
        <p>The following tables detail the wired and wireless equipment supported by PacketFence. This list is the most up-to-date one. Note that generally all wired switches supporting MAC authentication and/or 802.1X with RADIUS can be supported by PacketFence.</p>
        <p>Bugs and limitations of the various modules can be found in the <a href="support.html#/documentation">Network Devices documentation</a>.</p>
        <p>
          <i class="wifi icon"></i> means wireless device.<br>
          <i class="arrows alternate icon"></i> means wireless controller.<br>
          <i class="sitemap icon"></i> means wired device.<br>
          <i class="th icon"></i> means VPN device.<br>
          <i class="copy icon"></i> means a template.
        </p>
        <h2 class="ui red header">Wired Support</h2>

        <p>PacketFence supports a huge number of wired switches.</p>

        <h2 class="ui red header">VPN Support</h2>

        <p>PacketFence supports some VPN.</p>

        <h2 class="ui red header">Wireless Support</h2>

        <p>There are two approaches to wireless networks. One where a controller handles the Access Points (AP) and one where AP act individually. PacketFence supports both approaches.</p>

        <h3 class="ui header">Wireless Controllers</h3>

        <p>When using a controller, it does not matter to PacketFence what individual AP are supported or not. As long as the AP itself is supported by your controller and that your controller is supported by PacketFence it will work fine.</p>

        <h3 class="ui header">Access Points</h3>

        <p>Some Access Points behave the same if they are attached to a controller or not. Because of that you might want to try a controller module if a controller from the same vendor is supported in the list above.</p>

        <p style="margin-bottom:20px;"></p>
      </div>
      <div class="sixteen wide column" n0style="margin-bottom:20px;">
        <h4 class="ui horizontal header red divider">Devices</h4>
        <form class="ui form">
          <div class="field">
            <div class="ui centered grid">
              <div class="five column center aligned row">
                <div class="column">
                  <div class="ui checked checkbox">
                    <input type="checkbox" name="public" id="wiredButton" checked> <label>Wired</label>
                  </div>
                </div>
                <div class="column">
                  <div class="ui checked checkbox">
                    <input type="checkbox" name="public" id="apButton" checked> <label>Access point</label>
                  </div>
                </div>
                <div class="column">
                  <div class="ui checked checkbox">
                    <input type="checkbox" name="public" id="controllersButton" checked> <label>Controllers</label>
                  </div>
                </div>
                <div class="column">
                  <div class="ui checked checkbox">
                    <input type="checkbox" name="public" id="vpnButton" checked> <label>VPN</label>
                  </div>
                </div>
                <div class="column">
                  <div class="ui checked checkbox">
                    <input type="checkbox" name="public" id="templateButton" checked> <label>Templates</label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="field">
            <input type="text" id="switches-filter-input" placeholder="Search for device model">
          </div>
          <button class="ui button" id="clearButton">
            Reset
          </button>
        </form>

        <div class="ui container h-scroll">
';

$html .= $tab;

$html .= '
        </div>
        <div id="noresult" class="ui segment">
  <div class="ui center aligned">
    <i class="frown icon"></i> No device match your filter.
  </div>
</div>
      </div>
    </div>
    <script>
    // Script to search names with filters or not
    window.onload = () => {
      var ids= {
        "vpnButton": "th",
        "templateButton": "copy",
        "wiredButton": "sitemap",
        "controllersButton": "arrows",
        "apButton": "wifi"
      };

      function getCurrentFilters(){
        var filters = "";
        $.each(ids, function(k, v) {
          if ($(`#${k}:checked`).length>0) {
            filters += v+",";
          }
        });
        return filters;
      }

      function inSearch(device,txt) {
        var name = $(device).find("a").attr("name");
        if (txt === "" || name.toLowerCase().includes(txt.toLowerCase())) {
          return true;
        } else {
         return false;
        }
      };

      function deviceType(device,type) {
        var name = device.find("i");
        var boo =  false;
        $(name).each(function() {
          var classes = $(this).attr("class").toLowerCase().split(" ");
          for (var i = 0; i < classes.length; i++) {
            if (type.toLowerCase().includes(classes[i])) {
              boo = true;
            }
          }
        });
        return boo;
      };

      function setShowHide(){
        var filters = getCurrentFilters();
        var txt = $("#switches-filter-input").val();
        var noresult = true;
        $(".device").each(function() {
          if ( deviceType($(this),filters) && inSearch($(this),txt)){
            $(this).show();
            noresult = false;
          } else {
            $(this).hide();
          }
        });
        if (noresult) {
          $("#noresult").show();
        } else {
          $("#noresult").hide();
        }
      }

      $("#switches-filter-input").on("input", function(){
        setShowHide();
      });

      $(".ui.checkbox").checkbox();

      $(".ui.checkbox").on("click", function(){
        setShowHide();
      });

      $("#clearButton").click(function () {
        $.each(ids, function(k, v) {
          $(`#${k}`).prop("checked", true);
        });
        $("#switches-filter-input").val("");
        setShowHide();
        return false;
      });

      setShowHide();
    }
    </script>

    <div class="eight wide column">
      <div class="ui orange segment">
        <h3 class="ui orange header"><i class="warning sign icon"></i> Not on this list?</h3>
        <p>Your network hardware is not on this list? Chances are that it works with a similar module already. Try this first and if it does work, let us know what module you used on what hardware and your firmware version. You can communicate that information to us by <a href="https://github.com/inverse-inc/packetfence/issues" target="_blank">filing a ticket</a>.
        </p>
        <p>Otherwise, we are always interested in adding new hardware support into PacketFence. Please <a href="/support.html#/commercial" target="_blank">contact us</a>.</p>
      </div>
    </div>
  </div>

</div><!-- material tab -->'.$nl;

print($html);

sub getRelated {
    my ($m) = @_;
    no strict qw(refs);
    my $p =return *{"${m}::ISA"}->[-1];
    $p =~ s/pf::Switch:://;
    return $p;
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
