#!/bin/bash

# Variables
FRONTEND_PORT=3000
CONTAINER_NAME="nodejs_frontend_container"
API_URL="http://ec2-107-21-142-216.compute-1.amazonaws.com:5000/recommendations"
REPO_URL="https://github.com/NicolasPalma0511/frontApiExamen"

# Función para comprobar errores
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error durante la ejecución: $1"
        exit 1
    fi
}

# Clonar el repositorio
git clone $REPO_URL frontend
check_error "Error clonando el repositorio."

# Cambiar al directorio del proyecto frontend
cd frontend

# Iniciar el contenedor en modo interactivo y en segundo plano, mapeando el puerto 3000
container_id=$(docker run -d -p $FRONTEND_PORT:$FRONTEND_PORT --env API_URL=$API_URL --name $CONTAINER_NAME -v $(pwd):/app -w /app node:18 /bin/bash -c "npm install && npm start")
check_error "Error iniciando el contenedor de Node.js."

# Mostrar la URL
echo "La aplicación está disponible en http://localhost:$FRONTEND_PORT"
