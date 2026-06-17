const CACHE_NAME = 'gestor-letsfood-v1';
const urlsToCache = [
  '/vendor/order/manager',
  '/css/app.css',
  '/js/app.js',
  '/logo.png'
];

// Instalação do Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache aberto');
        return cache.addAll(urlsToCache);
      })
  );
});

// Intercepta requisições
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Retorna do cache se encontrado, senão faz a requisição
        return response || fetch(event.request).then(fetchResponse => {
          // Adiciona a resposta ao cache
          return caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, fetchResponse.clone());
            return fetchResponse;
          });
        });
      })
  );
});

// Notificações push
self.addEventListener('push', event => {
  let data = {};
  if (event.data) {
    data = event.data.json();
  }
  
  const title = data.title || 'Novo pedido!';
  const options = {
    body: data.body || 'Você recebeu uma atualização',
    icon: '/logo.png',
    badge: '/logo.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url || '/vendor/order/manager'
    }
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Lidar com clique nas notificações
self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  const urlToOpen = event.notification.data.url || '/vendor/order/manager';
  
  event.waitUntil(
    clients.matchAll({type: 'window'})
      .then(windowClients => {
        // Verifica se já existe uma aba aberta
        for (let i = 0; i < windowClients.length; i++) {
          const client = windowClients[i];
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        // Se não encontrou, abre uma nova aba
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});