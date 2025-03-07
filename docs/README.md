<div style="display: flex; align-items: center;">
  <div style="flex: 1;">
    <img src="../.gitbook/assets/home/empire_helmet.png" alt="Empire Helmet" width="560" height="315">
  </div>
  <div style="flex: 1; padding-left: 20px;">
    <h1>Empire Command & Control</h1>
    <p>
      Empire is a powerful post-exploitation and adversary emulation framework designed to aid Red Teams and Penetration Testers. 
      Built with flexibility and modularity in mind, Empire enables security professionals to conduct sophisticated operations with ease.
    </p>
    <p>
      The Empire server is written in Python 3, providing a robust and extensible backend for managing compromised systems. 
      Operators can interact with the server using Starkiller, a graphical user interface (GUI) that enhances usability and management.
    </p>
  </div>
</div>

## Key Features

* Server/Client Architecture – Supports multiplayer operations with remote client access.
* Multi-Client Support – Choose between a GUI (Starkiller) or command-line interface.
* Fully Encrypted Communications – Ensures secure C2 channels
* Diverse Listener Support – Communicate over HTTP/S, Malleable HTTP, and PHP.
* Extensive Module Library – Over 400 tools in PowerShell, C#, and Python for post-exploitation and lateral movement.
* Donut Integration – Generate shellcode for execution.
* Modular Plugin Interface – Extend Empire with custom server features.
* Flexible Module Framework – Easily add new capabilities.
* Advanced Obfuscation – Integrated [ConfuserEx 2](https://github.com/mkaring/ConfuserEx) and [Invoke-Obfuscation](https://github.com/danielbohannon/Invoke-Obfuscation) for stealth.
* In-Memory Execution – Load and execute .NET assemblies without touching disk.
* Customizable Bypasses – Evade detection using JA3/S and JARM evasion techniques.
* MITRE ATT&CK Integration – Map techniques and tactics directly to the framework.
* Built-in Roslyn Compiler – Compile C# payloads on the fly (thanks to Covenant).
* Broad Deployment Support – Install on Docker, Kali Linux, Ubuntu, and Debian.