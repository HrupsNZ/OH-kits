from __future__ import print_function

from lib.common.plugins import Plugin
import lib.common.helpers as helpers

import socket
import _thread
import ssl
import queue


# this class MUST be named Plugin
class Plugin(Plugin):
    description = "Socks proxy server plugin."

    def onLoad(self):
        """ any custom loading behavior - called by init, so any
        behavior you'd normally put in __init__ goes here """

        self.commands = {'do_socksserver': {'Description': 'Manages socks proxy server',
                                     'arg': '<start|stop> [handler port] [proxy port] [certificate] [private key]'
                                     }
                         }
        self.handler_port = '443'
        self.proxy_port = '1080'
        self.certificate = './data/empire-chain.pem'
        self.privateKey = './data/empire-priv.key'
        self.running = False

    def execute(self, dict):
        # This is for parsing commands through the api

        try:
            # essentially switches to parse the proper command to execute
            if dict['command'] == 'do_socksserver':
                results = self.do_socksserver(dict['arguments']['arg'])
            return results
        except:
            return False

    def get_commands(self):
        return self.commands

    def register(self, mainMenu):
        """ any modifications to the mainMenu go here - e.g.
        registering functions to be run by user commands """
        mainMenu.__class__.do_socksserver = self.do_socksserver

    def do_socksserver(self, args):
        "Manages socks proxy server"
        args = args.split(" ")
        if args[0] == "start":
            self.start_socks_server(args)
        elif args[0] == "stop":
            self.stop_socks_server()
        else:
            print(helpers.color("[!] socksserver <start|stop> [handler port] [proxy port] [certificate] [private key]", "red"))

    def start_socks_server(self, args):
        if not self.running:
            self.running = True
            if len(args) > 4:
                self.certificate = args[3]
                self.privateKey = args[4]
            if len(args) > 2:
                self.handler_port = args[1]
                self.proxy_port = args[2]
            _thread.start_new_thread(self.server, (self.handler_port, self.proxy_port, self.certificate, self.privateKey))
        else:
            print(helpers.color("[!] Server is already running!", "red"))

    def stop_socks_server(self):
        if self.running:
            self.running = False
            print(helpers.color("[*] Stopping socks proxy server...", "blue"))
            socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("127.0.0.1", int(self.handler_port)))
            socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("127.0.0.1", int(self.proxy_port)))
        else:
            print(helpers.color("[!] Server is not running!", "red"))

    def shutdown(self):
        """if the plugin spawns a process provide a shutdown method for when Empire exits else leave it as pass"""
        return

    def handlerServer(self, q, handlerPort, certificate, privateKey):
        context = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
        context.load_cert_chain(certificate, privateKey)
        try:
            dock_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            dock_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            dock_socket.bind(('', int(handlerPort)))
            dock_socket.listen(5)
            print(helpers.color("[*] Handler listening on: " + handlerPort, "blue"))
            print(helpers.color("[*] Using certificate: " + certificate, "blue"))
            print(helpers.color("[*] Using private key: " + privateKey, "blue"))
            while self.running:
                try:
                    clear_socket, address = dock_socket.accept()
                    client_socket = context.wrap_socket(clear_socket, server_side=True)
                    try:
                        data = b""
                        while (data.count(b'\n') < 3):
                            data_recv = client_socket.recv()
                            data += data_recv
                        client_socket.send(
                            b"HTTP/1.1 200 OK\nContent-Length: 999999\nContent-Type: text/plain\nConnection: Keep-Alive\nKeep-Alive: timeout=20, max=10000\n\n")
                        q.get(False)
                    except Exception as e:
                        pass
                    q.put(client_socket)
                except Exception as e:
                    pass
        except Exception as e:
            pass
        finally:
            dock_socket.close()

    def getActiveConnection(self, q):
        try:
            client_socket = q.get(block=True, timeout=10)
        except:
            return None
        try:
            client_socket.send(b"HELLO")
        except:
            return self.getActiveConnection(q)
        return client_socket

    def server(self, handlerPort, proxyPort, certificate, privateKey):
        q = queue.Queue()
        _thread.start_new_thread(self.handlerServer, (q, handlerPort, certificate, privateKey))
        try:
            dock_socket2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            dock_socket2.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            dock_socket2.bind(('127.0.0.1', int(proxyPort)))
            dock_socket2.listen(5)
            print(helpers.color("\n[*] Socks Server listening on: " + proxyPort, "blue"))
            while self.running:
                try:
                    client_socket2, address = dock_socket2.accept()
                    client_socket = self.getActiveConnection(q)
                    if client_socket == None:
                        client_socket2.close()
                    _thread.start_new_thread(self.forward, (client_socket, client_socket2))
                    _thread.start_new_thread(self.forward, (client_socket2, client_socket))
                except Exception as e:
                    print(helpers.color("[!] " + str(e), "red"))
        except Exception as e:
            print(helpers.color("[!] " + str(e), "red"))
        finally:
            dock_socket2.close()
            print(helpers.color("\n[*] Socks proxy server stopped", "blue"))

    def forward(self, source, destination):
        try:
            string = ' '
            while string:
                string = source.recv(1024)
                if string:
                    destination.sendall(string)
                else:
                    source.shutdown(socket.SHUT_RD)
                    destination.shutdown(socket.SHUT_WR)
        except:
            try:
                source.shutdown(socket.SHUT_RD)
                destination.shutdown(socket.SHUT_WR)
            except:
                pass
            pass


