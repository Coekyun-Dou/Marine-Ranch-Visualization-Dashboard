<template>
  <div class="fish-monitor-container">
    <!-- 顶部导航栏 -->
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
          <router-link to="/water-quality" class="nav-item">
            <el-icon><Goblet /></el-icon>
            <span>水质监控</span>
          </router-link>
          <router-link to="/fish-monitor" class="nav-item" active-class="active">
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
        <h2>
          <el-icon><Camera /></el-icon>
          鱼群实时监控
        </h2>
        <p>基于AI视觉技术的水下鱼群行为分析系统（演示：使用电脑摄像头模拟）</p>
      </div>

      <!-- 视频监控区域 -->
      <div class="video-section">
        <div class="main-video-panel">
          <!-- 主视频窗口 -->
          <div class="video-container">
            <video 
              v-if="showRecognitionMedia && recognitionType === 'video'"
              :src="recognitionMediaUrl"
              class="recognition-media"
              controls
              autoplay
            ></video>
            <img
              v-else-if="showRecognitionMedia && recognitionType === 'image'"
              :src="recognitionMediaUrl"
              class="recognition-media"
              alt="识别结果"
            />
            <video 
              v-else
              ref="videoRef" 
              autoplay 
              playsinline
              :class="{ 'mirror': mirrorMode }"
            ></video>
            <canvas ref="canvasRef" class="overlay-canvas"></canvas>
            
            <!-- 视频状态指示器 -->
            <div class="video-status">
              <div class="status-indicator" :class="{ active: cameraActive }">
                <span class="dot"></span>
                <span>{{ cameraActive ? '实时监控中' : '摄像头未开启' }}</span>
              </div>
              <div class="camera-info">
                <span>{{ currentCamera }}</span>
              </div>
            </div>

            <!-- 视频控制栏 -->
            <div class="video-controls">
              <div class="control-row">
                <el-button-group>
                  <el-button 
                    :type="cameraActive ? 'danger' : 'success'" 
                    @click="toggleCamera"
                  >
                    <el-icon><VideoCameraFilled /></el-icon>
                    {{ cameraActive ? '关闭摄像头' : '开启摄像头' }}
                  </el-button>
                  <el-button @click="captureSnapshot">
                    <el-icon><CameraFilled /></el-icon>
                    截图
                  </el-button>
                  <el-button @click="toggleMirror">
                    <el-icon><RefreshRight /></el-icon>
                    镜像
                  </el-button>
                  <el-button @click="switchCamera">
                    <el-icon><Refresh /></el-icon>
                    切换摄像头
                  </el-button>
                </el-button-group>

                <el-upload
                  class="upload-inline"
                  action="#"
                  :show-file-list="false"
                  :auto-upload="false"
                  :on-change="handleUploadChange"
                  accept=".jpg,.jpeg,.png,.bmp,.webp,.mp4,.avi,.mov,.mkv"
                >
                  <el-button type="primary" :loading="uploading">
                    导入图片/视频分析
                  </el-button>
                </el-upload>

                <el-button
                  v-if="showRecognitionMedia"
                  type="warning"
                  @click="clearRecognitionMedia"
                >
                  返回实时画面
                </el-button>
              </div>
              <div v-if="uploadFileName" class="upload-file-name">已选择：{{ uploadFileName }}</div>
            </div>
          </div>

          <!-- 侧边信息面板 -->
          <div class="info-panel">
            <div class="panel-card">
              <h3>
                <el-icon><DataLine /></el-icon>
                检测统计
              </h3>
              <div class="stats-grid">
                <div class="stat-item">
                  <div class="stat-value">{{ fishCount }}</div>
                  <div class="stat-label">检测到鱼类</div>
                </div>
                <div class="stat-item">
                  <div class="stat-value">{{ movementLevel }}</div>
                  <div class="stat-label">活动程度</div>
                </div>
                <div class="stat-item">
                  <div class="stat-value">{{ healthStatus }}</div>
                  <div class="stat-label">健康状态</div>
                </div>
                <div class="stat-item">
                  <div class="stat-value">{{ cageStatus }}</div>
                  <div class="stat-label">网箱状态</div>
                </div>
              </div>
            </div>

            <div class="panel-card">
              <h3>
                <el-icon><Bell /></el-icon>
                实时告警
              </h3>
              <el-timeline>
                <el-timeline-item
                  v-for="(alert, index) in alerts"
                  :key="index"
                  :timestamp="alert.time"
                  :color="alert.color"
                >
                  {{ alert.message }}
                </el-timeline-item>
                <el-timeline-item 
                  v-if="alerts.length === 0"
                  timestamp="--:--:--"
                  color="#4caf50"
                >
                  暂无告警信息
                </el-timeline-item>
              </el-timeline>
            </div>

            <div class="panel-card">
              <h3>
                <el-icon><Monitor /></el-icon>
                摄像头列表
              </h3>
              <div class="camera-list">
                <div 
                  v-for="cam in cameras" 
                  :key="cam.id"
                  class="camera-item"
                  :class="{ active: activeCameraId === cam.id }"
                  @click="selectCamera(cam.id)"
                >
                  <el-icon><VideoCamera /></el-icon>
                  <span>{{ cam.name }}</span>
                  <el-tag :type="cam.online ? 'success' : 'danger'" size="small">
                    {{ cam.online ? '在线' : '离线' }}
                  </el-tag>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 截图历史 -->
        <div class="snapshots-panel" v-if="snapshots.length > 0">
          <h3>
            <el-icon><Picture /></el-icon>
            截图历史
          </h3>
          <div class="snapshots-grid">
            <div 
              v-for="(snap, index) in snapshots" 
              :key="index"
              class="snapshot-item"
              @click="viewSnapshot(snap)"
            >
              <img :src="snap.url" :alt="snap.time" />
              <div class="snapshot-info">
                <span>{{ snap.time }}</span>
                <el-button 
                  size="small" 
                  type="primary" 
                  link
                  @click.stop="downloadSnapshot(snap)"
                >
                  下载
                </el-button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- AI分析结果 -->
      <div class="analysis-section">
        <div class="section-header">
          <h3>
            <el-icon><TrendCharts /></el-icon>
            AI智能分析
          </h3>
          <el-button type="primary" size="small" :disabled="!cameraActive">
            开始分析
          </el-button>
        </div>
        <el-row :gutter="20">
          <el-col :span="8">
            <div class="analysis-card">
              <h4>鱼类行为分析</h4>
              <div ref="behaviorChartRef" class="chart"></div>
            </div>
          </el-col>
          <el-col :span="8">
            <div class="analysis-card">
              <h4>活动区域热力图</h4>
              <div ref="heatmapChartRef" class="chart"></div>
            </div>
          </el-col>
          <el-col :span="8">
            <div class="analysis-card">
              <h4>历史趋势</h4>
              <div ref="trendChartRef" class="chart"></div>
            </div>
          </el-col>
        </el-row>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import axios from 'axios'
