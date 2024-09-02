#!/bin/bash

# Variables
FRONTEND_PORT=3000
CONTAINER_NAME="nodejs_frontend_container"
API_URL="http://ec2-107-21-142-216.compute-1.amazonaws.com:5000/recommendations"

# Función para comprobar errores
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error durante la ejecución: $1"
        exit 1
    fi
}

# Crear la estructura de archivos
mkdir -p frontend/public

# Crear el archivo index.js
cat <<EOF > frontend/index.js
const express = require('express');
const path = require('path');
const axios = require('axios');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Ruta para servir el archivo HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Ruta para manejar la consulta
app.post('/recommend', async (req, res) => {
    try {
        const response = await axios.post(process.env.API_URL, req.body, {
            headers: {
                'Content-Type': 'application/json',
            },
        });
        res.json(response.data);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error en la solicitud a la API.');
    }
});

app.listen(port, () => {
    console.log(\`Servidor escuchando en http://localhost:\${port}\`);
});
EOF

# Crear el archivo index.html con TailwindCSS
cat <<EOF > frontend/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GIF Recommendations</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100 p-8">
    <div class="max-w-2xl mx-auto bg-white rounded-lg shadow-lg p-6">
        <h1 class="text-2xl font-bold mb-6 text-center">GIF Recommendations</h1>
        <form id="searchForm" class="mb-6">
            <input type="text" id="query" class="border border-gray-300 rounded-lg p-2 w-full mb-4" placeholder="Introduce una consulta" required>
            <button type="submit" class="bg-blue-500 text-white rounded-lg py-2 px-4 w-full">Buscar</button>
        </form>
        <div id="results" class="space-y-6"></div>
    </div>

    <script>
        document.getElementById('searchForm').addEventListener('submit', async function(event) {
            event.preventDefault();
            
            const query = document.getElementById('query').value;
            const resultsDiv = document.getElementById('results');
            
            resultsDiv.innerHTML = '<p class="text-gray-500 text-center">Cargando...</p>';

            try {
                const response = await fetch('/recommend', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ query })
                });

                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }

                const data = await response.json();
                resultsDiv.innerHTML = '';

                data.forEach(([url, description, score]) => {
                    const resultItem = document.createElement('div');
                    resultItem.classList.add('bg-gray-100', 'p-4', 'rounded-lg', 'shadow-md');
                    resultItem.innerHTML = \`
                        <img src="\${url}" alt="\${description}" class="w-full h-auto rounded-md mb-4">
                        <p class="text-gray-700 font-medium">\${description} (Score: \${score.toFixed(2)})</p>
                    \`;
                    resultsDiv.appendChild(resultItem);
                });
            } catch (error) {
                resultsDiv.innerHTML = '<p class="text-red-500 text-center">Error fetching data.</p>';
                console.error('Error:', error);
            }
        });
    </script>
</body>
</html>
EOF

# Crear el archivo package.json
cat <<EOF > frontend/package.json
{
  "name": "nodejs-frontend",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "axios": "^0.21.1",
    "express": "^4.17.1"
  }
}
EOF

# Cambiar al directorio del proyecto frontend
cd frontend

# Iniciar el contenedor en modo interactivo y en segundo plano, mapeando el puerto 3000
container_id=$(docker run -d -p $FRONTEND_PORT:$FRONTEND_PORT --env API_URL=$API_URL --name $CONTAINER_NAME -v $(pwd):/app -w /app node:18 /bin/bash -c "npm install && npm start")
check_error "Error iniciando el contenedor de Node.js."

# Mostrar la URL
echo "La aplicación está disponible en http://localhost:$FRONTEND_PORT"
