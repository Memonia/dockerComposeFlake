## About
[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/Memonia/dockerComposeFlake/badge)](https://flakehub.com/flake/Memonia/dockerComposeFlake)

This flake is a convenient wrapper around `docker compose up` project deployment, which additionally supports `jsonnet` compose files.

## Installation
Add this flake to your `flake.nix`. First `#1`, specify dockerCompose flake as an input, then `#2` make it available under the `config` set.
```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        # (1)
        dockerCompose.url = "github:Memonia/dockerComposeFlake";
        # Or pull from FlakeHub
        # dockerCompose.url = https://flakehub.com/f/Memonia/dockerComposeFlake/<version>
    };

    outputs = { nixpkgs, dockerCompose, ... }: {
        nixosConfigurations = {
            myNixosHost = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./configuration.nix
                    # (2)
                    dockerCompose.nixosModules.default
                ];
            };
        };
    };
}
```

## How to use it
The snippet below will create a systemd service `myComposeProject.service`, which runs `docker compose up` with a file specified in `composeFilePath`.

```nix
config.dockerCompose."myComposeProject" = {
    enable = true;
    composeFilePath = ./myComposeProject.yaml;
};
```

In order to use a `jsonnet` file for your compose project, modify the configuration like so: 

```nix
config.dockerCompose."myComposeProject" = {
    enable = true;
    isJsonnetFile = true;
    composeFilePath = ./myComposeProject.jsonnet;
};
```

Now, before starting the project, the `jsonnet` file will be converted to `json`, which docker supports.

## Tips
Suppose, your `myComposeProject.yaml` builds one of its services like so:

```yaml
name: myComposeProject
services:
  app:
    build:
      context: ./myComposeProjectDirectory
      dockerfile: app.Dockerfile
```

Depending on where the compose project directory is located, the files may not be transferred to the store together with the compose file. To ensure it works properly, you may change your `nix` configuration like so:

```nix
config.dockerCompose."myComposeProject" = {
    enable = true;
    composeFilePath = ./myComposeProject.yaml;
    environment = [
        COMPOSE_CONTEXT = ./myComposeProjectDirectory;
    ];
};
```

And `myComposeProject.yaml` like so:

```yaml
name: myComposeProject
services:
  app:
    build:
      context: ${COMPOSE_CONTEXT}
      dockerfile: app.Dockerfile
```

Now, because the extra directory is referenced within the `nix` configuration, it will be transferred to the store together with `myComposeProject.yaml`.
