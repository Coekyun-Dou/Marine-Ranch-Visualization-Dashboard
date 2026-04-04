<template>
  <div class="map-visualization">
    <!-- 地图容器 -->
    <div ref="mapContainer" class="map-container">
      <!-- 中国地图轮廓背景 -->
      <div class="china-outline">
        <svg viewBox="0 0 1000 800" class="china-svg">
          <!-- 简化的中国地图轮廓 -->
          <path d="M 200,400 Q 300,200 500,250 T 800,400 Q 700,600 500,650 T 200,400 Z" 
                fill="rgba(30, 58, 95, 0.4)" 
                stroke="#4ecdc4" 
                stroke-width="2"/>
          
          <!-- 广东省区域（粗略位置） -->
          <ellipse cx="650" cy="550" rx="80" ry="60" 
                   fill="rgba(100, 181, 246, 0.2)" 
                   stroke="#64b5f6" 
                   stroke-width="2"/>
          
          <!-- 海岸线效果 -->
          <path d="M 300,500 Q 400,480 500,500 T 700,500" 
                fill="none" 
                stroke="rgba(78, 205, 196, 0.3)" 
                stroke-width="3"/>
        </svg>
      </div>
      
      <!-- 海陵岛标注（脉冲动画） -->
      <div class="ranch-marker" :style="markerPosition">
        <div class="pulse-ring"></div>
        <div class="pulse-ring pulse-ring-delay"></div>
        <div class="marker-dot"></div>
        <div class="marker-label">
          {{ ranchInfo.name }}
        </div>
      </div>
      
      <!-- 参照城市标注 -->
      <div class="city-marker" 
           v-for="city in cities" 
           :key="city.name"
           :style="getCityPosition(city)">
        <div class="city-dot"></div>
        <div class="city-label">{{ city.name }}</div>
      </div>
      
      <!-- 网箱位置标注 -->
      <div class="cage-marker"
           v-for="(cage, index) in cages"
           :key="index"
           :style="getCagePosition(cage)">
        <div class="cage-icon">🏭</div>
      </div>
    </div>
    
    <!-- 信息面板 -->
    <div class="info-panel">
      <h3>📍 {{ ranchInfo.name }}</h3>
      <div class="info-item">
        <span class="label">位置：</span>
        <span class="value">{{ ranchInfo.description }}</span>
      </div>
      <div class="info-item">
        <span class="label">经度：</span>
        <span class="value">{{ ranchInfo.longitude }}°E</span>
      </div>
      <div class="info-item">
        <span class="label">纬度：</span>
        <span class="value">{{ ranchInfo.latitude }}°N</span>
      </div>
      <div class="info-item">
        <span class="label">面积：</span>
        <span class="value">{{ ranchInfo.area }}</span>
      </div>
      <div class="info-item">
        <span class="label">水深：</span>
        <span class="value">{{ ranchInfo.depth }}</span>
      </div>
    </div>
    
    <!-- 控制按钮 -->
    <div class="controls">
      <el-button-group>
        <el-button size="small" type="primary" @click="zoomLevel = 1">
          全国视图
        </el-button>
        <el-button size="small" type="primary" @click="zoomLevel = 2">
          广东省
        </el-button>
        <el-button size="small" type="primary" @click="zoomLevel = 3">
          海陵岛
        </el-button>
      </el-button-group>
    </div>
    
    <!-- 图例 -->
    <div class="legend">
      <div class="legend-item">
        <div class="legend-icon ranch"></div>
        <span>海洋牧场</span>
      </div>
      <div class="legend-item">
        <div class="legend-icon city"></div>
        <span>参照城市</span>
      </div>
      <div class="legend-item">
        <div class="legend-icon cage"></div>
        <span>养殖网箱</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import axios from 'axios'

const mapContainer = ref(null)
const zoomLevel = ref(2)  // 1=全国, 2=广东, 3=海陵岛

const ranchInfo = ref({
  name: '海陵岛智慧海洋牧场',
  longitude: 111.9,
  latitude: 21.6,
  area: '500公顷',
  depth: '15-30米',
  description: '广东省阳江市海陵岛附近海域'
})

// 参照城市（相对位置）
const cities = [
  { name: '阳江', x: 650, y: 540 },
  { name: '广州', x: 700, y: 480 },
  { name: '深圳', x: 750, y: 500 },
  { name: '珠海', x: 720, y: 520 },
  { name: '湛江', x: 600, y: 560 }
]

// 网箱位置（相对牧场的偏移）
const cages = [
  { offsetX: -15, offsetY: -15 },
  { offsetX: 15, offsetY: -15 },
  { offsetX: -15, offsetY: 15 },
  { offsetX: 15, offsetY: 15 }
]

// 牧场标注位置（广东省内，海陵岛位置）
const markerPosition = computed(() => {
  const baseX = 650
  const baseY = 550
  
  // 根据缩放级别调整位置
  const scale = zoomLevel.value === 3 ? 1.5 : zoomLevel.value === 2 ? 1.2 : 1
  
  return {
    left: `${baseX * scale - (scale - 1) * 300}px`,
    top: `${baseY * scale - (scale - 1) * 250}px`,
    transform: `scale(${scale})`
  }
})

// 获取城市位置
const getCityPosition = (city) => {
  const scale = zoomLevel.value === 1 ? 1 : zoomLevel.value === 2 ? 1.1 : 0.8
  return {
    left: `${city.x}px`,
    top: `${city.y}px`,
    opacity: zoomLevel.value === 3 ? 0.3 : 1
  }
}

