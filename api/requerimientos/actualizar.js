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

  // Para actualizar registros parciales en APIs REST el estándar es usar el método PUT o PATCH
  if (req.method !== 'PUT') {
    return res.status(405).json({ error: 'Método no permitido. Utiliza PUT.' });
  }

  try {
    // Desestructuramos los campos que enviará la pantalla de Matriz desde Flutter
    const { id, estado, comentario_matiz } = req.body;

    // Validación básica: necesitamos obligatoriamente saber qué registro modificar e ingresar los nuevos datos
    if (!id || !estado) {
      return res.status(400).json({ error: 'Faltan campos obligatorios: id y estado son requeridos.' });
    }

    // Ejecutamos el UPDATE en Turso de manera segura mediante parámetros estructurados
    const resultado = await turso.execute({
      sql: `UPDATE requerimientos 
            SET estado = ?, comentario_matriz = ? 
            WHERE id = ?`,
      args: [estado, comentario_matiz || '', id],
    });

    // Validamos si efectivamente la base de datos encontró esa fila para modificar
    if (resultado.rowsAffected === 0) {
      return res.status(404).json({ error: 'No se encontró ningún requerimiento con el ID proporcionado.' });
    }

    // Respondemos con éxito
    return res.status(200).json({
      success: true,
      mensaje: 'El estado del requerimiento industrial ha sido actualizado correctamente.'
    });

  } catch (error) {
    console.error('Error al actualizar requerimiento en Turso:', error);
    return res.status(500).json({ error: 'Error interno en el servidor al intentar modificar el reporte.' });
  }
}
