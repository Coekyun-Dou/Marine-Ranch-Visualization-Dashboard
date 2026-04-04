<template>
  <div class="dashboard-container">
    <!-- 顶部导航栏 -->
    <header class="dashboard-header">
      <div class="header-content">
        <div class="logo-area">
          <span class="logo-icon">🌊</span>
          <h1>智慧海洋牧场可视化平台</h1>
        </div>
        
        <nav class="nav-menu">
          <router-link to="/" class="nav-item" active-class="active">
            <el-icon><Odometer /></el-icon>
            <span>综合监控</span>
          </router-link>
          <router-link to="/water-quality" class="nav-item" active-class="active">
            <el-icon><Goblet /></el-icon>
            <span>水质监控</span>
          </router-link>
          <router-link to="/fish-monitor" class="nav-item" active-class="active">
            <el-icon><Camera /></el-icon>
            <span>鱼群监控</span>
          </router-link>
          <router-link to="/hydro-monitor" class="nav-item" active-class="active">
            <el-icon><Compass /></el-icon>
            <span>水文检测</span>
          </router-link>
          <router-link to="/ai-assistant" class="nav-item" active-class="active">
            <el-icon><ChatDotRound /></el-icon>
            <span>AI助手</span>
          </router-link>
        </nav>

        <div class="status-area">
          <el-tag :type="connected ? 'success' : 'danger'" effect="dark">
            {{ connected ? '🟢 实时连接' : '🔴 连接断开' }}
          </el-tag>
          <span class="time">{{ currentTime }}</span>
          <el-dropdown @command="handleCommand">
            <div class="user-info">
              <el-icon><User /></el-icon>
              <span>{{ username }}</span>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </header>

    <!-- 主体内容区 -->
    <main class="dashboard-main">
      <!-- 左侧面板 -->
      <aside class="left-panel">
        <!-- 关键指标卡片 -->
        <div class="panel-section">
          <div class="section-title">
            <el-icon><DataAnalysis /></el-icon>
            <span>关键环境指标</span>
          </div>
          <div class="key-metrics">
            <!-- 水温 -->
            <div class="metric-card temperature">
              <div class="metric-icon">
                <el-icon><Sunny /></el-icon>
              </div>
              <div class="metric-content">
                <div class="metric-label">水温</div>
                <div class="metric-value">{{ sensorData.temperature || '--' }}</div>
                <div class="metric-unit">°C</div>
              </div>
              <div class="metric-status" :class="getStatus('temperature')">
                {{ getStatusText('temperature') }}
              </div>
            </div>

            <!-- pH值 -->
            <div class="metric-card ph">
              <div class="metric-icon">
                <el-icon><Goblet /></el-icon>
              </div>
              <div class="metric-content">
                <div class="metric-label">pH值</div>
                <div class="metric-value">{{ sensorData.ph || '--' }}</div>
                <div class="metric-unit">pH</div>
              </div>
              <div class="metric-status" :class="getStatus('ph')">
                {{ getStatusText('ph') }}
              </div>
            </div>

            <!-- 溶氧量 -->
            <div class="metric-card oxygen">
              <div class="metric-icon">
                <el-icon><WindPower /></el-icon>
              </div>
              <div class="metric-content">
                <div class="metric-label">溶氧量</div>
                <div class="metric-value">{{ sensorData.dissolvedOxygen || '--' }}</div>
                <div class="metric-unit">mg/L</div>
              </div>
              <div class="metric-status" :class="getStatus('oxygen')">
                {{ getStatusText('oxygen') }}
              </div>
            </div>

            <!-- 其他指标 -->
            <div class="other-metrics">
              <div class="small-metric">
                <span class="label">盐度</span>
                <span class="value">{{ sensorData.salinity || '--' }} ppt</span>
              </div>
              <div class="small-metric">
                <span class="label">浊度</span>
                <span class="value">{{ sensorData.turbidity || '--' }} NTU</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 视频监控 -->
        <div class="panel-section">
          <div class="section-title">
            <el-icon><VideoCamera /></el-icon>
            <span>实时视频监控</span>
          </div>
          <VideoMonitor />
        </div>
      </aside>

      <!-- 中央区域 - 3D地球 -->
      <section class="center-area">
        <CesiumViewer />
      </section>

      <!-- 右侧面板 -->
      <aside class="right-panel">
        <!-- 环境数据趋势图 -->
        <div class="panel-section">
          <div class="section-title">
            <el-icon><TrendCharts /></el-icon>
            <span>环境数据趋势</span>
          </div>
          <TrendChart :historyData="historyData" />
        </div>

        <!-- 鱼类分布饼图 -->
        <div class="panel-section">
          <div class="section-title">
            <el-icon><PieChart /></el-icon>
            <span>鱼类分布统计</span>
          </div>
          <FishDistribution :fishData="fishData" />
        </div>
      </aside>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { io } from 'socket.io-client'
