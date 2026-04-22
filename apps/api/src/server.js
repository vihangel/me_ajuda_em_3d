import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import multer from 'multer';
import { ObjectId } from 'mongodb';
import { getDb } from './db.js';

const app = express();
const upload = multer({ dest: 'uploads/' });
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use('/uploads', express.static('uploads'));

function code(prefix) {
  return `${prefix}-${Date.now().toString().slice(-6)}`;
}

app.get('/health', (_, res) => res.json({ ok: true }));

app.get('/customer-products', (_, res) => {
  res.json([
    { id: 'keyring', title: 'Chaveiro personalizado', fromPriceCents: 1290, needsImage: false },
    { id: 'decor', title: 'Encomenda decoracao', fromPriceCents: 3490, needsImage: false },
    { id: 'frame', title: 'Quadro ou placa', fromPriceCents: 5990, needsImage: false },
    { id: 'image', title: 'Pedido com base em imagem', fromPriceCents: 4590, needsImage: true },
    { id: 'other', title: 'Outros', fromPriceCents: 2990, needsImage: false }
  ]);
});

app.get('/customer-orders', async (req, res, next) => {
  try {
    const db = await getDb();
    const email = String(req.query.email || '').trim().toLowerCase();
    const filter = email ? { email } : {};
    const orders = await db.collection('customer_orders')
      .find(filter)
      .sort({ createdAt: -1 })
      .limit(100)
      .toArray();
    res.json(orders);
  } catch (error) {
    next(error);
  }
});

app.post('/customer-orders', async (req, res, next) => {
  try {
    const db = await getDb();
    const now = new Date();
    const order = {
      code: code('PED'),
      customerName: req.body.customerName,
      email: String(req.body.email || '').trim().toLowerCase(),
      phone: req.body.phone,
      kind: req.body.kind || 'person',
      productTitle: req.body.productTitle,
      description: req.body.description,
      quantity: Number(req.body.quantity || 1),
      hasReferenceImage: Boolean(req.body.hasReferenceImage),
      status: 'received',
      createdAt: now,
      updatedAt: now
    };
    const result = await db.collection('customer_orders').insertOne(order);
    res.status(201).json({ ...order, _id: result.insertedId });
  } catch (error) {
    next(error);
  }
});

app.post('/uploads', upload.single('file'), async (req, res, next) => {
  try {
    const db = await getDb();
    const doc = {
      orderId: req.body.orderId ? new ObjectId(req.body.orderId) : null,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      url: `${process.env.PUBLIC_BASE_URL || ''}/${req.file.path}`,
      createdAt: new Date()
    };
    const result = await db.collection('uploads').insertOne(doc);
    res.status(201).json({ ...doc, _id: result.insertedId });
  } catch (error) {
    next(error);
  }
});

app.get('/clients', async (_, res, next) => {
  try {
    const db = await getDb();
    res.json(await db.collection('clients').find().sort({ createdAt: -1 }).toArray());
  } catch (error) {
    next(error);
  }
});

app.post('/clients', async (req, res, next) => {
  try {
    const db = await getDb();
    const client = { ...req.body, isActive: true, createdAt: new Date() };
    const result = await db.collection('clients').insertOne(client);
    res.status(201).json({ ...client, _id: result.insertedId });
  } catch (error) {
    next(error);
  }
});

app.get('/materials', async (_, res, next) => {
  try {
    const db = await getDb();
    res.json(await db.collection('materials').find().sort({ createdAt: -1 }).toArray());
  } catch (error) {
    next(error);
  }
});

app.post('/materials', async (req, res, next) => {
  try {
    const db = await getDb();
    const material = { ...req.body, createdAt: new Date() };
    const result = await db.collection('materials').insertOne(material);
    res.status(201).json({ ...material, _id: result.insertedId });
  } catch (error) {
    next(error);
  }
});

app.get('/search', async (req, res, next) => {
  try {
    const db = await getDb();
    const q = String(req.query.q || '').trim();
    if (!q) return res.json([]);
    const regex = new RegExp(q, 'i');
    const [orders, clients, materials] = await Promise.all([
      db.collection('customer_orders').find({ $or: [{ code: regex }, { customerName: regex }, { productTitle: regex }] }).limit(5).toArray(),
      db.collection('clients').find({ $or: [{ name: regex }, { phone: regex }, { channel: regex }] }).limit(5).toArray(),
      db.collection('materials').find({ $or: [{ brand: regex }, { material: regex }, { colorName: regex }] }).limit(5).toArray()
    ]);
    res.json({ orders, clients, materials });
  } catch (error) {
    next(error);
  }
});

app.get('/notifications', async (_, res, next) => {
  try {
    const db = await getDb();
    const lowMaterials = await db.collection('materials')
      .find({ $expr: { $lte: ['$remainingGrams', '$lowStockGrams'] } })
      .limit(20)
      .toArray();
    res.json(lowMaterials.map((item) => ({
      title: 'Material baixo',
      message: `${item.material} ${item.colorName || ''}`.trim(),
      severity: 'warning'
    })));
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(500).json({ error: error.message || 'Internal error' });
});

app.listen(port, () => {
  console.log(`API listening on :${port}`);
});
