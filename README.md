<!-- @format -->

# Me Ajuda em 3D

App Flutter mobile para gestao operacional de impressao 3D.

## Recorte atual

- Cockpit com indicadores de orcamentos, producao, retirada, estoque baixo e prazos.
- Visao do cliente para criar pedido sem login e consultar pedidos abertos por email.
- Produtos base para pedido: chaveiro personalizado, decoracao, quadro/placa,
  pedido por imagem e outros com campo aberto.
- Materiais com filamentos, insumos e baixo estoque.
- Orcamentos com editor visual em dois modos: rapido e real.
- Producao em secoes de fila, imprimindo, acabamento e pronto.
- Clientes com busca, status atual e ultimo orcamento.
- Configuracoes basicas de custo, prazo, taxa e mensagem padrao.

Tudo usa dados fake em memoria por enquanto. A UI ja conversa com um
`OperationRepository`, entao a troca para backend fica concentrada na camada
`data`.

## Arquitetura

- `lib/app`: bootstrap, tema e shell de navegacao.
- `lib/core`: modelos, formatadores, regras puras e componentes compartilhados.
- `lib/data`: contrato de repositorio e implementacao fake.
- `lib/features`: telas por area do produto.

Widgets nao calculam preco nem reordenam fila. Essas regras ficam em
`lib/core/business_rules.dart`.

## MongoDB + Railway

O caminho recomendado para a integracao e:

1. Criar uma API no Railway, por exemplo Node/Nest, Express ou Dart Shelf.
2. Conectar essa API ao MongoDB Atlas usando variaveis de ambiente no Railway.
3. Expor endpoints por modulo: clients, materials, quotes, jobs e settings.
4. Implementar um `ApiOperationRepository` no Flutter usando HTTP.
5. Manter segredo, string de conexao e Mercado Pago apenas no servidor.

O app Flutter deve receber somente JSON da API. Ele nao deve conectar direto no
MongoDB.

## Endpoints da API

### Rota publica (cliente)

- `GET /customer-products` — lista produtos base
- `POST /customer-orders` — cria pedido
- `GET /customer-orders?email=...` — consulta pedidos por email

### Admin

- `GET /dashboard` — resumo (orcamentos, producao, estoque, prazos)
- `GET /materials` / `POST /materials` / `PATCH /materials/:id`
- `GET /supplies` / `POST /supplies`
- `GET /quotes` / `POST /quotes`
- `GET /templates`
- `GET /jobs` / `POST /jobs` / `PATCH /jobs/:id/status`
- `GET /clients` / `POST /clients`
- `PATCH /customer-orders/:id/status`
- `GET /search?q=...`
- `GET /notifications`
- `POST /uploads` (multipart)

## Como rodar

```bash
# API
cd apps/api
cp .env.example .env   # configure MONGODB_URI
npm install
npm run dev

# Flutter (com URL da API)
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```
