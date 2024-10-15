## About
[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/Memonia/dockerComposeFlake/badge)](https://flakehub.com/flake/Memonia/dockerComposeFlake)

This flake is a convenient wrapper around `docker compose up` stack deployment, which additionally supports `jsonnet` compose files.

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
The snippet below will create a systemd service `myComposeStack.service`, which runs `docker compose up` with a file specified in `composeFilePath`.

```nix
config.dockerCompose.stacks."myComposeStack" = {
    enable = true;
    composeFilePath = ./myComposeStack.yaml;
};
```

In order to use a `jsonnet` file for your compose stack, modify the configuration like so: 

```nix
config.dockerCompose.stacks."myComposeStack" = {
    enable = true;
    isJsonnetFile = true;
    composeFilePath = ./myComposeStack.jsonnet;
};
```

Now, before starting the stack, the `jsonnet` file will be converted to `json`, which docker supports.

## Tips
Suppose, your `myComposeStack.yaml` builds one of its services like so:

```yaml
name: myComposeStack
services:
  app:
    build:
      context: ./myComposeStackDirectory
      dockerfile: app.Dockerfile
```

Depending on where the compose stack directory is located, the files may not be transferred to the store together with the compose file. To ensure it works properly, you may change your `nix` configuration like so:

```nix
config.dockerCompose.stacks."myComposeStack" = {
    enable = true;
    composeFilePath = ./myComposeStack.yaml;
    environment = [
        COMPOSE_CONTEXT = ./myComposeStackDirectory;
    ];
};
```

And `myComposeStack.yaml` like so:

```yaml
name: myComposeStack
services:
  app:
    build:
      context: ${COMPOSE_CONTEXT}
      dockerfile: app.Dockerfile
```

Now, because the extra directory is referenced within the `nix` configuration, it will be transferred to the store together with `myComposeStack.yaml`.
