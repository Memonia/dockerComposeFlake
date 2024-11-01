{ config, lib, pkgs, ... }:

{
	options.dockerCompose = {
		dockerPackage = lib.mkPackageOption pkgs "docker" { };
		jsonnetPackage = lib.mkPackageOption pkgs "jsonnet" { };
		stacks = lib.mkOption {	   
			default = {};
			description = "";
			type = lib.types.attrsOf (lib.types.submodule {
				options = {
					enable = lib.mkEnableOption "a docker compose project";
					isJsonnetFile = lib.mkOption {
						type = lib.types.bool;
						default = false;
						description = 
							"Whether docker compose file is a jsonnet file. If true, " +
							"the file will be converted to a json file before running 'docker compose up' command";
					};

					composeFilePath = lib.mkOption {
						type = lib.types.path;
						description = "Path to the docker compose file";
					};

					environment = lib.mkOption  {
						type = lib.types.attrs;
						default = {};
						description = "The value of 'systemd.services.<name>.environment'";
					};  

					extraComposeFlags = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						default = [];
						description = "Flags to pass to 'docker compose' command";
					};         
				
					extraUpFlags = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						default = [];
						description = "Flags to pass to 'docker compose up' command";
					};

					extraPackages = lib.mkOption {
						type = lib.types.listOf lib.types.package;
						default = [];
						description = "Extra packages to add to systemd.services.<name>.path";
					};
				};         
			});
		};
	};
	
	config = lib.mkIf (config.dockerCompose.stacks != { }) {
		systemd.services = lib.mapAttrs (name: composeConfig:
		let
			_jnet = "${config.dockerCompose.jsonnetPackage}/bin/jsonnet";
			_docker = "${config.dockerCompose.dockerPackage}/bin/docker";
			
			_jsonnetCommandOutputFile = "${builtins.baseNameOf composeConfig.composeFilePath}.json";
			_jsonnetCommand = pkgs.runCommand "${name}-jsonnet-result" { } ''
				mkdir $out
				${_jnet} --output-file $out/${_jsonnetCommandOutputFile} ${composeConfig.composeFilePath}
			'';

			_upFlags = "${lib.strings.concatStringsSep " " composeConfig.extraUpFlags}"; 
			_composeFlags = "${lib.strings.concatStringsSep " " composeConfig.extraComposeFlags}";
			_file = 
				if composeConfig.isJsonnetFile 
					then "${_jsonnetCommand}/${_jsonnetCommandOutputFile}" 
					else "${composeConfig.composeFilePath}"
			;
		
			script = ''
				${_docker} compose --file ${_file} ${_composeFlags} up ${_upFlags}
			'';
		in
		{
			after = ["docker.service" "docker.socket"];
			wantedBy = ["multi-user.target"];
			path = composeConfig.extraPackages;
			script = script;
			environment = composeConfig.environment;
		}) (lib.filterAttrs (_: cfg: cfg.enable) config.dockerCompose.stacks);
	};
}
