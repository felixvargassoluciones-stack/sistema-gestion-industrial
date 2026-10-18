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

  // Para listar e inspeccionar datos comúnmente usamos el método GET
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Método no permitido. Utiliza GET.' });
  }

  try {
    // Obtenemos los parámetros de filtro opcionales que envíe Flutter (ej. correo del cliente o rol)
    const { correo, rol } = req.query;

    let resultado;

    // LÓGICA DE FILTRADO DE SENIOR:
    // Si el rol es 'cliente', aplicamos un filtro estricto en SQL para que SOLO vea sus propios registros.
    // Si el rol es 'matriz', ejecutamos un SELECT general para que tenga acceso total a todo el sistema.
    if (rol === 'cliente' && correo) {
      resultado = await turso.execute({
        sql: 'SELECT * FROM requerimientos WHERE correo_cliente = ? ORDER BY fecha_creacion DESC',
        args: [correo],
      });
    } else {
      resultado = await turso.execute({
        sql: 'SELECT * FROM requerimientos ORDER BY fecha_creacion DESC',
      });
    }

    // Devolvemos el arreglo de filas plano que el FutureBuilder de Flutter transformará en tarjetas visuales
    return res.status(200).json({
      success: true,
      total_registros: resultado.rows.length,
      datos: resultado.rows,
    });

  } catch (error) {
    console.error('Error al listar requerimientos de Turso:', error);
    return res.status(500).json({ error: 'Error interno en el servidor al consultar los registros.' });
  }
}
