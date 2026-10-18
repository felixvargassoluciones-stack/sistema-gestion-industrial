import { createClient } from '@libsql/client';

// Conexión segura a Turso usando las variables ocultas de Vercel
const turso = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

export default async function handler(req, res) {
  // Encabezados de CORS para permitir la conexión desde GitHub Pages
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Respuesta rápida para peticiones OPTIONS del navegador
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Restringimos la ruta para que solo acepte inserciones de datos (POST)
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido. Utiliza POST.' });
  }

  try {
    // Desestructuramos los campos que enviará el formulario de Flutter Web
    const { id, titulo, descripcion, ubicacion, prioridad, correo_cliente, url_imagen } = req.body;

    // Validación estricta de campos requeridos en el sistema de gestión
    if (!id || !titulo || !descripcion || !ubicacion || !prioridad || !correo_cliente) {
      return res.status(400).json({ error: 'Faltan campos obligatorios para registrar el requerimiento.' });
    }

    // Insertamos la fila directamente en la tabla de Turso
    await turso.execute({
      sql: `INSERT INTO requerimientos (
              id, titulo, descripcion, ubicacion, prioridad, correo_cliente, url_imagen
            ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      args: [id, titulo, descripcion, ubicacion, prioridad, correo_cliente, url_imagen || ''],
    });

    // Respondemos con éxito a la aplicación de Flutter
    return res.status(201).json({
      success: true,
      mensaje: 'Requerimiento industrial registrado con éxito en la base de datos.'
    });

  } catch (error) {
    console.error('Error al insertar requerimiento en Turso:', error);
    return res.status(500).json({ error: 'Error interno en el servidor al guardar el reporte.' });
  }
}