import { ElMessage } from 'element-plus'
// 注意：某些图标可能不存在，使用通用图标替代
import { 
  Odometer, Camera, User, SwitchButton, 
  DataAnalysis, Sunny, Goblet, WindPower, VideoCamera,
  TrendCharts, PieChart, Compass, ChatDotRound
} from '@element-plus/icons-vue'
import CesiumViewer from '../components/ThreeGlobe.vue'
import VideoMonitor from '../components/VideoMonitor.vue'
import TrendChart from '../components/TrendChart.vue'
import FishDistribution from '../components/FishDistribution.vue'

const router = useRouter()

// WebSocket连接状态
const connected = ref(false)
const socket = ref(null)

// 当前时间
const currentTime = ref('')

// 用户名
const username = computed(() => localStorage.getItem('username') || 'Admin')

// 传感器实时数据
const sensorData = ref({
  temperature: '--',
  ph: '--',
  dissolvedOxygen: '--',
  salinity: '--',
  turbidity: '--'
})

// 历史数据
const historyData = ref({
  timestamps: [],
  temperature: [],
  ph: [],
  dissolvedOxygen: []
})

// 鱼类分布数据
const fishData = ref([])

// 更新时间
const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// 获取状态
const getStatus = (type) => {
  const value = parseFloat(sensorData.value[type])
  if (isNaN(value)) return 'normal'
  
  if (type === 'temperature') {
    if (value >= 20 && value <= 25) return 'good'
    if (value >= 18 && value <= 27) return 'normal'
    return 'warning'
  } else if (type === 'ph') {
    if (value >= 7.8 && value <= 8.2) return 'good'
    if (value >= 7.5 && value <= 8.5) return 'normal'
    return 'warning'
  } else if (type === 'oxygen') {
    if (value >= 7 && value <= 9) return 'good'
    if (value >= 6) return 'normal'
    return 'warning'
  }
  return 'normal'
}

// 获取状态文本
const getStatusText = (type) => {
  const status = getStatus(type)
  return status === 'good' ? '优秀' : status === 'normal' ? '正常' : '警告'
}

// 初始化Socket.IO连接
const initSocket = () => {
  socket.value = io('http://localhost:3000')

  socket.value.on('connect', () => {
    connected.value = true
    console.log('✅ WebSocket连接成功')
  })

  socket.value.on('disconnect', () => {
    connected.value = false
    console.log('❌ WebSocket连接断开')
  })

  // 接收传感器数据
  socket.value.on('sensorData', (data) => {
    sensorData.value.temperature = data.temperature
    sensorData.value.ph = data.ph
    sensorData.value.dissolvedOxygen = data.dissolvedOxygen
    sensorData.value.salinity = data.salinity
    sensorData.value.turbidity = data.turbidity

    // 更新历史数据
    const time = new Date().toLocaleTimeString()
    historyData.value.timestamps.push(time)
    historyData.value.temperature.push(parseFloat(data.temperature))
    historyData.value.ph.push(parseFloat(data.ph))
    historyData.value.dissolvedOxygen.push(parseFloat(data.dissolvedOxygen))

    // 保持最近30条数据
    if (historyData.value.timestamps.length > 30) {
      historyData.value.timestamps.shift()
      historyData.value.temperature.shift()
      historyData.value.ph.shift()
      historyData.value.dissolvedOxygen.shift()
    }
  })

  // 接收鱼类分布数据
  socket.value.on('fishDistribution', (data) => {
    fishData.value = data
  })
}

// 处理下拉菜单命令
const handleCommand = (command) => {
  if (command === 'logout') {
    ElMessage.success('退出登录成功')
    localStorage.removeItem('isLoggedIn')
    localStorage.removeItem('username')
    router.push('/login')
  }
}

// 时间定时器
let timeInterval = null

onMounted(() => {
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
  initSocket()
})

