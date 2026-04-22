<!-- @format -->

# O que falta no backend para o Flutter funcionar

## Resumo rápido

O Flutter chama **2 rotas que não existem** no backend e espera **1 campo extra**
no `customer-products`. Tudo abaixo é para adicionar ao módulo `/api/3d`.

---

## 1. Model: CatalogItem (NOVO)

Criar `models/CatalogItem.js`:

```js
const mongoose = require("mongoose");

const catalogItemSchema = new mongoose.Schema(
  {
    categoryId: { type: String, required: true, index: true },
    title: { type: String, required: true },
    description: { type: String, default: "" },
    style: { type: String, default: "" },
    priceCents: { type: Number, required: true },
    imageTag: { type: String, default: "" },
  },
  { timestamps: true },
);

module.exports = mongoose.model("CatalogItem", catalogItemSchema);
```

---

## 2. Rota: GET /api/3d/catalog?categoryId=... (NOVA)

O Flutter chama `GET /catalog?categoryId=cat_keyring` e espera um array:

```json
[
  {
    "_id": "...",
    "categoryId": "cat_keyring",
    "title": "Chaveiro com nome",
    "description": "Nome em relevo, ate 10 letras.",
    "style": "Moderno",
    "priceCents": 1490,
    "imageTag": "key_name"
  }
]
```

Criar rota (ou adicionar ao router existente do módulo 3d):

```js
const CatalogItem = require("../models/CatalogItem");

// GET /api/3d/catalog?categoryId=cat_keyring
router.get("/catalog", async (req, res) => {
  try {
    const { categoryId } = req.query;
    const filter = categoryId ? { categoryId } : {};
    const items = await CatalogItem.find(filter).sort({ title: 1 });
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: "Erro ao buscar catalogo" });
  }
});
```

**Essa rota é pública** (sem token) — o cliente vê o catálogo antes de logar.

---

## 3. Rota: POST /api/3d/catalog (NOVA — admin)

Para o admin gerenciar itens do catálogo:

```js
// POST /api/3d/catalog (protegida)
router.post("/catalog", authMiddleware, async (req, res) => {
  try {
    const item = await CatalogItem.create(req.body);
    res.status(201).json(item);
  } catch (err) {
    res.status(400).json({ error: "Erro ao criar item do catalogo" });
  }
});

// PUT /api/3d/catalog/:id (protegida)
router.put("/catalog/:id", authMiddleware, async (req, res) => {
  try {
    const item = await CatalogItem.findByIdAndUpdate(req.id, req.body, {
      new: true,
    });
    if (!item) return res.status(404).json({ error: "Item nao encontrado" });
    res.json(item);
  } catch (err) {
    res.status(400).json({ error: "Erro ao atualizar item" });
  }
});

// DELETE /api/3d/catalog/:id (protegida)
router.delete("/catalog/:id", authMiddleware, async (req, res) => {
  try {
    await CatalogItem.findByIdAndDelete(req.params.id);
    res.status(204).end();
  } catch (err) {
    res.status(500).json({ error: "Erro ao remover item" });
  }
});
```

---

## 4. Seed de catálogo (opcional mas recomendado)

Script para popular o catálogo inicial. Rodar uma vez:

