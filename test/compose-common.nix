{ pkgs, constants, dockerCompose, ... }:

let
	echoPort = 11111;
	echoData = "Hi!";
	vmBaseImageFile = "/tmp/dockerCompose/alpine";

	# The VM has no internet access, so we build the test outside image and transfer it to the VM
	testDockerImage = pkgs.dockerTools.buildImage {
		tag = "local";
		name = "echo";
		fromImage = pkgs.dockerTools.pullImage { 
			sha256 = "0fzqhqvvb0pzkwvjwyqjfv3rw2w8006xz4mhk0dk5clmyb08hqwc";
			imageName = "alpine";
			imageDigest = "sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d";
			finalImageTag = "3.20.3";
			finalImageName = "alpine";
		};

		config = {
			Env = ["LISTEN_PORT=12345"];
			ExposedPorts = { "12345/tcp" = {}; };
		};

		copyToRoot = pkgs.buildEnv {
			name = "root";
			paths = [pkgs.python3];
			pathsToLink = ["/bin"];
		};

		config.Cmd = ["python" "-u" ./service/echo.py];
	};
in
{	
	makeTest = { name, dockerComposeConfig, ... }: pkgs.nixosTest {		
		name = name;
		globalTimeout = 600;
		nodes.node = { ... }: {
			imports = [dockerCompose];

			config.virtualisation = {
				docker.enable = true;
				writableStore = true;
			};

			config.dockerCompose."${name}" = dockerComposeConfig // {
				enable = true;
				environment = {
					LISTEN_PORT = toString echoPort;
				};
			};
		};

		testScript = ''
            node.copy_from_host('${testDockerImage}', '${vmBaseImageFile}'); 

            node.wait_for_unit('docker.socket')
            node.wait_for_unit('docker.service')
            node.succeed('docker load -i "${vmBaseImageFile}"')

            # Make sure the service is started after the image has become available
            node.succeed('systemctl restart "${name}.service"')

            node.wait_for_unit('${name}.service')
            node.wait_for_open_port(${toString echoPort}, '127.0.0.1', 30)

            # Give it some time to prepare
            node.succeed('sleep 10')

            (_, output) = node.execute(
                command = "echo -n '${echoData}' | nc 127.0.0.1 ${toString echoPort}",
                timeout = 30
            )

            assert output == '${echoData}'
        '';
	};
}
