{ config, lib, pkgs, ... }:

{
	options.dockerCompose = lib.mkOption {	   
		default = {};
		description = "";
		type = lib.types.attrsOf (lib.types.submodule {
			options = {
				enable = lib.mkEnableOption "a docker compose project";
				composeFilePath = lib.mkOption {
					type = lib.types.path;
					description = "Path to the docker compose file";
				};

				isJsonnetFile = lib.mkOption {
					type = lib.types.bool;
					default = false;
					description = 
						"Whether docker compose file is a jsonnet file. If true, " +
						"the file will be converted to a json file before running 'docker compose up' command";
				};

				environment = lib.mkOption  {
					type = lib.types.attrs;
					default = {};
					description = "The value of 'systemd.services.<name>.environment'";
				};  

				extraComposeFlags = lib.mkOption {
					type = lib.types.listOf lib.types.str;
					default = [];
					description = "Given strings will be passed directly to 'docker compose' command";
				};         
            
                extraUpFlags = lib.mkOption {
					type = lib.types.listOf lib.types.str;
					default = [];
					description = "Given strings will be passed directly to 'docker compose up' command";
                };
			};
		});
	};

	config = lib.mkIf (config.dockerCompose != { }) {
		systemd.services = lib.mapAttrs (name: composeConfig:
		let	   
			_out = "./out/${builtins.baseNameOf composeConfig.composeFilePath}.json";
			_composeFlags = "${lib.strings.concatStringsSep " " composeConfig.extraComposeFlags}";
            _upFlags = "${lib.strings.concatStringsSep " " composeConfig.extraUpFlags}"; 

			path = [pkgs.docker] ++ (if composeConfig.isJsonnetFile then [pkgs.jsonnet] else []);
			script = 
				if composeConfig.isJsonnetFile 
					then ''
                        mkdir --parents ${builtins.dirOf _out}
						jsonnet --output-file ${_out} ${composeConfig.composeFilePath}
						docker compose --file ${_out} ${_composeFlags} up ${_upFlags}
					''

					else ''
						docker compose --file ${composeConfig.composeFilePath} ${_composeFlags} up ${_upFlags}
					'' 
				;
		in
		{
			after = ["docker.service" "docker.socket"];
			wantedBy = ["multi-user.target"];
			path = path;
			script = script;
			environment = composeConfig.environment;
		}) (lib.filterAttrs (_: cfg: cfg.enable) config.dockerCompose);
	};
}
