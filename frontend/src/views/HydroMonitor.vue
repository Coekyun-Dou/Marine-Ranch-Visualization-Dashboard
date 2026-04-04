<template>
  <div class="hydro-monitor">
    <!-- 顶部导航 -->
    <el-header class="header">
      <div class="header-left">
        <h1>🌊 水文环境监测系统</h1>
        <span class="subtitle">Hydrological Monitoring System</span>
      </div>
      <div class="header-right">
        <el-button @click="$router.push('/ai-assistant')" :icon="ChatDotRound">
          AI助手
        </el-button>
        <el-button type="success" @click="exportData" :icon="Download">
          导出数据
        </el-button>
        <el-button type="primary" @click="$router.push('/')">返回主页</el-button>
      </div>
    </el-header>

    <!-- 主内容区域 -->
    <div class="content">
      <!-- 第一行：实时数据卡片 -->
      <el-row :gutter="20" class="data-cards">
        <el-col :span="4">
          <div class="data-card wave">
            <div class="icon">🌊</div>
            <div class="label">波高</div>
            <div class="value">{{ hydroData.wave?.height || '--' }} <span class="unit">米</span></div>
            <div class="sub">周期 {{ hydroData.wave?.period || '--' }}秒</div>
          </div>
        </el-col>
        <el-col :span="4">
          <div class="data-card current">
            <div class="icon">🔄</div>
            <div class="label">流速</div>
            <div class="value">{{ hydroData.current?.speed || '--' }} <span class="unit">m/s</span></div>
            <div class="sub">{{ getDirectionName(hydroData.current?.direction) }}</div>
          </div>
        </el-col>
        <el-col :span="4">
          <div class="data-card tide">
            <div class="icon">📊</div>
            <div class="label">潮位</div>
            <div class="value">{{ hydroData.tide?.level || '--' }} <span class="unit">米</span></div>
            <div class="sub">{{ hydroData.tide?.trend || '--' }}</div>
          </div>
        </el-col>
        <el-col :span="4">
          <div class="data-card wind">
            <div class="icon">💨</div>
            <div class="label">风速</div>
            <div class="value">{{ hydroData.wind?.speed || '--' }} <span class="unit">m/s</span></div>
            <div class="sub">{{ hydroData.wind?.level || '--' }}级 {{ getDirectionName(hydroData.wind?.direction) }}</div>
          </div>
        </el-col>
        <el-col :span="4">
          <div class="data-card light">
            <div class="icon">☀️</div>
            <div class="label">光照强度</div>
            <div class="value">{{ hydroData.light?.intensity || '--' }} <span class="unit">lux</span></div>
            <div class="sub">UV {{ hydroData.light?.uv || '--' }}</div>
          </div>
        </el-col>
        <el-col :span="4">
          <div class="data-card status">
            <div class="icon">✅</div>
            <div class="label">系统状态</div>
            <div class="value online">在线</div>
            <div class="sub">{{ currentTime }}</div>
          </div>
        </el-col>
      </el-row>

      <!-- 第二行：海浪和海流 -->
      <el-row :gutter="20" class="chart-row">
        <el-col :span="12">
          <div class="chart-card">
            <div class="card-header">
              <h3>🌊 海浪监测</h3>
              <span class="desc">Wave Height & Period</span>
            </div>
            <WaveChart ref="waveChartRef" />
          </div>
        </el-col>
        <el-col :span="12">
          <div class="chart-card">
            <div class="card-header">
              <h3>🔄 海流监测</h3>
              <span class="desc">Current Speed & Direction</span>
            </div>
            <CurrentChart ref="currentChartRef" />
          </div>
        </el-col>
      </el-row>

      <!-- 第三行：潮位和风速风向 -->
      <el-row :gutter="20" class="chart-row">
        <el-col :span="12">
          <div class="chart-card">
            <div class="card-header">
              <h3>📊 潮位变化</h3>
              <span class="desc">24-Hour Tide Level</span>
            </div>
            <TideChart />
          </div>
        </el-col>
        <el-col :span="12">
          <div class="chart-card">
            <div class="card-header">
              <h3>💨 风速风向</h3>
              <span class="desc">Wind Speed & Direction</span>
            </div>
            <WindChart ref="windChartRef" />
          </div>
        </el-col>
      </el-row>

      <!-- 第四行：光照强度 -->
      <el-row :gutter="20" class="chart-row">
        <el-col :span="24">
          <div class="chart-card">
            <div class="card-header">
              <h3>☀️ 光照强度监测</h3>
              <span class="desc">Light Intensity & UV Index</span>
            </div>
            <LightChart ref="lightChartRef" />
          </div>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { io } from 'socket.io-client'
import { Download, ChatDotRound } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import WaveChart from '../components/hydro/WaveChart.vue'
import CurrentChart from '../components/hydro/CurrentChart.vue'
import TideChart from '../components/hydro/TideChart.vue'
import WindChart from '../components/hydro/WindChart.vue'
import LightChart from '../components/hydro/LightChart.vue'

const hydroData = ref({})
const currentTime = ref('')
let socket = null
let timeInterval = null

const waveChartRef = ref(null)
const currentChartRef = ref(null)
const windChartRef = ref(null)
const lightChartRef = ref(null)

onMounted(() => {
  // 连接 WebSocket
  socket = io('http://localhost:3000')
  
  socket.on('connect', () => {
    console.log('✅ WebSocket连接成功')
  })
  
  socket.on('hydroData', (data) => {
    hydroData.value = data
    
    // 更新各个图表
    if (waveChartRef.value) {
      waveChartRef.value.updateData(data.wave)
    }
    if (currentChartRef.value) {
      currentChartRef.value.updateData(data.current)
    }
    if (windChartRef.value) {
      windChartRef.value.updateData(data.wind)
    }
    if (lightChartRef.value) {
      lightChartRef.value.updateData(data.light)
    }
  })
  
  socket.on('disconnect', () => {
    console.log('❌ WebSocket断开连接')
  })
  
  // 更新当前时间
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
})

