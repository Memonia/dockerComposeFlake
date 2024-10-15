{
	description = "A wrapper for running docker compose stacks as systemd services";
	inputs = {
		nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0";
	};

	outputs = { self, nixpkgs, ... } @inputs:  
	let
		lib = nixpkgs.lib;
		dockerCompose = import ./src;
	in
	{	
		nixosModules.default = dockerCompose;
		checks = let 
			systems = ["x86_64-linux" "aarch64-linux"];
		in
		lib.genAttrs systems (
			system: let
				tests = (import ./test { 
					pkgs = import nixpkgs { system = system; }; 
					dockerCompose = dockerCompose;
				}).tests;
			in
			tests
		); 
	};
}
