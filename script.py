import json
import nmap
import platform
import subprocess
import requests
import os 

from flask import Flask, render_template, redirect, url_for

app = Flask(__name__,template_folder='templates')

def check_and_update_repository():
    desktop_path = "/Users/nathanaelchansard/Desktop/"  # Remplacez cela par le chemin absolu de votre répertoire Desktop
    repository_path = os.path.join(desktop_path, "MSPR-BLOC1")

    # Vérifier si le répertoire existe
    if not os.path.exists(repository_path):
        # Si le répertoire n'existe pas, effectuer un git clone
        clone_command = ["git", "clone", "https://github.com/NChansard/MSPR-BLOC1.git", repository_path]
        subprocess.run(clone_command, check=True)

    # Entrer dans le répertoire
    os.chdir(repository_path)

    # Effectuer un git pull pour mettre à jour le répertoire
    pull_command = ["git", "pull"]
    subprocess.run(pull_command, check=True)

@app.route('/upload', methods=['POST'])
def upload_file():
    local_ip = subprocess.getoutput('hostname -I').split()[0]
    scan_file = f'{local_ip}.json'
    if not os.path.exists(scan_file):
        return 'Scan file not found'
    with open(scan_file, 'rb') as f:
        # Send the file to the web server
        url = "http://192.168.1.133:9999/receive-file"
        response = requests.post(url, files={'file': f})
    if response.ok:
        return 'File successfully sent'
    else:
        return f'Error sending file: {response.status_code}'

def collecter_informations_locales():
    local_ip = subprocess.getoutput('hostname -I').split()[0]
    hostname = platform.node()
    return local_ip, hostname

def scanner_reseau():
    local_ip = subprocess.getoutput('hostname -I').split()[0]
    nm = nmap.PortScanner()
    nm.scan(hosts='192.168.1.1/24', arguments='-p 22-80')
    
    open_ports = []
    for host in nm.all_hosts():
        for proto in nm[host].all_protocols():
            lport = nm[host][proto].keys()
            open_ports.extend([(host, port) for port in lport])

    result = {
        'hosts': nm.all_hosts(),
        f'{local_ip}': nm.csv(),
        'open_ports': open_ports,
    }

    with open(f'{local_ip}.json', 'w') as json_file:
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
    check_and_update_repository()
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

        if response.status_code == 200:
            # Afficher le contenu du README
            version = response.text
        else:
            print(f"Erreur lors de la requête. Code de statut : {response.status_code}")

    except requests.RequestException as e:
        print(f"Erreur lors de la requête : {e}")
    return version

@app.route('/scan', methods=['POST'])
def relancer_scan():
    try:
        local_ip, hostname = collecter_informations_locales()
        resultat_scan = scanner_reseau()
        machines_connectees = len(resultat_scan['hosts'])
        ping_result = subprocess.getoutput('ping -c 5 google.com')
        repository_url = "https://github.com/NChansard/MSPR-BLOC1"
        version = read_github_readme(repository_url)

        return render_template('dashboard.html', local_ip=local_ip, hostname=hostname,
                               machines_connectees=machines_connectees, resultat_scan=resultat_scan,
                               ping_result=ping_result, version=version, scan_success=True)
    except Exception as e:
        return render_template('dashboard.html', error=str(e))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9998,debug=True)