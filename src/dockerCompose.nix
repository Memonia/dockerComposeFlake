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
			_out = "./out/${builtins.baseNameOf composeConfig.composeFilePath}.json";
			_upFlags = "${lib.strings.concatStringsSep " " composeConfig.extraUpFlags}"; 
			_composeFlags = "${lib.strings.concatStringsSep " " composeConfig.extraComposeFlags}";
			_docker = "${config.dockerCompose.dockerPackage}/bin/docker";
			_jsonnet = "${config.dockerCompose.jsonnetPackage}/bin/jsonnet";

			script = 
				if composeConfig.isJsonnetFile 
					then ''
						mkdir --parents ${builtins.dirOf _out}
						${_jsonnet} --output-file ${_out} ${composeConfig.composeFilePath}
						${_docker} compose --file ${_out} ${_composeFlags} up ${_upFlags}
					''

					else ''
						${_docker} compose --file ${composeConfig.composeFilePath} ${_composeFlags} up ${_upFlags}
					'' 
				;
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
