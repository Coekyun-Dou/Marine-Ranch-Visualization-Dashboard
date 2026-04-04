<template>
  <div class="water-quality-container">
    <!-- 顶部导航栏（复用） -->
    <header class="dashboard-header">
      <div class="header-content">
        <div class="logo-area">
          <span class="logo-icon">🌊</span>
          <h1>智慧海洋牧场可视化平台</h1>
        </div>
        
        <nav class="nav-menu">
          <router-link to="/" class="nav-item">
            <el-icon><Odometer /></el-icon>
            <span>综合监控</span>
          </router-link>
          <router-link to="/water-quality" class="nav-item" active-class="active">
            <el-icon><Goblet /></el-icon>
            <span>水质监控</span>
          </router-link>
          <router-link to="/fish-monitor" class="nav-item">
            <el-icon><Camera /></el-icon>
            <span>鱼群监控</span>
          </router-link>
          <router-link to="/hydro-monitor" class="nav-item">
            <el-icon><Compass /></el-icon>
            <span>水文检测</span>
          </router-link>
          <router-link to="/ai-assistant" class="nav-item">
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

    <!-- 主内容区 -->
    <main class="main-content">
      <!-- 页面标题 -->
      <div class="page-header">
        <div class="header-left">
          <h2>
            <el-icon><Goblet /></el-icon>
            水质监控中心
          </h2>
          <p>实时监测海洋牧场水质参数，确保养殖环境健康</p>
        </div>
        <div class="header-right">
          <el-button type="success" @click="exportData" :icon="Download">
            导出数据
          </el-button>
        </div>
      </div>

      <!-- 数据卡片网格 -->
      <div class="metrics-grid">
        <!-- 水温卡片 -->
        <div class="metric-card-large temperature">
          <div class="card-header">
            <div class="icon-box">
              <el-icon><Sunny /></el-icon>
            </div>
            <div class="header-info">
              <h3>水温</h3>
              <span class="unit">Temperature (°C)</span>
            </div>
          </div>
          <div class="card-body">
            <div class="value-display">{{ sensorData.temperature || '--' }}</div>
            <div class="range-info">
              <span>正常范围: 18-26°C</span>
              <el-tag :type="getStatusType('temperature')" size="small">
                {{ getStatusText('temperature') }}
              </el-tag>
            </div>
          </div>
          <div class="card-chart">
            <div ref="tempChartRef" class="mini-chart"></div>
          </div>
        </div>

        <!-- pH值卡片 -->
        <div class="metric-card-large ph">
          <div class="card-header">
            <div class="icon-box">
              <el-icon><Goblet /></el-icon>
            </div>
            <div class="header-info">
              <h3>pH值</h3>
              <span class="unit">pH Value</span>
            </div>
          </div>
          <div class="card-body">
            <div class="value-display">{{ sensorData.ph || '--' }}</div>
            <div class="range-info">
              <span>正常范围: 7.5-8.5</span>
              <el-tag :type="getStatusType('ph')" size="small">
                {{ getStatusText('ph') }}
              </el-tag>
            </div>
          </div>
          <div class="card-chart">
            <div ref="phChartRef" class="mini-chart"></div>
          </div>
        </div>

        <!-- 溶氧量卡片 -->
        <div class="metric-card-large oxygen">
          <div class="card-header">
            <div class="icon-box">
              <el-icon><WindPower /></el-icon>
            </div>
            <div class="header-info">
              <h3>溶氧量</h3>
              <span class="unit">Dissolved Oxygen (mg/L)</span>
            </div>
          </div>
          <div class="card-body">
            <div class="value-display">{{ sensorData.dissolvedOxygen || '--' }}</div>
            <div class="range-info">
              <span>正常范围: ≥6 mg/L</span>
              <el-tag :type="getStatusType('oxygen')" size="small">
                {{ getStatusText('oxygen') }}
              </el-tag>
            </div>
          </div>
          <div class="card-chart">
            <div ref="oxygenChartRef" class="mini-chart"></div>
          </div>
        </div>

        <!-- 盐度卡片 -->
        <div class="metric-card-medium">
          <div class="icon">
            <el-icon><Sugar /></el-icon>
          </div>
          <div class="content">
            <div class="label">盐度 Salinity</div>
            <div class="value">{{ sensorData.salinity || '--' }} <span class="unit">ppt</span></div>
            <div class="status">正常范围: 30-35 ppt</div>
          </div>
        </div>

        <!-- 浊度卡片 -->
        <div class="metric-card-medium">
          <div class="icon">
            <el-icon><View /></el-icon>
          </div>
          <div class="content">
            <div class="label">浊度 Turbidity</div>
            <div class="value">{{ sensorData.turbidity || '--' }} <span class="unit">NTU</span></div>
            <div class="status">正常范围: 2-5 NTU</div>
          </div>
        </div>
      </div>

      <!-- 历史趋势图表 -->
      <div class="chart-section">
        <div class="section-header">
          <h3>
            <el-icon><TrendCharts /></el-icon>
            历史数据趋势分析
          </h3>
          <el-radio-group v-model="timeRange" size="small">
            <el-radio-button label="realtime">实时</el-radio-button>
            <el-radio-button label="hour">1小时</el-radio-button>
            <el-radio-button label="day">24小时</el-radio-button>
          </el-radio-group>
        </div>
        <div ref="mainChartRef" class="main-chart"></div>
      </div>

      <!-- 数据统计表格 -->
      <div class="table-section">
        <div class="section-header">
          <h3>
            <el-icon><Document /></el-icon>
            数据统计报表
          </h3>
          <el-button type="primary" size="small" @click="exportData">
            <el-icon><Download /></el-icon>
            导出数据
          </el-button>
        </div>
        <el-table :data="statisticsData" stripe style="width: 100%">
          <el-table-column prop="parameter" label="参数" width="150" />
          <el-table-column prop="current" label="当前值" width="120" />
          <el-table-column prop="avg" label="平均值" width="120" />
          <el-table-column prop="max" label="最大值" width="120" />
          <el-table-column prop="min" label="最小值" width="120" />
          <el-table-column prop="status" label="状态" width="100">
            <template #default="scope">
              <el-tag :type="scope.row.statusType" size="small">
                {{ scope.row.status }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { io } from 'socket.io-client'
import { ElMessage } from 'element-plus'
import * as echarts from 'echarts'
import {
  Odometer, Camera, User, SwitchButton,
  Sunny, Goblet, WindPower,
  TrendCharts, Document, Download, Compass, ChatDotRound
} from '@element-plus/icons-vue'

const router = useRouter()
const connected = ref(false)
const socket = ref(null)
const currentTime = ref('')
const username = computed(() => localStorage.getItem('username') || 'Admin')
const timeRange = ref('realtime')

// 传感器数据
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

// 图表引用
const tempChartRef = ref(null)
const phChartRef = ref(null)
const oxygenChartRef = ref(null)
const mainChartRef = ref(null)

let tempChart = null
let phChart = null
let oxygenChart = null
let mainChart = null

// 统计数据
const statisticsData = computed(() => {
  const calcStats = (arr) => {
    if (!arr.length) return { avg: '--', max: '--', min: '--' }
    const values = arr.filter(v => !isNaN(v))
    return {
      avg: (values.reduce((a, b) => a + b, 0) / values.length).toFixed(2),
      max: Math.max(...values).toFixed(2),
      min: Math.min(...values).toFixed(2)
    }
  }

  const tempStats = calcStats(historyData.value.temperature)
  const phStats = calcStats(historyData.value.ph)
  const oxygenStats = calcStats(historyData.value.dissolvedOxygen)

  return [
    {
      parameter: '水温',
      current: sensorData.value.temperature + ' °C',
      ...tempStats,
      status: '正常',
      statusType: 'success'
    },
    {
      parameter: 'pH值',
      current: sensorData.value.ph,
      ...phStats,
      status: '正常',
      statusType: 'success'
    },
    {
      parameter: '溶氧量',
      current: sensorData.value.dissolvedOxygen + ' mg/L',
      ...oxygenStats,
      status: '正常',
      statusType: 'success'
    }
  ]
})

// 获取状态类型
const getStatusType = (type) => {
  const value = parseFloat(sensorData.value[type])
  if (isNaN(value)) return 'info'
  
  if (type === 'temperature') {
    return (value >= 18 && value <= 26) ? 'success' : 'warning'
  } else if (type === 'ph') {
    return (value >= 7.5 && value <= 8.5) ? 'success' : 'warning'
  } else if (type === 'oxygen') {
    return value >= 6 ? 'success' : 'danger'
  }
  return 'info'
}

// 获取状态文本
const getStatusText = (type) => {
  const statusType = getStatusType(type)
  return statusType === 'success' ? '正常' : statusType === 'warning' ? '注意' : '警告'
}

// 初始化小图表
const initMiniCharts = () => {
  if (tempChartRef.value) {
    tempChart = echarts.init(tempChartRef.value)
    tempChart.setOption(getMiniChartOption('#ff6b6b'))
  }
  
  if (phChartRef.value) {
    phChart = echarts.init(phChartRef.value)
    phChart.setOption(getMiniChartOption('#4ecdc4'))
  }
  
  if (oxygenChartRef.value) {
    oxygenChart = echarts.init(oxygenChartRef.value)
    oxygenChart.setOption(getMiniChartOption('#64b5f6'))
  }
}

// 小图表配置
const getMiniChartOption = (color) => ({
  grid: { left: 0, right: 0, top: 5, bottom: 0 },
  xAxis: { type: 'category', show: false, data: [] },
  yAxis: { type: 'value', show: false },
  series: [{
    type: 'line',
    smooth: true,
    symbol: 'none',
    lineStyle: { color, width: 2 },
    areaStyle: {
      color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
        { offset: 0, color: color + '80' },
        { offset: 1, color: color + '00' }
      ])
    },
    data: []
  }]
})

