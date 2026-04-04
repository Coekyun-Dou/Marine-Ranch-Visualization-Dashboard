# 🌊 智慧海洋牧场可视化平台

## 项目简介

这是一个面向大学生计算机设计大赛数据可视化赛道的智慧海洋牧场综合可视化平台。项目通过现代化的Web技术实现海洋牧场的实时监控、数据分析和三维可视化展示。

## ✨ 核心功能

### 1. 🔐 登录系统
- 精美的登录界面设计
- 动态海浪背景动画
- 演示账号：admin / 123456
- 路由守卫保护

### 2. 🗺️ 多页面导航
- **综合监控**：整体数据概览、3D地球、实时监控
- **水质监控**：专业的水质数据分析和可视化
- **鱼群监控**：实时摄像头监控和AI分析

### 3. 🌏 3D地球可视化
- 基于Cesium的三维地球展示
- 实时标注海洋牧场位置
- 养殖网箱可视化
- 动态水波效果
- 地理信息叠加显示

### 4. 📹 视频监控系统
- **真实摄像头接入**：使用电脑摄像头模拟水下监控
- 实时视频流展示
- 截图功能
- 镜像模式
- 多摄像头切换
- 鱼类数量智能统计
- 网箱健康状态检测

### 5. 📊 数据实时分析
- **改进的数据卡片**：带图标和状态指示
  - 🌡️ 水温（红色图标）
  - 🧪 pH值（青色图标）
  - 💨 溶氧量（蓝色图标）
- 实时采集环境数据（通过传感器API）
- 折线图实时展示环境参数趋势
- 迷你趋势图
- 数据统计表格

### 6. 🐟 鱼类分布统计
- 饼图展示不同鱼类分布
- 实时更新养殖数据
- 数量统计与占比分析

### 7. 🤖 AI智能分析（模拟）
- 鱼类行为分析
- 活动区域热力图
- 历史趋势分析

## 🛠️ 技术栈

### 前端技术
| 技术 | 版本 | 用途 |
|------|------|------|
| Vue.js | 3.3.4 | 前端框架 |
| Vue Router | 4.2.5 | 路由管理 |
| Element Plus | 2.4.0 | UI组件库 |
| Element Plus Icons | 2.3.1 | 图标库 |
| ECharts | 5.4.3 | 数据可视化图表 |
| Cesium | 1.110.0 | 3D地球可视化 |
| Socket.IO Client | 4.6.1 | 实时数据通信 |
| Vite | 4.5.0 | 构建工具 |

### 后端技术
| 技术 | 版本 | 用途 |
|------|------|------|
| Node.js | - | 运行环境 |
| Express | 4.18.2 | Web服务框架 |
| Socket.IO | 4.6.1 | WebSocket实时通信 |
| Axios | 1.6.0 | HTTP客户端 |

## 📁 项目结构

```
Marine-Ranch/
├── backend/                  # 后端服务
│   ├── server.js            # Express + Socket.IO 服务器
│   ├── package.json         # 后端依赖配置
│   └── .gitignore
├── frontend/                 # 前端应用
│   ├── src/
│   │   ├── views/           # 页面组件
│   │   │   ├── Login.vue           # 登录页面
│   │   │   ├── Dashboard.vue       # 综合监控主页
│   │   │   ├── WaterQuality.vue    # 水质监控页面
│   │   │   └── FishMonitor.vue     # 鱼群监控页面
│   │   ├── components/      # 公共组件
│   │   │   ├── CesiumViewer.vue      # 3D地球组件
│   │   │   ├── VideoMonitor.vue      # 视频监控组件
│   │   │   ├── TrendChart.vue        # 趋势图表组件
│   │   │   └── FishDistribution.vue  # 鱼类分布组件
│   │   ├── router/          # 路由配置
│   │   │   └── index.js            # 路由定义
│   │   ├── App.vue          # 根组件
│   │   └── main.js          # 入口文件
│   ├── index.html           # HTML模板
│   ├── vite.config.js       # Vite配置
│   └── package.json         # 前端依赖配置
├── start.bat                # 一键启动脚本
├── stop.bat                 # 停止服务脚本
├── README.md                # 项目文档
├── 快速启动指南.md          # 启动指南
├── 功能演示说明.md          # 演示说明
└── 更新说明.md              # 最新更新说明
```

## 🚀 快速开始

### 环境要求
- Node.js >= 16.0.0
- npm >= 8.0.0

### 安装步骤

#### 1. 克隆项目
```bash
git clone <repository-url>
cd Marine-Ranch
```

