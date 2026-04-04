const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const cors = require('cors');
const axios = require('axios');
const path = require('path');
const { execFile } = require('child_process');

// 指定 Python 解释器，避免系统 PATH 命中到无依赖环境
const PYTHON_BIN = process.env.PYTHON_BIN || 'E:\\anaconda3\\python.exe';
const fs = require('fs');
const multer = require('multer');

// DeepSeek API 配置
const DEEPSEEK_API_KEY = 'sk-cf29ab77b9ef4d3089a975b1be8fd0ae';
const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json());

const fishCountingRoot = path.resolve(__dirname, '../fish-counting');
const fishResultsDir = path.join(fishCountingRoot, 'results');
const fishUploadsDir = path.join(fishCountingRoot, 'uploads');

fs.mkdirSync(fishResultsDir, { recursive: true });
fs.mkdirSync(fishUploadsDir, { recursive: true });

app.use('/api/fish/recognition/files', express.static(fishResultsDir));

const upload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, fishUploadsDir),
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname || '').toLowerCase();
      cb(null, `upload_${Date.now()}${ext}`);
    }
  }),
  limits: { fileSize: 200 * 1024 * 1024 }
});

const config = {
  sensorAPIAddress: 'SensorAPIAdress001',
  port: 3000
};

function generateSensorData() {
  return {
    timestamp: new Date().toISOString(),
    temperature: (18 + Math.random() * 8).toFixed(2),
    ph: (7.5 + Math.random() * 1).toFixed(2),
    dissolvedOxygen: (6 + Math.random() * 3).toFixed(2),
    salinity: (30 + Math.random() * 5).toFixed(2),
    turbidity: (2 + Math.random() * 3).toFixed(2)
  };
}

function generateFishDistribution() {
  return [
    { name: '大黄鱼', value: Math.floor(1200 + Math.random() * 300) },
    { name: '石斑鱼', value: Math.floor(800 + Math.random() * 200) },
    { name: '鲈鱼', value: Math.floor(1500 + Math.random() * 400) },
    { name: '海鲈', value: Math.floor(600 + Math.random() * 150) },
    { name: '其他', value: Math.floor(400 + Math.random() * 100) }
  ];
}

function generateHydroData() {
  return {
    timestamp: new Date().toISOString(),
    wave: {
      height: (0.5 + Math.random() * 2).toFixed(2),
      period: (4 + Math.random() * 3).toFixed(1),
      direction: Math.floor(Math.random() * 360)
    },
    current: {
      speed: (0.2 + Math.random() * 0.8).toFixed(2),
      direction: Math.floor(Math.random() * 360),
      depth: 10
    },
    tide: {
      level: (2.5 + Math.sin(Date.now() / 60000) * 1.5).toFixed(2),
      trend: Math.sin(Date.now() / 60000) > 0 ? '涨潮' : '落潮'
    },
    wind: {
      speed: (2 + Math.random() * 8).toFixed(1),
      direction: Math.floor(Math.random() * 360),
      level: Math.floor(2 + Math.random() * 4)
    },
    light: {
      intensity: Math.floor(300 + Math.random() * 800),
      uv: (2 + Math.random() * 8).toFixed(1)
    }
  };
}

function generateTideHistory() {
  const data = [];
  const now = Date.now();
  for (let i = 23; i >= 0; i--) {
    const time = new Date(now - i * 3600000);
    const hour = time.getHours();
    const tideLevel = 2.5 + 1.5 * Math.sin((hour * Math.PI) / 6);
    data.push({
      time: `${hour.toString().padStart(2, '0')}:00`,
      level: tideLevel.toFixed(2)
    });
  }
  return data;
}

function generateWindRose() {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return directions.map(dir => ({
    direction: dir,
    frequency: Math.floor(5 + Math.random() * 20)
  }));
}

let historyData = {
  temperature: [],
  ph: [],
  dissolvedOxygen: [],
  timestamps: []
};

const MAX_HISTORY = 50;

app.get('/api/sensor/current', (req, res) => {
  res.json({ success: true, data: generateSensorData(), source: config.sensorAPIAddress });
});

app.get('/api/sensor/history', (req, res) => {
  res.json({ success: true, data: historyData });
});

app.get('/api/fish/distribution', (req, res) => {
  res.json({ success: true, data: generateFishDistribution() });
});

app.get('/api/ranch/location', (req, res) => {
  res.json({
    success: true,
    data: {
      name: '海陵岛智慧海洋牧场',
      longitude: 111.9,
      latitude: 21.6,
      description: '位于广东省阳江市海陵岛附近海域的现代化海洋牧场',
      area: '500公顷',
      depth: '15-30米'
    }
  });
});

app.get('/api/hydro/current', (req, res) => {
  res.json({ success: true, data: generateHydroData(), source: config.sensorAPIAddress });
});

app.get('/api/hydro/tide-history', (req, res) => {
  res.json({ success: true, data: generateTideHistory() });
});

app.get('/api/hydro/wind-rose', (req, res) => {
  res.json({ success: true, data: generateWindRose() });
});