// 初始化主图表
const initMainChart = () => {
  if (!mainChartRef.value) return
  
  mainChart = echarts.init(mainChartRef.value)
  mainChart.setOption({
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(30, 41, 59, 0.9)',
      borderColor: '#64b5f6',
      textStyle: { color: '#fff' }
    },
    legend: {
      data: ['水温', 'pH值', '溶氧量'],
      textStyle: { color: '#90caf9' },
      top: 10
    },
    grid: { left: '3%', right: '4%', bottom: '3%', top: '15%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: [],
      axisLine: { lineStyle: { color: '#64b5f6' } },
      axisLabel: { color: '#90caf9' }
    },
    yAxis: [
      {
        type: 'value',
        name: '水温(°C) / 溶氧(mg/L)',
        axisLine: { lineStyle: { color: '#64b5f6' } },
        axisLabel: { color: '#90caf9' },
        splitLine: { lineStyle: { color: 'rgba(100, 181, 246, 0.1)' } }
      },
      {
        type: 'value',
        name: 'pH值',
        min: 6,
        max: 10,
        axisLine: { lineStyle: { color: '#64b5f6' } },
        axisLabel: { color: '#90caf9' },
        splitLine: { show: false }
      }
    ],
    series: [
      {
        name: '水温',
        type: 'line',
        smooth: true,
        data: [],
        itemStyle: { color: '#ff6b6b' }
      },
      {
        name: 'pH值',
        type: 'line',
        smooth: true,
        yAxisIndex: 1,
        data: [],
        itemStyle: { color: '#4ecdc4' }
      },
      {
        name: '溶氧量',
        type: 'line',
        smooth: true,
        data: [],
        itemStyle: { color: '#64b5f6' }
      }
    ]
  })
}

