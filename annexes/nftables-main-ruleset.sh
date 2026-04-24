# Extrait depuis RP-05-ANDREO-Vincent.docx
# Contexte: Le fichier de configuration de Debian 12 (nftables) est un fichier XML situé dan

<?xml version="1.0"?>
# nftables configuration
  <filter>
    <!-- Règle 1: Bloquer adresses RFC1918 depuis WAN -->
    <rule>
      <id></id>
      <tracker>1700000001</tracker>
      <type>block</type>
      <interface>wan</interface>
      <ipprotocol>inet</ipprotocol>
      <tag></tag>
      <tagged></tagged>
      <max></max>
      <max-src-nodes></max-src-nodes>
      <max-src-conn></max-src-conn>
      <max-src-states></max-src-states>
      <statetimeout></statetimeout>
      <statetype><![CDATA[keep state]]></statetype>
      <os></os>
      <source>
        <network>192.168.0.0/16</network>
      </source>
      <destination>
        <any></any>
      </destination>
      <descr><![CDATA[BLOCK RFC1918 spoofed from WAN]]></descr>
    </rule>

    <!-- Règle 2: Autoriser HTTPS vers WebVirtCloud DMZ -->
    <rule>
      <id></id>
      <tracker>1700000002</tracker>
      <type>pass</type>
      <interface>wan</interface>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <source>
        <any></any>
      </source>
      <destination>
        <address>172.16.0.10</address>
        <port>443</port>
      </destination>
      <log></log>
      <descr><![CDATA[WAN -> DMZ WebVirtCloud HTTPS]]></descr>
    </rule>

    <!-- Règle 3: Autoriser SSH vers Bastion DMZ -->
    <rule>
      <id></id>
      <tracker>1700000003</tracker>
      <type>pass</type>
      <interface>wan</interface>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <source>
        <any></any>
      </source>
      <destination>
        <address>172.16.0.20</address>
        <port>22</port>
      </destination>
      <log></log>
      <descr><![CDATA[WAN -> DMZ Bastion SSH]]></descr>
    </rule>

    <!-- Règle finale WAN: DENY ALL avec logging -->
    <rule>
      <id></id>
      <tracker>1700000099</tracker>
      <type>block</type>
      <interface>wan</interface>
      <ipprotocol>inet46</ipprotocol>
      <source>
        <any></any>
      </source>
      <destination>
        <any></any>
      </destination>
      <log></log>
      <descr><![CDATA[DENY ALL WAN - regle finale]]></descr>
    </rule>

    <!-- Règle DMZ: Autoriser WebVirtCloud -> libvirt API -->
    <rule>
      <id></id>
      <tracker>1700000010</tracker>
      <type>pass</type>
      <interface>dmz</interface>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <source>
        <address>172.16.0.10</address>
      </source>
      <destination>
        <address>192.168.40.2</address>
        <port>16509</port>
      </destination>
      <descr><![CDATA[DMZ WebVirtCloud -> KVM libvirt API]]></descr>
    </rule>

    <!-- Règle finale DMZ: DENY ALL avec logging -->
    <rule>
      <id></id>
      <tracker>1700000098</tracker>
      <type>block</type>
      <interface>dmz</interface>
      <ipprotocol>inet46</ipprotocol>
      <source>
        <any></any>
      </source>
      <destination>
        <any></any>
      </destination>
      <log></log>
      <descr><![CDATA[DENY ALL DMZ - regle finale]]></descr>
    </rule>

  </filter>
# end nftables configuration