import * as echarts from 'echarts'
import {
  Odometer, Camera, User, SwitchButton,
  VideoCameraFilled, CameraFilled, RefreshRight, Refresh,
  DataLine, Bell, Monitor, VideoCamera, Picture, TrendCharts, Compass, ChatDotRound
} from '@element-plus/icons-vue'

const router = useRouter()
const connected = ref(true)
const currentTime = ref('')
const username = computed(() => localStorage.getItem('username') || 'Admin')

// 视频相关
const videoRef = ref(null)
const canvasRef = ref(null)
const cameraActive = ref(false)
const mirrorMode = ref(true)
const currentCamera = ref('电脑摄像头（模拟水下摄像头）')
const activeCameraId = ref(1)

// 摄像头列表
const cameras = ref([
  { id: 1, name: '网箱1号摄像头', online: true },
  { id: 2, name: '网箱2号摄像头', online: true },
  { id: 3, name: '网箱3号摄像头', online: false },
  { id: 4, name: '网箱4号摄像头', online: true }
])

// 检测数据
const fishCount = ref(Math.floor(Math.random() * 30 + 50))
const movementLevel = ref('活跃')
const healthStatus = ref('良好')
const cageStatus = ref('正常')

// 上传识别
const uploading = ref(false)
const uploadFileName = ref('')
const recognitionType = ref('')
const recognitionMediaPath = ref('')

const showRecognitionMedia = computed(() => !!recognitionMediaPath.value)
const recognitionMediaUrl = computed(() => {
  if (!recognitionMediaPath.value) return ''
  return `http://localhost:3000${recognitionMediaPath.value}?t=${Date.now()}`
})

// 告警信息
const alerts = ref([])

// 截图历史
const snapshots = ref([])

