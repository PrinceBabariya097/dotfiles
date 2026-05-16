{
  description = "Prince's Bleeding-Edge Wayland Ecosystem";

  # 1. THE INPUTS: Where is the code coming from?
  inputs = {
    # The massive community repository for stable/pre-compiled apps
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The bleeding-edge source code directly from the developers
    hyprland.url = "github:hyprwm/Hyprland";
    hyprpaper.url = "github:hyprwm/hyprpaper";
    hypridle.url  = "github:hyprwm/hypridle";
  };

  # 2. THE OUTPUTS: What are we building?
  outputs = { self, nixpkgs, hyprland, hyprpaper, hypridle }: 
  let
    # Define your system architecture
    system = "x86_64-linux";
    
    # Load the standard packages for that architecture
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      
      # SOURCE BUILDS:
      # We tell Nix to go into the inputs, run the developer's build scripts, 
      # and output the absolute latest binaries here.
      hyprland = hyprland.packages.${system}.hyprland;
      hyprpaper = hyprpaper.packages.${system}.hyprpaper;
      hypridle = hypridle.packages.${system}.hypridle;

      # PRE-COMPILED STABLE BUILDS:
      # We don't want to waste time compiling these, so we just grab them 
      # directly from the standard Nixpkgs repository.
      waybar = pkgs.waybar;
      dunst = pkgs.dunst;
      rofi = pkgs.rofi-wayland;
    };
  };
}
