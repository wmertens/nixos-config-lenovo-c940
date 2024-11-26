# Custom modules
{ config, pkgs, options, ... }:

{
  imports = [ ./uvdesk.nix ./osticket ];
}