```js
// seeds/catalog.js
const mongoose = require("mongoose");
const CatalogItem = require("../models/CatalogItem");

const items = [
  // Chaveiros
  {
    categoryId: "cat_keyring",
    title: "Chaveiro com nome",
    description: "Nome em relevo, ate 10 letras.",
    style: "Moderno",
    priceCents: 1490,
    imageTag: "key_name",
  },
  {
    categoryId: "cat_keyring",
    title: "Chaveiro com logo",
    description: "Logo da empresa ou time.",
    style: "Corporativo",
    priceCents: 1890,
    imageTag: "key_logo",
  },
  {
    categoryId: "cat_keyring",
    title: "Chaveiro personagem",
    description: "Personagem simples estilizado.",
    style: "Divertido",
    priceCents: 2290,
    imageTag: "key_char",
  },
  // Miniaturas
  {
    categoryId: "cat_miniature",
    title: "Miniatura de personagem",
    description: "Boneco ate 15cm de altura.",
    style: "Detalhado",
    priceCents: 5990,
    imageTag: "mini_char",
  },
  {
    categoryId: "cat_miniature",
    title: "Peca de RPG/tabuleiro",
    description: "Miniaturas para jogos.",
    style: "Fantasia",
    priceCents: 3490,
    imageTag: "mini_rpg",
  },
  // Decoracao
  {
    categoryId: "cat_decor",
    title: "Vaso geometrico",
    description: "Vaso decorativo low-poly.",
    style: "Geometrico",
    priceCents: 4990,
    imageTag: "decor_vase",
  },
  {
    categoryId: "cat_decor",
    title: "Porta-retrato 3D",
    description: "Moldura com relevo tematico.",
    style: "Classico",
    priceCents: 3990,
    imageTag: "decor_frame",
  },
  // Placas e letreiros
  {
    categoryId: "cat_sign",
    title: "Letreiro de parede",
    description: "Nome ou frase em relevo.",
    style: "Moderno",
    priceCents: 6990,
    imageTag: "sign_wall",
  },
  {
    categoryId: "cat_sign",
    title: "Placa de porta",
    description: "Placa com nome e icone.",
    style: "Minimalista",
    priceCents: 3990,
    imageTag: "sign_door",
  },
  // Luminarias
  {
    categoryId: "cat_lamp",
    title: "Luminaria litofane",
    description: "Foto impressa em luz.",
    style: "Personalizado",
    priceCents: 7990,
    imageTag: "lamp_litho",
  },
  {
    categoryId: "cat_lamp",
    title: "Abajur geometrico",
    description: "Abajur com padrao vazado.",
    style: "Geometrico",
    priceCents: 5990,
    imageTag: "lamp_geo",
  },
];

async function seed(mongoUri) {
  await mongoose.connect(mongoUri);
  await CatalogItem.deleteMany({});
  await CatalogItem.insertMany(items);
  console.log(`${items.length} catalog items seeded.`);
  await mongoose.disconnect();
}

// Rodar: node seeds/catalog.js
const uri = process.env.MONGODB_URI || "mongodb://localhost:27017/meajuda3d";
seed(uri);
```

---

## 5. Atualizar customer-products para incluir as novas categorias

O Flutter agora espera 6 categorias com estes `id`s:

| id              | title              |
| --------------- | ------------------ |
| `cat_keyring`   | Chaveiros          |
| `cat_miniature` | Miniaturas         |
| `cat_decor`     | Decoracao          |
| `cat_sign`      | Placas e letreiros |
| `cat_lamp`      | Luminarias         |
| `cat_other`     | Outros             |

Se `GET /api/3d/customer-products` retorna dados estáticos no código, atualize
o array. Se vem do banco, atualize o seed. O Flutter espera estes campos:

```json
{
  "id": "cat_keyring",
  "title": "Chaveiros",
  "description": "Chaveiros personalizados com nome, logo ou personagem.",
  "icon": "key",
  "examples": ["brinde", "nome", "logo", "evento"],
  "fromPriceCents": 1290,
  "needsImage": false
}
```

Os `icon` possíveis: `key`, `miniature`, `decor`, `frame`, `lamp`, `other`.

---

## Checklist final — rotas que o Flutter chama

| Rota                          | Método | Existe?      | Obs                  |
| ----------------------------- | ------ | ------------ | -------------------- |
| `/customer-products`          | GET    | ✅           | Atualizar categorias |
| `/customer-orders?email=`     | GET    | ✅           |                      |
| `/customer-orders`            | POST   | ✅           |                      |
| `/customer-orders/:id/status` | PATCH  | ✅           |                      |
| `/catalog?categoryId=`        | GET    | ❌ **CRIAR** | Pública              |
| `/catalog`                    | POST   | ❌ **CRIAR** | Admin                |
| `/catalog/:id`                | PUT    | ❌ **CRIAR** | Admin                |
| `/catalog/:id`                | DELETE | ❌ **CRIAR** | Admin                |
| `/dashboard`                  | GET    | ✅           |                      |
| `/clients`                    | GET    | ✅           |                      |
| `/clients`                    | POST   | ✅           |                      |
| `/materials`                  | GET    | ✅           |                      |
| `/materials`                  | POST   | ✅           |                      |
| `/materials/:id`              | PATCH  | ✅           |                      |
| `/quotes`                     | GET    | ✅           |                      |
| `/templates`                  | GET    | ✅           |                      |
| `/jobs`                       | GET    | ✅           |                      |
| `/jobs/:id/status`            | PATCH  | ✅           |                      |
| `/supplies`                   | GET    | ✅           |                      |
| `/search?q=`                  | GET    | ✅           |                      |
| `/notifications`              | GET    | ✅           |                      |
