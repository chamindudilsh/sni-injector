# Python SSH SSL SNI Injector For Free Internet [HTTP Injector]

<p align="center">
   <a href="#-installation">Installation & Usage</a>
   &nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
   <a href="#-how-it-works">How it Works</a>
</p>

**SVL Injector / HTTP Injector alternative for Linux.**

It works pretty easy on Ubuntu/Mint where gsettings is available. 

You can add this to start menu by copying `sni-injector.desktop` to `~/.local/share/applications` <br>
Make sure to edit `Exec=` and `Path=` as necessary.

If your distro doesn't have `gsettings`, you might have to modify `run_sni.sh` with it's equivalent or,
You will have to manually run 2 scripts (main.py & ssh.sh) and set socks proxy.
Check the installation guide.

---
# 🚀 Installation

Check `dependencies.txt` to see Linux dependencies. Install them for this to work properly.

## Ubuntu / Mint

1. Clone the repository.<br>
   ```console
   git clone https://github.com/chamindudilsh/sni-injector.git
   ```
2. Add your SNI host and SSH settings to `settings.ini` <br>

   <img src="https://github.com/chamindudilsh/sni-injector/blob/17bad5b2beba9905dba96f9c5e0f266f9e322787/static/settings.png">

> [!NOTE]
> If you wish to use manual login for SSH, uncomment `ssh ` and comment `sshpass ` in `ssh.sh`
   
3. Make `ssh.sh`, `run_sni.sh` and `sni-launcher.sh` executable. <br>
   *(First time only)*
   
   ```console
   chmod +x ssh.sh
   chmod +x run_sni.sh
   chmod +x sni-launcher.sh
   ```
5. Run `sni-launcher.sh` <br>
   *(Uses a simple zenity GUI + gsettings to set proxy automatically)*

   ```console
   bash ./sni-launcher.sh
   ```
   Or
   
   These also work (No GUI)

   ```console
   bash ./run_sni.sh start
   bash ./run_sni.sh stop
   ```

---
## Linux 

*(If `gsettings` isn't available on your distro)*

1. Clone the repository.<br>

   ```console
   git clone https://github.com/chamindudilsh/sni-injector.git
   ```
2. Add your SNI host and SSH settings to `settings.ini` <br>

   <img src="https://github.com/chamindudilsh/sni-injector/blob/17bad5b2beba9905dba96f9c5e0f266f9e322787/static/settings.png">

> [!NOTE]
> If you wish to use manual login for SSH, uncomment `ssh ` and comment `sshpass ` in `ssh.sh`
   
3. Make `ssh.sh`, `run_sni.sh` and `sni-launcher.sh` executable. <br>
   *(First time only)*
   
   ```console
   chmod +x ssh.sh
   ```
5. Run python script. <br>
   ```console
   python3 main.py
   ```
> [!IMPORTANT]
> It's important that `main.py` should run before `ssh.sh`

6. Run `ssh.sh` file.
   ```console
   bash ./ssh.sh
   ```
    <b>OR run one of following commands with args </b>

   <i>Auto login (with ssh password)</i>
   ```console
   sshpass -p [password] ssh -C -o "ProxyCommand=nc -X CONNECT -x 127.0.0.1:9092 %h %p" [username]@[host] -p [port] -v -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
   ```
   
   <i>Manual login (without ssh password in command)</i>   
   ```console
   ssh -C -o "ProxyCommand=nc -X CONNECT -x 127.0.0.1:9092 %h %p" [username]@[host] -p [port] -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
   ```
   
5. Add socks5 proxy and Enjoy!<br>
   `host: localhost/127.0.0.1`<br>
   `port: 1080`

---
## Windows

> [!NOTE]
> Just use [SVL Injector](https://sourceforge.net/projects/svlheaderinjector) instead of this. It's much easier.

1. Clone the repository.<br><br>
2. Install requirements.<br>
   ```console
   pip install -r requirements.txt
   ```
3. Add your SNI host and ssh host to <code>settings.ini </code><br>
   <img src="https://user-images.githubusercontent.com/90369043/184321639-3340d961-8971-43ef-824e-3b47638251b2.png" width="200px"><br>
> [!NOTE]
> You will have to enter ssh username, password and port in the command.

4. Run Python script.<br>
   ```console
   python3 main.py
   ```
5. Install nmap. *(you need ncat for run this script)*.<br>
   nmap download [page](https://nmap.org/dist/).<br><br>
6. Run ssh command.
   ```console
   ssh -C -o "ProxyCommand=ncat --proxy 127.0.0.1:9092 %h %p" [username]@[host] -p 443 -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=nul
   ```
7. Add socks5 proxy and Enjoy!<br>
   <code>host: localhost/127.0.0.1 </code><br>
   <code>port: 1080 </code>
   
---
## 💻 How it works

### What is SNI?

[***Server Name Indication (SNI)***](https://en.wikipedia.org/wiki/Server_Name_Indication) is an extension to the Transport Layer Security (TLS) computer networking protocol by which a client indicates which hostname it is attempting to connect to at the start of the handshaking process.This allows a server to present one of multiple possible certificates on the same IP address and TCP port number and hence allows multiple secure (HTTPS) websites (or any other service over TLS) to be served by the same IP address without requiring all those sites to use the same certificate [<sup>Read more</sup>](https://en.wikipedia.org/wiki/Server_Name_Indication)

Here's a screenshot of **Wireshark** while I'm attempting to connect to zoom.us via https.
<img src="https://github.com/miyurudassanayake/sni-injector/blob/master/static/wireshark.png" width="70%"><br>
As you can see, I applied the <code>ssl.handshake.extensions server name=zoom.us</code> filter to wireshark to filter ssl handshakes where sni is <code>zoom.us</code>.

### What is SNI BUG Host

SNI bug hosts can be in various forms. They can be a packet host, a free CDN host, government portals, zero-rated websites, social media (subscription), and a variety of other sites. They also do a fantastic job of getting over your Internet service provider's firewall.

If you have a subscription to <code>zoom.us</code> and want to visit Zoom, your ISP's firewall will scan every time your SSL handshake to determine if the SNI is "zoom.us", and if it does, the firewall will enable you to keep that connection free fo charge. When you have a subscription to access internet, this is what happens.

What if we can modify our SNI and gain access to different sites? Yes! we can. However, SNI verification will fail, and the connection will be terminated by host. But we still can use ***our own TLS connection(with changed SNI) and use a proxy through it access the internet.***

*Here's a simple diagram showing how it's done.*<br>
<img src="https://github.com/miyurudassanayake/sni-injector/blob/master/static/zoom.us.png" width=50%>

### And here's how is it done

To do so, we need to install a proxy on our server and enable TLS encryption. We can use an SSH tunnel to access a proxy that is already installed on the server. And stunnel can be used to add TLS encryption to that connection.
<img src="https://github.com/miyurudassanayake/sni-injector/blob/master/static/stunnel.png" width="80%">

<br>

## Stargazers over time (On original repo)

[![Stargazers over time](https://starchart.cc/miyurudassanayake/sni-injector.svg)](https://github.com/miyurudassanayake/sni-injector)
