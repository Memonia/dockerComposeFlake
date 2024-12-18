{ pkgs, dockerCompose, ... }:

let
	constants = import ./constants.nix;
	common = import ./compose-common.nix { 
		pkgs = pkgs;
		constants = constants; 
		dockerCompose = dockerCompose;
	};

	testNames = {
		composeYaml = "compose-yaml";
		composeJsonnet = "compose-jsonnet";
	};
in
{
	tests = {
		"${testNames.composeYaml}" = common.makeTest {
			name = testNames.composeYaml;
			stackConfig = {
				isJsonnetFile = false;
				composeFilePath = ./service/compose/compose-yaml.yaml;
			};
		};

		"${testNames.composeJsonnet}" = common.makeTest {
			name = testNames.composeJsonnet;
			stackConfig = {
				isJsonnetFile = true;
				composeFilePath = ./service/compose/compose-jsonnet.jsonnet;
			};
		};
	};
}
