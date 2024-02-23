import json
import nmap
import platform
import subprocess
import requests

from flask import Flask, render_template
from markupsafe import Markup

app = Flask(__name__,template_folder='templates')

def collecter_informations_locales():
    local_ip = subprocess.getoutput('hostname -I').split()[0]
    hostname = platform.node()
    return local_ip, hostname

def scanner_reseau():
    nm = nmap.PortScanner()
    nm.scan(hosts='192.168.1.1/24', arguments='-p 22-80')
    
    open_ports = []
    for host in nm.all_hosts():
        for proto in nm[host].all_protocols():
            lport = nm[host][proto].keys()
            open_ports.extend([(host, port) for port in lport])

    result = {
        'hosts': nm.all_hosts(),
        'scan_result': nm.csv(),
        'open_ports': open_ports,
    }

    with open('scan_result.json', 'w') as json_file:
        json.dump(result, json_file)

    return result

def main():
    local_ip, hostname = collecter_informations_locales()
    resultat_scan = scanner_reseau()

    print(f"Adresse IP locale: {local_ip}")
    print(f"Nom de la machine: {hostname}")
    print(f"Résultats du dernier scan: {resultat_scan}")

@app.route('/')
def tableau_de_bord():
    local_ip, hostname = collecter_informations_locales()
    resultat_scan = scanner_reseau()
    machines_connectees = len(resultat_scan['hosts'])
    ping_result = subprocess.getoutput('ping -c 5 google.com')
    repository_url = "https://github.com/NChansard/MSPR-BLOC1"
    version = read_github_readme(repository_url)

    return render_template('dashboard.html', local_ip=local_ip, hostname=hostname,
                           machines_connectees=machines_connectees, resultat_scan=resultat_scan,
                           ping_result=ping_result, version=version)

def read_github_readme(repo_url):
    version = None
    try:
        # Construire l'URL du fichier README en format RAW
        readme_url = f"https://raw.githubusercontent.com/NChansard/MSPR-BLOC1/main/version.md"
        response = requests.get(readme_url)
        print(response)

        if response.status_code == 200:
            # Afficher le contenu du README
            version = response.text
            print(response.text)
        else:
            print(f"Erreur lors de la requête. Code de statut : {response.status_code}")

    except requests.RequestException as e:
        print(f"Erreur lors de la requête : {e}")
    return version
if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)