// 媒体流
let mediaStream = null
let deviceId = null

// 更新时间
const updateTime = () => {
  currentTime.value = new Date().toLocaleString('zh-CN')
}

// 开启/关闭摄像头
const toggleCamera = async () => {
  if (cameraActive.value) {
    // 关闭摄像头
    if (mediaStream) {
      mediaStream.getTracks().forEach(track => track.stop())
      mediaStream = null
    }
    if (videoRef.value) {
      videoRef.value.srcObject = null
    }
    cameraActive.value = false
    ElMessage.info('摄像头已关闭')
  } else {
    // 开启摄像头
    try {
      const constraints = {
        video: deviceId ? { deviceId: { exact: deviceId } } : true,
        audio: false
      }
      
      mediaStream = await navigator.mediaDevices.getUserMedia(constraints)
      
      if (videoRef.value) {
        videoRef.value.srcObject = mediaStream
      }
      
      cameraActive.value = true
      ElMessage.success('摄像头已开启')
      
      // 模拟鱼类检测更新
      startFishDetection()
    } catch (error) {
      console.error('无法访问摄像头:', error)
      ElMessage.error('无法访问摄像头，请检查权限设置')
    }
  }
}

// 切换摄像头
const switchCamera = async () => {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices()
    const videoDevices = devices.filter(device => device.kind === 'videoinput')
    
    if (videoDevices.length > 1) {
      // 找到当前设备的索引
      const currentIndex = videoDevices.findIndex(device => device.deviceId === deviceId)
      const nextIndex = (currentIndex + 1) % videoDevices.length
      deviceId = videoDevices[nextIndex].deviceId
      
      // 重新开启摄像头
      if (cameraActive.value) {
        await toggleCamera() // 关闭
        await toggleCamera() // 重新开启
      }
      
      ElMessage.success('已切换摄像头')
    } else {
      ElMessage.info('只检测到一个摄像头设备')
    }
  } catch (error) {
    console.error('切换摄像头失败:', error)
    ElMessage.error('切换摄像头失败')
  }
}

// 镜像模式
const toggleMirror = () => {
  mirrorMode.value = !mirrorMode.value
  ElMessage.success(`镜像模式已${mirrorMode.value ? '开启' : '关闭'}`)
}

// 截图
const captureSnapshot = () => {
  if (!cameraActive.value) {
    ElMessage.warning('请先开启摄像头')
    return
  }
  
  const canvas = canvasRef.value
  const video = videoRef.value
  
  if (canvas && video) {
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    
    const ctx = canvas.getContext('2d')
    ctx.drawImage(video, 0, 0)
    
    const imageUrl = canvas.toDataURL('image/png')
    const time = new Date().toLocaleString('zh-CN')
    
    snapshots.value.unshift({
      url: imageUrl,
      time: time
    })
    
    // 只保留最近10张
    if (snapshots.value.length > 10) {
      snapshots.value.pop()
    }
    
    ElMessage.success('截图成功')
  }
}

// 下载截图
const downloadSnapshot = (snap) => {
  const link = document.createElement('a')
  link.href = snap.url
  link.download = `截图_${snap.time}.png`
  link.click()
  ElMessage.success('下载成功')
}

// 查看截图
const viewSnapshot = (snap) => {
  // 可以实现图片预览功能
  ElMessage.info('图片预览功能开发中...')
}

// 上传图片/视频并识别
const handleUploadChange = async (file) => {
  if (!file?.raw) return

  uploadFileName.value = file.name || ''
  uploading.value = true

  try {
    const formData = new FormData()
    formData.append('file', file.raw)
    formData.append('model', 'pt/best.pt')
    formData.append('conf', '0.4')
    formData.append('iou', '0.5')
    formData.append('save', 'true')

    const res = await axios.post('http://localhost:3000/api/fish/recognition/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    if (!res.data?.success) {
      throw new Error(res.data?.error || '识别失败')
    }

    const data = res.data.data || {}
    fishCount.value = data.totalCount ?? fishCount.value

    // 展示带框识别结果媒体
    recognitionType.value = data.type || ''
    if (data.type === 'video' && data.outputVideoUrl) {
      recognitionMediaPath.value = data.outputVideoUrl
    } else if (data.type === 'image' && data.annotatedImageUrl) {
      recognitionMediaPath.value = data.annotatedImageUrl
    } else {
      recognitionMediaPath.value = ''
    }

    if (data.type === 'video') {
      ElMessage.success(`视频识别完成，最大鱼数：${data.totalCount ?? 0}`)
    } else {
      ElMessage.success(`图片识别完成，检测到鱼数：${data.totalCount ?? 0}`)
    }

    // 有告警区的话补一条记录
    alerts.value.unshift({
      time: new Date().toLocaleTimeString(),
      message: `已完成${data.type === 'video' ? '视频' : '图片'}识别：鱼数 ${data.totalCount ?? 0}`,
      color: '#4caf50'
    })
    if (alerts.value.length > 5) alerts.value.pop()
  } catch (err) {
    ElMessage.error(err?.response?.data?.error || err.message || '上传识别失败')
  } finally {
    uploading.value = false
  }
}

