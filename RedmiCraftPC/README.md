# RedmiCraft PC Server Manager

Windows GUI for hosting a Minecraft Java Edition server.

Defaults:
- Minecraft Java server: 26.3
- Java: 25
- Port: 25565
- RAM: 4 GB
- Max players: 10
- View distance: 8
- Simulation distance: 6
- Online authentication: enabled

The manager stores server data in Documents\\RedmiCraft Server and app settings in LocalAppData\\RedmiCraftPC.

Setup downloads the official Minecraft server metadata and server JAR from Mojang and, when needed, downloads a portable Temurin Java 25 runtime. Users must accept the Minecraft EULA before setup.

For internet play, configure your router/firewall or use an appropriate private networking solution. LAN play needs no public port forwarding when both PCs are on the same local network.