onUnmounted(() => {
  if (socket) {
    socket.disconnect()
  }
  if (timeInterval) {
    clearInterval(timeInterval)
  }
})

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('zh-CN')
}

const getDirectionName = (degree) => {
  if (degree === undefined || degree === null) return '--'
  const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北']
  const index = Math.round((degree % 360) / 45) % 8
  return directions[index]
}

// 导出数据功能
const exportData = async () => {
  try {
    ElMessage.info('正在生成导出文件...')
    
    // 准备CSV内容
    const timestamp = new Date().toLocaleString('zh-CN')
    let csvContent = '\uFEFF' // UTF-8 BOM for Excel compatibility
    
    // 添加标题
    csvContent += '智慧海洋牧场 - 水文监测数据导出\n'
    csvContent += `导出时间,${timestamp}\n\n`
    
    // 实时数据
    csvContent += '=== 实时水文数据 ===\n'
    csvContent += '监测项目,数值,单位,备注\n'
    csvContent += `波高,${hydroData.value.wave?.height || '--'},米,周期${hydroData.value.wave?.period || '--'}秒\n`
    csvContent += `流速,${hydroData.value.current?.speed || '--'},m/s,${getDirectionName(hydroData.value.current?.direction)}\n`
    csvContent += `潮位,${hydroData.value.tide?.level || '--'},米,${hydroData.value.tide?.trend || '--'}\n`
    csvContent += `风速,${hydroData.value.wind?.speed || '--'},m/s,${hydroData.value.wind?.level || '--'}级 ${getDirectionName(hydroData.value.wind?.direction)}\n`
    csvContent += `光照强度,${hydroData.value.light?.intensity || '--'},lux,UV指数${hydroData.value.light?.uv || '--'}\n`
    csvContent += '\n'
    
    // 历史数据（模拟最近24小时）
    csvContent += '=== 历史趋势数据（最近24小时）===\n'
    csvContent += '时间,波高(米),流速(m/s),潮位(米),风速(m/s),光照(lux)\n'
    
    // 生成24小时模拟数据
    for (let i = 23; i >= 0; i--) {
      const time = new Date(Date.now() - i * 3600000)
      const timeStr = time.toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
      const waveHeight = (Math.random() * 1.5 + 0.5).toFixed(2)
      const currentSpeed = (Math.random() * 0.8 + 0.3).toFixed(2)
      const tideLevel = (Math.random() * 0.8 + 1.5).toFixed(2)
      const windSpeed = (Math.random() * 8 + 2).toFixed(1)
      const lightIntensity = Math.floor(Math.random() * 50000 + 10000)
      
      csvContent += `${timeStr},${waveHeight},${currentSpeed},${tideLevel},${windSpeed},${lightIntensity}\n`
    }
    
    // 创建下载链接
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    
    link.setAttribute('href', url)
    link.setAttribute('download', `水文监测数据_${new Date().getTime()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    ElMessage.success('数据导出成功！')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('数据导出失败，请重试')
  }
}
</script>

<style scoped>
.hydro-monitor {
  width: 100%;
  min-height: 100vh;
  height: 100vh;
  overflow-y: auto;
  overflow-x: hidden;
  background: linear-gradient(to bottom, #0a1929, #1a2942);
  color: #fff;
}

.header {
  background: rgba(10, 25, 41, 0.8);
  border-bottom: 1px solid rgba(100, 181, 246, 0.3);
  padding: 20px 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  backdrop-filter: blur(10px);
}

.header-right {
  display: flex;
  gap: 10px;
}

.header-left h1 {
  font-size: 24px;
  margin: 0 0 5px 0;
  background: linear-gradient(90deg, #64b5f6, #00e5ff);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.subtitle {
  font-size: 12px;
  color: #90caf9;
  letter-spacing: 2px;
}

.content {
  padding: 30px;
}

.data-cards {
  margin-bottom: 20px;
}

.data-card {
  background: rgba(10, 25, 41, 0.6);
  border: 1px solid rgba(100, 181, 246, 0.2);
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  transition: all 0.3s;
  backdrop-filter: blur(10px);
  position: relative;
  overflow: hidden;
}

.data-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, transparent, #64b5f6, transparent);
}

.data-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(100, 181, 246, 0.3);
  border-color: #64b5f6;
}

.data-card .icon {
  font-size: 32px;
  margin-bottom: 10px;
}

.data-card .label {
  color: #90caf9;
  font-size: 12px;
  margin-bottom: 8px;
  letter-spacing: 1px;
}

.data-card .value {
  font-size: 28px;
  font-weight: bold;
  color: #fff;
  margin-bottom: 5px;
}

.data-card .value .unit {
  font-size: 14px;
  color: #90caf9;
  margin-left: 5px;
}

.data-card .value.online {
  color: #00e676;
  font-size: 16px;
}

.data-card .sub {
  font-size: 12px;
  color: #64b5f6;
}

.chart-row {
  margin-bottom: 20px;
}

.chart-card {
  background: rgba(10, 25, 41, 0.6);
  border: 1px solid rgba(100, 181, 246, 0.2);
  border-radius: 12px;
  padding: 20px;
  backdrop-filter: blur(10px);
  min-height: 400px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 1px solid rgba(100, 181, 246, 0.2);
}

.card-header h3 {
  margin: 0;
  font-size: 18px;
  color: #fff;
}

.card-header .desc {
  font-size: 12px;
  color: #90caf9;
  letter-spacing: 1px;
}
</style>


