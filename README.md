# Turbo Entregas

Plataforma de entregas de parcelas composta por tres aplicacoes integradas: um aplicativo para clientes, um aplicativo para entregadores e um painel administrativo com API REST.

O projeto e baseado no 6amMart (CodeCanyon) e foi extensivamente customizado para operar como servico de entrega de parcelas sob a marca Turbo Entregas.

---

## Estrutura do Repositorio

```
TURBOENTREGACOMPLETO/
├── Cliente/          # App Flutter — cliente final
├── Entregador/       # App Flutter — entregador (motoboy)
├── Painel_API/       # Backend Laravel 10 — painel admin + API REST
└── documentacao/     # Documentacao auxiliar
```

---

## Cliente (`Cliente/`)

Aplicativo Flutter voltado ao usuario final que solicita entregas de parcelas.

**Stack:** Flutter (Dart), GetX (state management + DI + routing), Google Maps Flutter, Firebase (push notifications, analytics).

**Funcionalidades principais:**
- Cadastro e autenticacao (email, telefone, login social via Facebook/Google)
- Solicitacao de entregas com selecao de endereco via Google Places
- Rastreamento de pedidos em tempo real no mapa
- Historico de pedidos e avaliacoes
- Carteira digital e sistema de cupons
- Chat com entregador e suporte
- Notificacoes push via Firebase Cloud Messaging
- Interface web responsiva (Flutter web)

**Estrutura interna:**
```
Cliente/lib/
├── common/           # Widgets e modelos compartilhados
├── features/         # Modulos de funcionalidade (parcel, auth, order, location, etc.)
├── helper/           # Utilitarios, rotas, notificacoes
├── theme/            # Temas claro e escuro
└── util/             # Constantes, imagens, mensagens
```

Cada modulo em `features/` segue a arquitetura: `controllers/`, `domain/` (models, repositories, services), `screens/` e `widgets/`.

---

## Entregador (`Entregador/`)

Aplicativo Flutter voltado ao motoboy que realiza as entregas.

**Stack:** Flutter (Dart), GetX, Google Maps Flutter, Firebase, Flutter Foreground Task.

**Funcionalidades principais:**
- Login e gestao de perfil do entregador
- Recepcao de pedidos com notificacao sonora e push
- Navegacao ate o endereco de coleta e entrega via mapa
- Atualizacao de status do pedido em tempo real
- Servico em foreground para rastreamento continuo de localizacao (Android)
- Chat com cliente e administracao
- Historico de corridas e ganhos

**Estrutura interna:**
```
Entregador/lib/
├── common/           # Widgets e modelos compartilhados
├── features/         # Modulos (order, auth, dashboard, chat, etc.)
├── helper/           # Rotas, notificacoes, DI, foreground service
├── theme/            # Temas claro e escuro
└── util/             # Constantes e imagens
```

---

## Painel Admin e API (`Painel_API/`)

Backend em Laravel 10 que serve tanto o painel administrativo web quanto a API REST consumida pelos aplicativos.

**Stack:** PHP 8.2, Laravel 10, MySQL/MariaDB, Blade (views do admin), Firebase Admin SDK.

**API REST** (`/api/v1/`):
- Autenticacao e gestao de usuarios (clientes e entregadores)
- CRUD de categorias, itens, lojas, banners e campanhas
- Gestao de pedidos com fluxo completo (criacao, atribuicao, rastreamento, conclusao)
- Google Places (autocomplete e detalhes de endereco via proxy server-side)
- Notificacoes push via Firebase
- Carteira, cupons, cashback e programa de fidelidade
- Configuracao dinamica da plataforma (`/api/v1/config`)
- Estatisticas da plataforma (`/api/v1/platform/statistics`)

**Painel Administrativo:**
- Dashboard com metricas de operacao
- Gestao de entregadores, clientes e zonas de entrega
- Configuracao de modulos, pagamentos e integracoes
- Gestao de conteudo (banners, campanhas, landing page)
- Relatorios e exportacoes

**Estrutura interna:**
```
Painel_API/
├── app/
│   ├── Http/Controllers/
│   │   ├── Admin/        # Controllers do painel administrativo
│   │   └── Api/V1/       # Controllers da API REST
│   ├── Models/           # Eloquent models
│   ├── CentralLogics/    # Helpers e logica de negocio compartilhada
│   └── Providers/        # Service providers (Firebase, etc.)
├── config/               # Configuracoes do Laravel
├── database/             # Migrations e seeders
├── resources/views/      # Templates Blade do admin
├── routes/               # Definicao de rotas (api.php, admin.php)
├── public/               # Assets publicos e build do Flutter web
└── storage/              # Logs, cache e arquivos temporarios
```

---

## Configuracao do Ambiente

### Pre-requisitos

- Flutter SDK (>= 3.27)
- PHP 8.2 com extensoes necessarias para Laravel 10
- MySQL ou MariaDB
- Composer
- Conta Firebase com projeto configurado
- Chave de API do Google Maps (com Geocoding, Places e Maps SDK habilitados)

### Credenciais e API Keys

Este repositorio nao contem chaves de API. Antes de compilar ou executar, configure as seguintes credenciais nos locais indicados:

| Credencial | Arquivos |
|---|---|
| Google Maps API Key | `Cliente/android/app/src/main/AndroidManifest.xml`, `Entregador/android/app/src/main/AndroidManifest.xml`, `Cliente/ios/Runner/AppDelegate.swift`, `Entregador/ios/Runner/AppDelegate.swift`, `Cliente/web/index.html`, `Cliente/lib/features/location/domain/services/location_service.dart` |
| Firebase Config | `Cliente/lib/main.dart`, `Entregador/lib/main.dart`, `*/web/firebase-messaging-sw.js` |
| Firebase Services | `Cliente/android/app/google-services.json`, `Entregador/android/app/google-services.json`, `Cliente/ios/GoogleService-Info.plist`, `Entregador/ios/GoogleService-Info.plist` |
| Facebook App ID | `Cliente/android/app/src/main/res/values/strings.xml`, `Entregador/android/app/src/main/res/values/strings.xml`, `Cliente/ios/Runner/Info.plist`, `Cliente/lib/main.dart` |
| Google Maps (server) | `Painel_API/.env` (variavel `GOOGLE_MAPS_API_KEY`) |

Os arquivos `google-services.json` e `GoogleService-Info.plist` devem ser obtidos no console do Firebase e colocados nos diretorios indicados acima. Eles estao no `.gitignore` e nao sao versionados.

### Backend (Laravel)

```bash
cd Painel_API
cp .env.example .env
# Editar .env com credenciais do banco, Firebase e Google Maps
composer install
php artisan key:generate
php artisan migrate
php artisan serve --port=8005
```

### Cliente Flutter

```bash
cd Cliente
flutter pub get
flutter run -d chrome --web-port=7878
```

### Entregador Flutter

```bash
cd Entregador
flutter pub get
flutter run
```

---

## Producao

- **API e Painel:** https://producao.turboentregas.com.br
- **App Cliente (web):** https://cliente.turboentregas.com.br
- **App Cliente (Android):** [Google Play](https://play.google.com/store/apps/details?id=com.turboentregas.cliente)
- **App Entregador (Android):** [Google Play](https://play.google.com/store/apps/details?id=com.turboentregasv3.motoboy)

---

## Licenca

Projeto proprietario baseado em licenca TurboEntregas. Uso restrito conforme termos da licenca original.