function runFishDetection({ source, model = 'pt/best.pt', conf = 0.5, iou = 0.5, save = true }, callback) {
  const sourcePath = path.isAbsolute(source) ? source : path.join(fishCountingRoot, source);
  const modelPath = path.isAbsolute(model) ? model : path.join(fishCountingRoot, model);
  const scriptPath = path.join(fishCountingRoot, 'models', 'yolov8_demo.py');

  const args = [
    scriptPath,
    '--model', modelPath,
    '--source', sourcePath,
    '--conf', String(conf),
    '--iou', String(iou),
    '--json'
  ];

  if (save) {
    args.push('--save', '--output', fishResultsDir);
  }

  execFile(PYTHON_BIN, args, { cwd: fishCountingRoot, timeout: 300000 }, (error, stdout, stderr) => {
    if (error) {
      callback({
        status: 500,
        body: {
          success: false,
          error: '鱼类识别调用失败',
          detail: error.message,
          stderr: String(stderr || '')
        }
      });
      return;
    }

    const text = String(stdout || '').trim();
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');

    if (start < 0 || end <= start) {
      callback({
        status: 500,
        body: {
          success: false,
          error: '识别结果解析失败',
          stdout: text,
          stderr: String(stderr || '')
        }
      });
      return;
    }

    try {
      const parsed = JSON.parse(text.slice(start, end + 1));
      const data = parsed.data || {};
      const annotatedImageUrl = data.annotatedImage
        ? `/api/fish/recognition/files/${path.basename(data.annotatedImage)}`
        : null;
      const outputVideoUrl = data.outputVideo
        ? `/api/fish/recognition/files/${path.basename(data.outputVideo)}`
        : null;

      callback(null, {
        success: true,
        data: {
          ...data,
          annotatedImageUrl,
          outputVideoUrl
        }
      });
    } catch (e) {
      callback({
        status: 500,
        body: {
          success: false,
          error: '识别结果JSON解析失败',
          detail: e.message,
          stdout: text,
          stderr: String(stderr || '')
        }
      });
    }
  });
}

app.post('/api/fish/recognition/detect', (req, res) => {
  const { source = 'testdata/CS_videoplayback014.png', model = 'pt/best.pt', conf = 0.5, iou = 0.5, save = true } = req.body || {};
  runFishDetection({ source, model, conf, iou, save }, (err, result) => {
    if (err) return res.status(err.status).json(err.body);
    return res.json(result);
  });
});

app.post('/api/fish/recognition/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: '请上传图片或视频文件' });
  }

  const ext = path.extname(req.file.originalname || '').toLowerCase();
  const allowed = ['.jpg', '.jpeg', '.png', '.bmp', '.webp', '.mp4', '.avi', '.mov', '.mkv'];

  if (!allowed.includes(ext)) {
    fs.unlink(req.file.path, () => {});
    return res.status(400).json({ success: false, error: '仅支持图片和视频文件（jpg/png/mp4/avi/mov/mkv）' });
  }

  const { model = 'pt/best.pt', conf = 0.5, iou = 0.5, save = true } = req.body || {};

  runFishDetection({ source: req.file.path, model, conf, iou, save }, (err, result) => {
    fs.unlink(req.file.path, () => {});
    if (err) return res.status(err.status).json(err.body);
    return res.json(result);
  });
});

app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, context } = req.body;

    if (!message) {
      return res.status(400).json({ success: false, error: '消息不能为空' });
    }

    const systemPrompt = `你是一个专业的海洋牧场管理助手，精通水产养殖、海洋环境监测和数据分析。\n\n当前环境数据：\n${context && context.sensorData ? `\n- 水温：${context.sensorData.temperature}°C\n- pH值：${context.sensorData.ph}\n- 溶氧量：${context.sensorData.dissolvedOxygen}mg/L\n- 盐度：${context.sensorData.salinity}ppt\n- 浊度：${context.sensorData.turbidity}NTU\n` : '暂无环境数据'}\n\n请用简洁、专业、友好的语气回答问题。`;

    const response = await axios.post(
      DEEPSEEK_API_URL,
      {
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        temperature: 0.7,
        max_tokens: 2000
      },
      {
        headers: {
          Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    res.json({ success: true, reply: response.data.choices[0].message.content, analysis: null, suggestions: [], usage: response.data.usage });
  } catch (error) {
    res.json({ success: true, reply: '抱歉，我现在遇到了一些问题，请稍后再试。', analysis: null, suggestions: [] });
  }
});

io.on('connection', (socket) => {
  const sensorInterval = setInterval(() => {
    const data = generateSensorData();

    historyData.timestamps.push(new Date().toLocaleTimeString());
    historyData.temperature.push(parseFloat(data.temperature));
    historyData.ph.push(parseFloat(data.ph));
    historyData.dissolvedOxygen.push(parseFloat(data.dissolvedOxygen));

    if (historyData.timestamps.length > MAX_HISTORY) {
      historyData.timestamps.shift();
      historyData.temperature.shift();
      historyData.ph.shift();
      historyData.dissolvedOxygen.shift();
    }

    socket.emit('sensorData', data);
  }, 3000);

  const fishInterval = setInterval(() => {
    socket.emit('fishDistribution', generateFishDistribution());
  }, 10000);

  const hydroInterval = setInterval(() => {
    socket.emit('hydroData', generateHydroData());
  }, 5000);

  socket.emit('sensorData', generateSensorData());
  socket.emit('fishDistribution', generateFishDistribution());
  socket.emit('hydroData', generateHydroData());

  socket.on('disconnect', () => {
    clearInterval(sensorInterval);
    clearInterval(fishInterval);
    clearInterval(hydroInterval);
  });
});

server.listen(config.port, () => {
  console.log(`=============================================`);
  console.log(`🌊 智慧海洋牧场可视化平台后端服务`);
  console.log(`📡 HTTP服务: http://localhost:${config.port}`);
  console.log(`🔌 WebSocket服务: ws://localhost:${config.port}`);
  console.log(`🐟 鱼类识别接口: http://localhost:${config.port}/api/fish/recognition/detect`);
  console.log(`=============================================`);
});
