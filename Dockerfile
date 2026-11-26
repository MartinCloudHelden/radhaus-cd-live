# Stufe 1: Abhängigkeiten installieren
FROM python:3.13-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stufe 2: schlankes Laufzeit-Image
FROM python:3.13-slim
# pip wird zur Laufzeit nicht gebraucht – weniger Software, weniger Angriffsfläche
RUN python -m pip uninstall --yes pip
COPY --from=build /install /usr/local
WORKDIR /app
COPY shop/ shop/
ARG GIT_SHA=unbekannt
ENV GIT_SHA=${GIT_SHA} PORT=8080
EXPOSE 8080
# nicht als root laufen
USER 1000
CMD ["python", "-m", "shop.server"]