#### 2. 安装后端依赖
```bash
cd backend
npm install
```

#### 3. 安装前端依赖
```bash
cd ../frontend
npm install
```

**注意**：首次安装可能需要5-10分钟，请耐心等待。

### 运行项目

#### 方式一：使用启动脚本（推荐）
```bash
# Windows系统
start.bat
```

#### 方式二：手动启动

**启动后端服务**（终端1）
```bash
cd backend
npm start
```

后端服务将在 `http://localhost:3000` 启动

**启动前端服务**（终端2）
```bash
cd frontend
npm run dev
```

前端服务将在 `http://localhost:5173` 启动

### 访问应用

1. 打开浏览器访问：`http://localhost:5173`
2. 使用演示账号登录：
   - 用户名：`admin`
   - 密码：`123456`
3. 首次加载Cesium可能需要10-30秒，请耐心等待

## 📡 API接口说明

### RESTful API

#### 1. 获取当前传感器数据
```
GET /api/sensor/current
```

响应示例：
```json
{
  "success": true,
  "data": {
    "timestamp": "2024-01-01T12:00:00.000Z",
    "temperature": "22.50",
    "ph": "8.20",
    "dissolvedOxygen": "7.80",
    "salinity": "33.20",
    "turbidity": "3.50"
  },
  "source": "SensorAPIAdress001"
}
```

#### 2. 获取历史数据
```
GET /api/sensor/history
```

#### 3. 获取鱼类分布数据
```
GET /api/fish/distribution
```

#### 4. 获取牧场位置信息
```
GET /api/ranch/location
```

### WebSocket实时推送

#### 事件：sensorData
实时推送传感器数据（每3秒）

#### 事件：fishDistribution
实时推送鱼类分布数据（每10秒）

## 🔧 配置说明

### 传感器API配置

在 `backend/server.js` 中配置传感器API地址：

```javascript
const config = {
  sensorAPIAddress: 'SensorAPIAdress001', // 替换为实际的传感器API地址
  port: 3000
};
```

> **注意**：当前使用占位符 `SensorAPIAdress001`，实际部署时需要替换为真实的传感器API地址。

### Cesium Token配置

在 `frontend/src/components/CesiumViewer.vue` 中配置Cesium Ion Token：

```javascript
Cesium.Ion.defaultAccessToken = 'your-cesium-token-here'
```

> 需要在 [Cesium Ion](https://cesium.com/ion/) 注册账号获取免费Token。

## 📊 数据模拟说明

### 传感器数据模拟
- **水温**：18-26°C 范围内随机生成
- **pH值**：7.5-8.5 范围内随机生成
- **溶氧量**：6-9 mg/L 范围内随机生成
- **盐度**：30-35 ppt 范围内随机生成
- **浊度**：2-5 NTU 范围内随机生成

### 鱼类分布模拟
- 大黄鱼：1200-1500条
- 石斑鱼：800-1000条
- 鲈鱼：1500-1900条
- 海鲈：600-750条
- 其他：400-500条

## 🎯 功能特色

1. **实时性强**：通过WebSocket实现毫秒级数据更新
2. **可视化丰富**：3D地球、折线图、饼图等多维度展示
3. **交互体验好**：流畅的动画效果和直观的用户界面
4. **架构清晰**：前后端分离，易于扩展和维护
5. **模拟完整**：在没有真实传感器的情况下，完整展示系统功能

## 🔮 未来扩展

- [ ] 接入真实传感器设备API
- [ ] 集成WebRTC实现真实视频流
- [ ] 添加TensorFlow.js实现鱼类识别
- [ ] 支持历史数据导出（CSV、Excel）
- [ ] 添加告警系统（异常数据预警）
- [ ] 多牧场管理支持
- [ ] 移动端适配
- [ ] 数据大屏展示模式

## 📝 开发注意事项

1. **端口占用**：确保3000和5173端口未被占用
2. **CORS配置**：后端已配置CORS，支持跨域请求
3. **数据存储**：当前使用内存存储，重启后数据清空
4. **浏览器兼容性**：建议使用Chrome、Edge等现代浏览器
5. **Cesium加载**：首次加载可能较慢，需要下载Cesium资源

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目！

## 📄 许可证

MIT License

## 👨‍💻 作者

大学生计算机设计大赛参赛团队

## 📞 联系方式

如有问题，请通过以下方式联系：
- 提交GitHub Issue
- 发送邮件至：[your-email@example.com]

---

**祝比赛顺利！🏆**

