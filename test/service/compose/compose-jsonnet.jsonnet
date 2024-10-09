# Making it an invalid json, so that docker can't process it as-is
local value = 45;

{
	name: "echo",
	services: {
		app: {
			image: 'echo:local',
			ports: [
				'127.0.0.1:${LISTEN_PORT}:${LISTEN_PORT}'
			],
			environment: [
				'LISTEN_PORT=${LISTEN_PORT}'
			]
		}
	}
}