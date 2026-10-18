import { createClient } from '@libsql/client';

// Inicializamos el cliente de Turso usando las variables ocultas que guardamos en la web de Vercel
const turso = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

export default async function handler(req, res) {
  // Habilitamos CORS de forma segura solo para permitir peticiones HTTP
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Si el navegador hace una petición de control previa (OPTIONS), respondemos OK de inmediato
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Solo permitimos el método POST (enviar datos de login)
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido. Utiliza POST.' });
  }

  try {
    const { correo, password } = req.body;

    // Validación básica de campos vacíos
    if (!correo || !password) {
      return res.status(400).json({ error: 'Faltan campos obligatorios: correo o password.' });
    }

    // Consultamos de forma segura en Turso si existe el usuario por su correo
    const resultado = await turso.execute({
      sql: 'SELECT * FROM usuarios WHERE correo = ?',
      args: [correo],
    });

    // Si no encontró filas, el usuario no existe en el sistema
    if (resultado.rows.length === 0) {
      return res.status(401).json({ error: 'El correo electrónico o la contraseña son incorrectos.' });
    }

    const usuario = resultado.rows[0];

    // TODO: En producción cambiaremos esto por encriptación (bcrypt).
    // De momento compara el texto crudo para que puedas hacer pruebas rápidas de conexión.
    if (usuario.password_hash !== password) {
      return res.status(401).json({ error: 'El correo electrónico o la contraseña son incorrectos.' });
    }

    // Si todo coincide, le respondemos a Flutter con éxito y el rol que le toca ('matriz' o 'cliente')
    return res.status(200).json({
      success: true,
      mensaje: 'Acceso concedido',
      usuario: {
        id: usuario.id,
        correo: usuario.correo,
        rol: usuario.rol,
      },
    });

  } catch (error) {
    console.error('Error en el servidor de login:', error);
    return res.status(500).json({ error: 'Error interno en el servidor backend.' });
  }
}