// 获取网箱位置
const getCagePosition = (cage) => {
  const baseX = 650
  const baseY = 550
  const scale = zoomLevel.value === 3 ? 2 : 1
  
  return {
    left: `${baseX + cage.offsetX * scale}px`,
    top: `${baseY + cage.offsetY * scale}px`,
    opacity: zoomLevel.value === 3 ? 1 : 0
  }
}

onMounted(async () => {
  // 获取牧场信息
  try {
    const response = await axios.get('/api/ranch/location')
    if (response.data.success) {
      ranchInfo.value = response.data.data
    }
  } catch (error) {
    console.log('使用默认牧场信息')
  }
  
  console.log('🗺️ 地图可视化初始化完成')
})
</script>

<style scoped>
.map-visualization {
  width: 100%;
  height: 100%;
  position: relative;
  background: linear-gradient(135deg, #0a1929 0%, #0d2838 50%, #1a2332 100%);
  overflow: hidden;
}

.map-container {
  width: 100%;
  height: 100%;
  position: relative;
}

/* 中国轮廓 */
.china-outline {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 90%;
  height: 90%;
  opacity: 0.8;
}

.china-svg {
  width: 100%;
  height: 100%;
  filter: drop-shadow(0 0 20px rgba(78, 205, 196, 0.3));
}

/* 海陵岛牧场标注 */
.ranch-marker {
  position: absolute;
  z-index: 10;
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.pulse-ring {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 60px;
  height: 60px;
  margin: -30px 0 0 -30px;
  border: 3px solid #ff6b6b;
  border-radius: 50%;
  animation: pulse 2s ease-out infinite;
}

.pulse-ring-delay {
  animation-delay: 1s;
}

@keyframes pulse {
  0% {
    transform: scale(0.5);
    opacity: 1;
  }
  100% {
    transform: scale(2);
    opacity: 0;
  }
}

.marker-dot {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 20px;
  height: 20px;
  margin: -10px 0 0 -10px;
  background: #ff6b6b;
  border-radius: 50%;
  border: 3px solid #fff;
  box-shadow: 0 0 20px rgba(255, 107, 107, 0.8),
              0 0 40px rgba(255, 107, 107, 0.4);
  animation: glow 2s ease-in-out infinite;
}

@keyframes glow {
  0%, 100% {
    box-shadow: 0 0 20px rgba(255, 107, 107, 0.8),
                0 0 40px rgba(255, 107, 107, 0.4);
  }
  50% {
    box-shadow: 0 0 30px rgba(255, 107, 107, 1),
                0 0 60px rgba(255, 107, 107, 0.6);
  }
}

.marker-label {
  position: absolute;
  top: -45px;
  left: 50%;
  transform: translateX(-50%);
  white-space: nowrap;
  background: rgba(255, 107, 107, 0.95);
  color: #fff;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% {
    transform: translateX(-50%) translateY(0);
  }
  50% {
    transform: translateX(-50%) translateY(-5px);
  }
}

/* 城市标注 */
.city-marker {
  position: absolute;
  z-index: 5;
  transition: all 0.5s ease;
}

.city-dot {
  width: 8px;
  height: 8px;
  background: #90caf9;
  border-radius: 50%;
  border: 2px solid #fff;
  box-shadow: 0 0 10px rgba(144, 202, 249, 0.6);
}

.city-label {
  position: absolute;
  top: -25px;
  left: 50%;
  transform: translateX(-50%);
  white-space: nowrap;
  color: #90caf9;
  font-size: 11px;
  background: rgba(13, 71, 161, 0.7);
  padding: 3px 8px;
  border-radius: 3px;
}

/* 网箱标注 */
.cage-marker {
  position: absolute;
  z-index: 8;
  transition: all 0.5s ease;
}

.cage-icon {
  font-size: 20px;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.5));
  animation: bounce 2s ease-in-out infinite;
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

/* 信息面板 */
.info-panel {
  position: absolute;
  top: 20px;
  left: 20px;
  background: rgba(30, 41, 59, 0.95);
  padding: 20px;
  border-radius: 12px;
  color: #fff;
  min-width: 300px;
  border: 1px solid rgba(100, 181, 246, 0.4);
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 20;
}

.info-panel h3 {
  color: #ff6b6b;
  margin-bottom: 15px;
  font-size: 18px;
  border-bottom: 2px solid rgba(255, 107, 107, 0.3);
  padding-bottom: 10px;
  font-weight: 600;
}

.info-item {
  display: flex;
  margin: 10px 0;
  font-size: 14px;
  line-height: 1.6;
}

.info-item .label {
  color: #64b5f6;
  font-weight: 600;
  min-width: 60px;
}

.info-item .value {
  color: #fff;
  flex: 1;
}

/* 控制按钮 */
.controls {
  position: absolute;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 20;
}

/* 图例 */
.legend {
  position: absolute;
  bottom: 30px;
  right: 30px;
  background: rgba(30, 41, 59, 0.9);
  padding: 15px;
  border-radius: 10px;
  border: 1px solid rgba(100, 181, 246, 0.3);
  z-index: 20;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 8px 0;
  color: #fff;
  font-size: 13px;
}

.legend-icon {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid #fff;
}

.legend-icon.ranch {
  background: #ff6b6b;
  box-shadow: 0 0 10px rgba(255, 107, 107, 0.8);
}

.legend-icon.city {
  background: #90caf9;
  box-shadow: 0 0 10px rgba(144, 202, 249, 0.6);
}

.legend-icon.cage {
  background: #ffe66d;
  box-shadow: 0 0 10px rgba(255, 230, 109, 0.6);
}
</style>