const clearRecognitionMedia = () => {
  recognitionType.value = ''
  recognitionMediaPath.value = ''
}

// 选择摄像头
const selectCamera = (cameraId) => {
  if (!cameras.value.find(c => c.id === cameraId)?.online) {
    ElMessage.warning('该摄像头离线')
    return
  }
  
  activeCameraId.value = cameraId
  currentCamera.value = cameras.value.find(c => c.id === cameraId)?.name || '未知摄像头'
  ElMessage.success(`已切换到${currentCamera.value}`)
}

// 模拟鱼类检测
let detectionInterval = null
const startFishDetection = () => {
  if (detectionInterval) {
    clearInterval(detectionInterval)
  }
  
  detectionInterval = setInterval(() => {
    fishCount.value = Math.floor(Math.random() * 20 + 50)
    
    // 随机生成告警
    if (Math.random() < 0.1) {
      const time = new Date().toLocaleTimeString()
      alerts.value.unshift({
        time: time,
        message: '检测到鱼群聚集异常',
        color: '#ffc107'
      })
      
      // 只保留最近5条
      if (alerts.value.length > 5) {
        alerts.value.pop()
      }
    }
  }, 3000)
}

// 初始化图表
const behaviorChartRef = ref(null)
const heatmapChartRef = ref(null)
const trendChartRef = ref(null)

let behaviorChart = null
let heatmapChart = null
let trendChart = null

const initCharts = () => {
  if (behaviorChartRef.value) {
    behaviorChart = echarts.init(behaviorChartRef.value)
    behaviorChart.setOption({
      backgroundColor: 'transparent',
      tooltip: { trigger: 'item' },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        data: [
          { value: 40, name: '正常游动' },
          { value: 30, name: '摄食行为' },
          { value: 20, name: '静止' },
          { value: 10, name: '其他' }
        ],
        label: { color: '#fff' },
        color: ['#4caf50', '#2196f3', '#ff9800', '#9e9e9e']
      }]
    })
  }
  
  if (heatmapChartRef.value) {
    heatmapChart = echarts.init(heatmapChartRef.value)
    const data = []
    for (let i = 0; i < 10; i++) {
      for (let j = 0; j < 10; j++) {
        data.push([i, j, Math.random() * 100])
      }
    }
    
    heatmapChart.setOption({
      backgroundColor: 'transparent',
      tooltip: { position: 'top' },
      grid: { height: '80%', top: '10%' },
      xAxis: { type: 'category', data: Array.from({ length: 10 }, (_, i) => i), splitArea: { show: true } },
      yAxis: { type: 'category', data: Array.from({ length: 10 }, (_, i) => i), splitArea: { show: true } },
      visualMap: {
        min: 0,
        max: 100,
        calculable: true,
        orient: 'horizontal',
        left: 'center',
        bottom: '0%',
        inRange: { color: ['#0d47a1', '#1976d2', '#42a5f5', '#64b5f6'] },
        textStyle: { color: '#fff' }
      },
      series: [{
        type: 'heatmap',
        data: data,
        emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0, 0, 0, 0.5)' } }
      }]
    })
  }
  
  if (trendChartRef.value) {
    trendChart = echarts.init(trendChartRef.value)
    trendChart.setOption({
      backgroundColor: 'transparent',
      tooltip: { trigger: 'axis' },
      xAxis: {
        type: 'category',
        data: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'],
        axisLine: { lineStyle: { color: '#64b5f6' } },
        axisLabel: { color: '#90caf9' }
      },
      yAxis: {
        type: 'value',
        axisLine: { lineStyle: { color: '#64b5f6' } },
        axisLabel: { color: '#90caf9' },
        splitLine: { lineStyle: { color: 'rgba(100, 181, 246, 0.1)' } }
      },
      series: [{
        type: 'line',
        smooth: true,
        data: [45, 52, 61, 58, 63, 55],
        itemStyle: { color: '#64b5f6' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(100, 181, 246, 0.3)' },
            { offset: 1, color: 'rgba(100, 181, 246, 0)' }
          ])
        }
      }]
    })
  }
}