onUnmounted(() => {
  if (timeInterval) clearInterval(timeInterval)
  if (socket.value) socket.value.disconnect()
})
</script>

<style scoped>
.dashboard-container {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #0a1929 0%, #1a2332 100%);
  display: flex;
  flex-direction: column;
}

/* 顶部导航栏 */
.dashboard-header {
  height: 70px;
  background: linear-gradient(90deg, rgba(13, 71, 161, 0.9) 0%, rgba(21, 101, 192, 0.9) 100%);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  border-bottom: 2px solid #1976d2;
  flex-shrink: 0;
}

.header-content {
  height: 100%;
  padding: 0 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 15px;
}

.logo-icon {
  font-size: 36px;
}

.logo-area h1 {
  font-size: 24px;
  color: #fff;
  font-weight: 600;
  letter-spacing: 2px;
  white-space: nowrap;
}

/* 导航菜单 */
.nav-menu {
  display: flex;
  gap: 10px;
  flex: 1;
  justify-content: center;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  border-radius: 8px;
  transition: all 0.3s ease;
  font-size: 15px;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.nav-item.active {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
  font-weight: 600;
}

.status-area {
  display: flex;
  align-items: center;
  gap: 15px;
}

.time {
  color: #fff;
  font-size: 14px;
  background: rgba(255, 255, 255, 0.1);
  padding: 8px 12px;
  border-radius: 6px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #fff;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 6px;
  transition: all 0.3s ease;
}

.user-info:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* 主体内容区 */
.dashboard-main {
  flex: 1;
  display: flex;
  gap: 15px;
  padding: 15px;
  overflow: auto;
  min-height: 0;
}

/* 侧边面板 */
.left-panel,
.right-panel {
  width: 380px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  overflow-y: auto;
  flex-shrink: 0;
}

.left-panel::-webkit-scrollbar,
.right-panel::-webkit-scrollbar {
  width: 6px;
}

.left-panel::-webkit-scrollbar-thumb,
.right-panel::-webkit-scrollbar-thumb {
  background: rgba(100, 181, 246, 0.3);
  border-radius: 3px;
}

.panel-section {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #64b5f6;
  margin-bottom: 15px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding-bottom: 10px;
  border-bottom: 2px solid rgba(100, 181, 246, 0.3);
}

/* 关键指标卡片 */
.key-metrics {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.metric-card {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 15px;
  border-radius: 10px;
  background: linear-gradient(135deg, rgba(25, 118, 210, 0.15) 0%, rgba(13, 71, 161, 0.15) 100%);
  border: 1px solid rgba(100, 181, 246, 0.3);
  transition: all 0.3s ease;
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(100, 181, 246, 0.3);
}

.metric-icon {
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  font-size: 24px;
}

.metric-card.temperature .metric-icon {
  background: linear-gradient(135deg, #ff6b6b, #ee5a52);
  color: #fff;
}

.metric-card.ph .metric-icon {
  background: linear-gradient(135deg, #4ecdc4, #44a08d);
  color: #fff;
}

.metric-card.oxygen .metric-icon {
  background: linear-gradient(135deg, #64b5f6, #1976d2);
  color: #fff;
}

.metric-content {
  flex: 1;
}

.metric-label {
  font-size: 13px;
  color: #90caf9;
  margin-bottom: 4px;
}

.metric-value {
  font-size: 28px;
  font-weight: 700;
  color: #fff;
  line-height: 1;
}

.metric-unit {
  font-size: 12px;
  color: #64b5f6;
  margin-top: 2px;
}

.metric-status {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.metric-status.good {
  background: rgba(76, 175, 80, 0.2);
  color: #4caf50;
}

.metric-status.normal {
  background: rgba(255, 193, 7, 0.2);
  color: #ffc107;
}

.metric-status.warning {
  background: rgba(244, 67, 54, 0.2);
  color: #f44336;
}

.other-metrics {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.small-metric {
  padding: 10px;
  background: rgba(13, 71, 161, 0.2);
  border-radius: 8px;
  border: 1px solid rgba(100, 181, 246, 0.2);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.small-metric .label {
  font-size: 12px;
  color: #90caf9;
}

.small-metric .value {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

/* 中央区域 */
.center-area {
  flex: 1;
  background: rgba(15, 23, 42, 0.5);
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.1);
  min-width: 0;
}
</style>

