# Utiliser l'image de base Python
FROM python:3.9

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

RUN apt-get update && apt-get install -y nmap iputils-ping

# Copier les fichiers nécessaires dans le conteneur
COPY requirements.txt /app/
COPY test.py /app/
COPY templates /app/templates

# Installer les dépendances
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
ENV FLASK_APP test.py
# Exposer le port sur lequel Flask s'exécute
EXPOSE 5000-5005

# Commande pour exécuter l'application Flask
CMD ["python", "test.py"]