// 处理命令
const handleCommand = (command) => {
  if (command === 'logout') {
    ElMessage.success('退出登录成功')
    localStorage.removeItem('isLoggedIn')
    router.push('/login')
  }
}

let timeInterval = null

onMounted(() => {
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
  
  setTimeout(() => {
    initCharts()
  }, 100)
})

onUnmounted(() => {
  if (timeInterval) clearInterval(timeInterval)
  if (detectionInterval) clearInterval(detectionInterval)
  
  // 关闭摄像头
  if (mediaStream) {
    mediaStream.getTracks().forEach(track => track.stop())
  }
  
  // 销毁图表
  if (behaviorChart) behaviorChart.dispose()
  if (heatmapChart) heatmapChart.dispose()
  if (trendChart) trendChart.dispose()
})
</script>

<style scoped>
.fish-monitor-container {
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
}

.page-header h2 {
  font-size: 32px;
  color: #fff;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.page-header p {
  color: #90caf9;
  font-size: 16px;
  margin-left: 44px;
}

/* 视频区域 */
.video-section {
  margin-bottom: 30px;
}

.main-video-panel {
  display: grid;
  grid-template-columns: 1fr 350px;
  gap: 20px;
  margin-bottom: 20px;
}

.video-container {
  position: relative;
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

video {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  background: #000;
}

.recognition-media {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
  background: #000;
}

video.mirror {
  transform: scaleX(-1);
}

.overlay-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  display: none;
}

.video-status {
  position: absolute;
  top: 20px;
  left: 20px;
  right: 20px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: rgba(0, 0, 0, 0.7);
  border-radius: 20px;
  color: #fff;
  font-size: 14px;
}

.status-indicator .dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #666;
}

.status-indicator.active .dot {
  background: #ff4444;
  animation: blink 1.5s infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.camera-info {
  padding: 8px 16px;
  background: rgba(0, 0, 0, 0.7);
  border-radius: 20px;
  color: #64b5f6;
  font-size: 14px;
}

.video-controls {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
}

/* 信息面板 */
.info-panel {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.panel-card {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.panel-card h3 {
  font-size: 16px;
  color: #64b5f6;
  margin-bottom: 15px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.stat-item {
  text-align: center;
  padding: 12px;
  background: rgba(13, 71, 161, 0.2);
  border-radius: 8px;
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #fff;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #90caf9;
}

/* 摄像头列表 */
.camera-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.camera-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  background: rgba(13, 71, 161, 0.2);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  color: #fff;
}

.camera-item:hover {
  background: rgba(13, 71, 161, 0.3);
}

.camera-item.active {
  background: rgba(25, 118, 210, 0.4);
  border: 1px solid #64b5f6;
}

/* 截图面板 */
.snapshots-panel {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  margin-bottom: 30px;
}

.snapshots-panel h3 {
  font-size: 18px;
  color: #64b5f6;
  margin-bottom: 15px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.snapshots-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
}

.snapshot-item {
  position: relative;
  cursor: pointer;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s ease;
}

.snapshot-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
}

.snapshot-item img {
  width: 100%;
  height: 150px;
  object-fit: cover;
  display: block;
}

.snapshot-info {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 8px;
  background: rgba(0, 0, 0, 0.7);
  color: #fff;
  font-size: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* AI分析区域 */
.analysis-section {
  background: rgba(30, 41, 59, 0.7);
  border-radius: 16px;
  padding: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
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

.analysis-card {
  background: rgba(13, 71, 161, 0.2);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid rgba(100, 181, 246, 0.2);
}

.analysis-card h4 {
  font-size: 16px;
  color: #64b5f6;
  margin-bottom: 15px;
}

.chart {
  width: 100%;
  height: 300px;
}

/* Timeline样式 */
:deep(.el-timeline-item__timestamp) {
  color: #90caf9;
}

:deep(.el-timeline-item__content) {
  color: #fff;
}
</style>

