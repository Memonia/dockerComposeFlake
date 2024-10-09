import os, socket

def run(addr, port):
	sct = socket.socket(
		socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP
	)

	sct.bind((addr, port))
	sct.listen(1)
	
	print(f'Listening on {addr}:{port}')
	while True:
		connection, addr = sct.accept()
		addr_str = f'{addr[0]}:{addr[1]}'
		
		try:
			while True:
				data = connection.recv(256)
				if len(data) <= 0:
					break
				
				connection.sendall(data)
				print(f"Echo '{data}' to {addr_str}")

		finally:
			connection.close()
			print(f'Connection with {addr_str} closed')

if __name__ == '__main__':
	addr = '0.0.0.0'
	port = int(os.environ['LISTEN_PORT'])
	run(addr, port)
