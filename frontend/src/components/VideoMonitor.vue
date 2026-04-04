<template>
  <div class="video-monitor">
    <div class="main-video">
      <div class="video-placeholder">
        <div class="video-content">
          <video
            v-if="recognitionResult.outputVideoUrl"
            class="detection-image"
            :src="mediaPreviewUrl"
            controls
          />
          <img
            v-else-if="recognitionResult.annotatedImageUrl"
            :src="mediaPreviewUrl"
            class="detection-image"
            alt="识别结果"
          />
          <template v-else>
            <span class="camera-icon">📹</span>
            <p class="camera-label">网箱 {{ activeCamera }} 号摄像头</p>
            <div class="live-indicator">
              <span class="live-dot"></span>
              <span>实时监控中</span>
            </div>
            <p class="placeholder-text">模拟水下视频流</p>
            <div class="fish-animation">
              <span class="fish" v-for="i in 3" :key="i" :style="getFishStyle(i)">🐟</span>
            </div>
          </template>

          <div class="detect-overlay" v-if="recognizing">
            <span>鱼类识别中...</span>
          </div>
        </div>
      </div>

      <div class="video-controls">
        <el-button-group>
          <el-button size="small" type="primary" @click="runDetection" :loading="recognizing">
            <span>🐟 识别当前画面</span>
          </el-button>
          <el-button size="small" type="primary" @click="toggleAutoDetect">
            <span>{{ autoDetect ? '⏸ 关闭自动识别' : '▶ 开启自动识别' }}</span>
          </el-button>
        </el-button-group>

        <el-upload
          class="upload-box"
          action="#"
          :show-file-list="false"
          :auto-upload="false"
          :on-change="handleFileChange"
          accept=".jpg,.jpeg,.png,.bmp,.webp,.mp4,.avi,.mov,.mkv"
        >
          <el-button size="small" type="success">
            导入图片/视频分析
          </el-button>
        </el-upload>
      </div>

      <p v-if="selectedFileName" class="selected-file">已选择：{{ selectedFileName }}</p>
      <p v-if="errorMessage" class="error-text">{{ errorMessage }}</p>
    </div>

    <div class="camera-selector">
      <div
        v-for="cam in cameras"
        :key="cam.id"
        class="camera-thumb"
        :class="{ active: activeCamera === cam.id }"
        @click="switchCamera(cam.id)"
      >
        <div class="thumb-content">
          <span class="cam-icon">📹</span>
          <span class="cam-name">{{ cam.name }}</span>
          <span class="cam-status" :class="{ online: cam.online }">
            {{ cam.online ? '●' : '○' }}
          </span>
        </div>
      </div>
    </div>

    <div class="monitor-stats">
      <div class="stat-item">
        <span class="stat-label">检测到鱼类数量</span>
        <span class="stat-value">{{ fishCount }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">识别类别</span>
        <span class="stat-value">{{ classSummary }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">结果类型</span>
        <span class="stat-value">{{ recognitionResult.type || '--' }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import axios from 'axios'

const activeCamera = ref(1)
const fishCount = ref(0)
const recognizing = ref(false)
const autoDetect = ref(false)
const errorMessage = ref('')
const selectedFileName = ref('')

const recognitionResult = ref({
  type: '',
  totalCount: 0,
  statistics: {},
  annotatedImageUrl: '',
  outputVideoUrl: ''
})

const cameras = ref([
  { id: 1, name: '网箱1', online: true },
  { id: 2, name: '网箱2', online: true },
  { id: 3, name: '网箱3', online: true },
  { id: 4, name: '网箱4', online: false }
])

const classSummary = computed(() => {
  const entries = Object.entries(recognitionResult.value.statistics || {})
  if (!entries.length) return '--'
  return entries.map(([name, count]) => `${name}:${count}`).join('，')
})

const mediaPreviewUrl = computed(() => {
  const url = recognitionResult.value.outputVideoUrl || recognitionResult.value.annotatedImageUrl
  if (!url) return ''
  return `http://localhost:3000${url}?t=${Date.now()}`
})

const getCameraSource = () => 'testdata/CS_videoplayback014.png'

const applyResult = (data) => {
  recognitionResult.value = {
    type: data.type || '',
    totalCount: data.totalCount || 0,
    statistics: data.statistics || {},
    annotatedImageUrl: data.annotatedImageUrl || '',
    outputVideoUrl: data.outputVideoUrl || ''
  }
  fishCount.value = recognitionResult.value.totalCount
}

const runDetection = async () => {
  recognizing.value = true
  errorMessage.value = ''

  try {
    const response = await axios.post('http://localhost:3000/api/fish/recognition/detect', {
      source: getCameraSource(),
      model: 'pt/best.pt',
      conf: 0.4,
      iou: 0.5,
      save: true
    })

    if (!response.data?.success) throw new Error(response.data?.error || '识别失败')
    applyResult(response.data.data || {})
  } catch (error) {
    errorMessage.value = error?.response?.data?.error || error.message || '识别接口调用失败'
  } finally {
    recognizing.value = false
  }
}

const uploadAndDetect = async (file) => {
  recognizing.value = true
  errorMessage.value = ''

  try {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('model', 'pt/best.pt')
    formData.append('conf', '0.4')
    formData.append('iou', '0.5')
    formData.append('save', 'true')

    const response = await axios.post('http://localhost:3000/api/fish/recognition/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    if (!response.data?.success) throw new Error(response.data?.error || '上传识别失败')
    applyResult(response.data.data || {})
  } catch (error) {
    errorMessage.value = error?.response?.data?.error || error.message || '上传识别失败'
  } finally {
    recognizing.value = false
  }
}

const handleFileChange = (file) => {
  if (!file?.raw) return
  selectedFileName.value = file.name || ''
  uploadAndDetect(file.raw)
}

let autoInterval = null

const toggleAutoDetect = () => {
  autoDetect.value = !autoDetect.value

  if (autoDetect.value) {
    runDetection()
    autoInterval = setInterval(runDetection, 10000)
  } else if (autoInterval) {
    clearInterval(autoInterval)
    autoInterval = null
  }
}

const switchCamera = (cameraId) => {
  activeCamera.value = cameraId
  if (autoDetect.value) runDetection()
}

const getFishStyle = (index) => ({
  animationDelay: `${index * 2}s`,
  top: `${20 + index * 25}%`
})

onUnmounted(() => {
  if (autoInterval) clearInterval(autoInterval)
})
</script>

<style scoped>
.video-monitor { display: flex; flex-direction: column; gap: 15px; }
.main-video { position: relative; }
.video-placeholder {
  width: 100%; aspect-ratio: 16/9;
  background: linear-gradient(180deg, #0a4f6e 0%, #0d2838 100%);
  border-radius: 8px; overflow: hidden; position: relative;
  border: 2px solid rgba(100, 181, 246, 0.3);
}
.video-content {
  width: 100%; height: 100%; display: flex; flex-direction: column;
  justify-content: center; align-items: center; color: #fff; position: relative;
}
.detection-image { width: 100%; height: 100%; object-fit: contain; background: #000; }
.detect-overlay {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  background: rgba(0, 0, 0, 0.35); color: #fff; font-size: 16px; font-weight: 600;
}
.video-controls { margin-top: 10px; display: flex; justify-content: center; gap: 10px; align-items: center; }
.upload-box { display: inline-flex; }
.selected-file { margin-top: 8px; color: #90caf9; font-size: 12px; }
.error-text { margin-top: 6px; color: #ff8a80; font-size: 12px; }
.camera-icon { font-size: 48px; margin-bottom: 10px; opacity: 0.7; }
.camera-label { font-size: 16px; font-weight: 600; margin-bottom: 8px; }
.live-indicator {
  display: flex; align-items: center; gap: 6px; background: rgba(255,0,0,.2);
  padding: 4px 12px; border-radius: 12px; font-size: 12px; margin-bottom: 10px;
}
.live-dot { width: 8px; height: 8px; background: #ff4444; border-radius: 50%; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:.5;transform:scale(1.2)} }
.placeholder-text { font-size: 14px; color: #90caf9; margin-top: 8px; }
.fish-animation { position: absolute; width: 100%; height: 100%; top: 0; left: 0; overflow: hidden; pointer-events: none; }
.fish { position: absolute; font-size: 24px; animation: swim 8s linear infinite; }
@keyframes swim {
  0% { left: -50px; transform: scaleX(1); }
  45% { transform: scaleX(1); }
  50% { left: 110%; transform: scaleX(1); }
  55% { transform: scaleX(-1); }
  95% { transform: scaleX(-1); }
  100% { left: -50px; transform: scaleX(-1); }
}
.camera-selector { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.camera-thumb {
  background: rgba(13,71,161,.3); border: 2px solid rgba(100,181,246,.3);
  border-radius: 6px; padding: 10px; cursor: pointer; transition: all .3s ease;
}
.camera-thumb:hover { border-color: #64b5f6; transform: translateY(-2px); }
.camera-thumb.active { background: rgba(25,118,210,.5); border-color: #64b5f6; }
.thumb-content { display: flex; flex-direction: column; align-items: center; gap: 4px; color: #fff; }
.cam-icon { font-size: 20px; }
.cam-name { font-size: 12px; }
.cam-status { font-size: 10px; color: #666; }
.cam-status.online { color: #4caf50; }
.monitor-stats { display: flex; flex-direction: column; gap: 10px; }
.stat-item {
  display: flex; justify-content: space-between; align-items: center;
  background: rgba(13,71,161,.2); padding: 10px 15px; border-radius: 6px;
  border: 1px solid rgba(100,181,246,.2);
}
.stat-label { font-size: 13px; color: #90caf9; }
.stat-value { font-size: 15px; font-weight: 600; color: #fff; }
</style>
