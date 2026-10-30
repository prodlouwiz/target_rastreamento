export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);

  // Redireciona para o servidor do Pilot GPS
  const targetUrl = 'https://global.pilot-gps.com' + url.pathname + url.search;

  // Trata preflight CORS (OPTIONS)
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  // Prepara headers da requisição para o Pilot GPS
  const reqHeaders = new Headers(request.headers);
  reqHeaders.set('Host', 'global.pilot-gps.com');
  reqHeaders.delete('origin');
  reqHeaders.delete('referer');

  const proxyRequest = new Request(targetUrl, {
    method: request.method,
    headers: reqHeaders,
    body: request.method !== 'GET' && request.method !== 'HEAD' ? await request.arrayBuffer() : null,
    redirect: 'follow',
  });

  try {
    const response = await fetch(proxyRequest);
    const resHeaders = new Headers(response.headers);
    resHeaders.set('Access-Control-Allow-Origin', '*');
    resHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
    resHeaders.set('Access-Control-Allow-Headers', '*');

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: resHeaders,
    });
  } catch (err) {
    return new Response(JSON.stringify({ code: -1, msg: 'Erro no proxy Pilot: ' + err.message }), {
      status: 502,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
}

