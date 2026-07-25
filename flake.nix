{
  description = "Unified NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkHost =
        {
          hostname,
          username,
          hostModule,
          homeModule,
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname username;
          };
          modules = [
            ./modules/nixos/common.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs hostname username;
              };
              home-manager.users.${username} = import homeModule;
            }
            hostModule
          ];
        };
    in
    {
      nixosConfigurations = {
        thinkpad-t14-gen5 = mkHost {
          hostname = "thinkpad-t14-gen5";
          username = "tarutyyyne";
          hostModule = ./hosts/thinkpad-t14-gen5;
          homeModule = ./home/tarutyyyne;
        };

        thinkpad-l480 = mkHost {
          hostname = "thinkpad-l480";
          username = "tarutyyyne";
          hostModule = ./hosts/thinkpad-l480;
          homeModule = ./home/tarutyyyne;
        };
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