// 更新图表
const updateCharts = () => {
  // 更新小图表
  if (tempChart && historyData.value.temperature.length) {
    tempChart.setOption({
      xAxis: { data: historyData.value.timestamps },
      series: [{ data: historyData.value.temperature }]
    })
  }
  
  if (phChart && historyData.value.ph.length) {
    phChart.setOption({
      xAxis: { data: historyData.value.timestamps },
      series: [{ data: historyData.value.ph }]
    })
  }
  
  if (oxygenChart && historyData.value.dissolvedOxygen.length) {
    oxygenChart.setOption({
      xAxis: { data: historyData.value.timestamps },
      series: [{ data: historyData.value.dissolvedOxygen }]
    })
  }
  
  // 更新主图表
  if (mainChart) {
    mainChart.setOption({
      xAxis: { data: historyData.value.timestamps },
      series: [
        { data: historyData.value.temperature },
        { data: historyData.value.ph },
        { data: historyData.value.dissolvedOxygen }
      ]
    })
  }
}

// 导出数据
// 更新时间
const updateTime = () => {
  currentTime.value = new Date().toLocaleString('zh-CN')
}

// 初始化Socket连接
const initSocket = () => {
  socket.value = io('http://localhost:3000')

  socket.value.on('connect', () => {
    connected.value = true
  })

  socket.value.on('disconnect', () => {
    connected.value = false
  })

  socket.value.on('sensorData', (data) => {
    sensorData.value = {
      temperature: data.temperature,
      ph: data.ph,
      dissolvedOxygen: data.dissolvedOxygen,
      salinity: data.salinity,
      turbidity: data.turbidity
    }

    const time = new Date().toLocaleTimeString()
    historyData.value.timestamps.push(time)
    historyData.value.temperature.push(parseFloat(data.temperature))
    historyData.value.ph.push(parseFloat(data.ph))
    historyData.value.dissolvedOxygen.push(parseFloat(data.dissolvedOxygen))

    if (historyData.value.timestamps.length > 30) {
      historyData.value.timestamps.shift()
      historyData.value.temperature.shift()
      historyData.value.ph.shift()
      historyData.value.dissolvedOxygen.shift()
    }

    updateCharts()
  })
}

