<!-- @format -->

# Me Ajuda em 3D

App Flutter para gestao operacional de impressao 3D.

## Funcionalidades

- Cockpit com indicadores de orcamentos, producao, retirada, estoque baixo e prazos.
- Visao do cliente para criar pedido sem login e consultar pedidos abertos por email.
- Produtos base para pedido: chaveiro personalizado, decoracao, quadro/placa,
  pedido por imagem e outros com campo aberto.
- Materiais com filamentos, insumos e baixo estoque.
- Orcamentos com editor visual em dois modos: rapido e real.
- Producao em secoes de fila, imprimindo, acabamento e pronto.
- Clientes com busca, status atual e ultimo orcamento.
- Calculadora 3D para simular custos e precos.

## Arquitetura

- `lib/app`: bootstrap, tema e shell de navegacao.
- `lib/core`: modelos, formatadores, regras puras e componentes compartilhados.
- `lib/data`: contrato de repositorio e implementacao HTTP (`ApiOperationRepository`).
- `lib/features`: telas por area do produto.

Widgets nao calculam preco nem reordenam fila. Essas regras ficam em
`lib/core/business_rules.dart`.

## Backend

A API roda em repositorio separado: **me-ajuda-em-3d-api**.
Deploy recomendado no Railway conectando ao MongoDB Atlas.

## Como rodar

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Para producao, aponte para a URL do Railway:

```bash
flutter run --dart-define=API_BASE_URL=https://sua-api.up.railway.app
```