// 处理命令
const handleCommand = (command) => {
  if (command === 'logout') {
    ElMessage.success('退出登录成功')
    localStorage.removeItem('isLoggedIn')
    router.push('/login')
  }
}

// 导出数据功能
const exportData = () => {
  try {
    ElMessage.info('正在生成导出文件...')
    
    // 准备CSV内容
    const timestamp = new Date().toLocaleString('zh-CN')
    let csvContent = '\uFEFF' // UTF-8 BOM for Excel compatibility
    
    // 添加标题
    csvContent += '智慧海洋牧场 - 水质监测数据导出\n'
    csvContent += `导出时间,${timestamp}\n\n`
    
    // 实时数据
    csvContent += '=== 实时水质数据 ===\n'
    csvContent += '监测项目,数值,单位,状态\n'
    csvContent += `水温,${sensorData.value.temperature || '--'},°C,${getStatusText('temperature')}\n`
    csvContent += `pH值,${sensorData.value.ph || '--'},,${getStatusText('ph')}\n`
    csvContent += `溶氧量,${sensorData.value.dissolvedOxygen || '--'},mg/L,${getStatusText('oxygen')}\n`
    csvContent += `盐度,${sensorData.value.salinity || '--'},ppt,正常\n`
    csvContent += `浊度,${sensorData.value.turbidity || '--'},NTU,正常\n`
    csvContent += '\n'
    
    // 历史数据（模拟最近24小时）
    csvContent += '=== 历史趋势数据（最近24小时）===\n'
    csvContent += '时间,水温(°C),pH值,溶氧量(mg/L),盐度(ppt),浊度(NTU)\n'
    
    // 生成24小时模拟数据
    for (let i = 23; i >= 0; i--) {
      const time = new Date(Date.now() - i * 3600000)
      const timeStr = time.toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
      const temp = (18 + Math.random() * 8).toFixed(2)
      const ph = (7.5 + Math.random() * 1).toFixed(2)
      const oxygen = (6 + Math.random() * 3).toFixed(2)
      const salinity = (30 + Math.random() * 5).toFixed(2)
      const turbidity = (2 + Math.random() * 3).toFixed(2)
      
      csvContent += `${timeStr},${temp},${ph},${oxygen},${salinity},${turbidity}\n`
    }
    
    csvContent += '\n'
    csvContent += '=== 数据说明 ===\n'
    csvContent += '水温正常范围,20-26°C\n'
    csvContent += 'pH值正常范围,7.8-8.3\n'
    csvContent += '溶氧量正常范围,≥7.0 mg/L\n'
    csvContent += '盐度正常范围,30-35 ppt\n'
    csvContent += '浊度正常范围,<5 NTU\n'
    
    // 创建下载链接
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    
    link.setAttribute('href', url)
    link.setAttribute('download', `水质监测数据_${new Date().getTime()}.csv`)
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

let timeInterval = null

onMounted(() => {
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
  initSocket()
  
  setTimeout(() => {
    initMiniCharts()
    initMainChart()
  }, 100)
})

onUnmounted(() => {
  if (timeInterval) clearInterval(timeInterval)
  if (socket.value) socket.value.disconnect()
  if (tempChart) tempChart.dispose()
  if (phChart) phChart.dispose()
  if (oxygenChart) oxygenChart.dispose()
  if (mainChart) mainChart.dispose()
})
</script>

<style scoped>
.water-quality-container {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #0a1929 0%, #1a2332 100%);
  display: flex;
  flex-direction: column;
}

/* 复用导航栏样式 */
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
}

.user-info:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* 主内容区 */
.main-content {
  flex: 1;
  overflow-y: auto;
  padding: 30px;
}

.main-content::-webkit-scrollbar {
  width: 8px;
}

.main-content::-webkit-scrollbar-thumb {
  background: rgba(100, 181, 246, 0.3);
  border-radius: 4px;
}

/* 页面标题 */
.page-header {
  margin-bottom: 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left h2 {
  font-size: 32px;
  color: #fff;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.header-left p {
  color: #90caf9;
  font-size: 16px;
  margin-left: 44px;
}

.header-right {
  display: flex;
  gap: 10px;
}

/* 数据卡片网格 */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 30px;
}

/* 大卡片 */
.metric-card-large {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  padding: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.metric-card-large:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 20px;
}

.icon-box {
  width: 50px;
  height: 50px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: #fff;
}

.temperature .icon-box {
  background: linear-gradient(135deg, #ff6b6b, #ee5a52);
}

.ph .icon-box {
  background: linear-gradient(135deg, #4ecdc4, #44a08d);
}

.oxygen .icon-box {
  background: linear-gradient(135deg, #64b5f6, #1976d2);
}

.header-info h3 {
  font-size: 18px;
  color: #fff;
  margin-bottom: 4px;
}

.header-info .unit {
  font-size: 12px;
  color: #90caf9;
}

.card-body {
  margin-bottom: 20px;
}

.value-display {
  font-size: 48px;
  font-weight: 700;
  color: #fff;
  line-height: 1;
  margin-bottom: 12px;
}

.range-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: #90caf9;
  font-size: 13px;
}

.card-chart {
  height: 60px;
  margin-top: 15px;
}

.mini-chart {
  width: 100%;
  height: 100%;
}

/* 中等卡片 */
.metric-card-medium {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  padding: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  gap: 20px;
  transition: all 0.3s ease;
}

.metric-card-medium:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.metric-card-medium .icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  background: linear-gradient(135deg, #ffe66d, #ffc107);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  color: #fff;
}

.metric-card-medium .content {
  flex: 1;
}

.metric-card-medium .label {
  font-size: 14px;
  color: #90caf9;
  margin-bottom: 8px;
}

.metric-card-medium .value {
  font-size: 32px;
  font-weight: 700;
  color: #fff;
  margin-bottom: 4px;
}

.metric-card-medium .value .unit {
  font-size: 16px;
  color: #64b5f6;
}

.metric-card-medium .status {
  font-size: 12px;
  color: #90caf9;
}

/* 图表区域 */
.chart-section,
.table-section {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  padding: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  margin-bottom: 30px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  font-size: 20px;
  color: #fff;
  display: flex;
  align-items: center;
  gap: 10px;
}

.main-chart {
  width: 100%;
  height: 400px;
}

/* 表格样式 */
:deep(.el-table) {
  background: transparent;
  color: #fff;
}

:deep(.el-table th.el-table__cell) {
  background: rgba(13, 71, 161, 0.3);
  color: #64b5f6;
  border-color: rgba(255, 255, 255, 0.1);
}

:deep(.el-table tr) {
  background: transparent;
}

:deep(.el-table td.el-table__cell) {
  border-color: rgba(255, 255, 255, 0.1);
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped td.el-table__cell) {
  background: rgba(13, 71, 161, 0.1);
}

:deep(.el-table__body tr:hover > td) {
  background: rgba(13, 71, 161, 0.2) !important;
}
</style>

