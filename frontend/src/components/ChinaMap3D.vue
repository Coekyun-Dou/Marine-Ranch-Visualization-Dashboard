<template>
  <div class="china-map-container">
    <div ref="mapRef" class="map-chart"></div>
    <div class="ranch-info" v-if="ranchInfo">
      <h3>{{ ranchInfo.name }}</h3>
      <p><strong>位置:</strong> {{ ranchInfo.description }}</p>
      <p><strong>经度:</strong> {{ ranchInfo.longitude }}°E</p>
      <p><strong>纬度:</strong> {{ ranchInfo.latitude }}°N</p>
      <p><strong>面积:</strong> {{ ranchInfo.area }}</p>
      <p><strong>水深:</strong> {{ ranchInfo.depth }}</p>
    </div>
    
    <div class="map-controls">
      <el-button-group>
        <el-button size="small" type="primary" @click="focusChina">
          全国视图
        </el-button>
        <el-button size="small" type="primary" @click="focusGuangdong">
          广东省
        </el-button>
        <el-button size="small" type="primary" @click="focusRanch">
          海陵岛
        </el-button>
      </el-button-group>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'

const mapRef = ref(null)
const ranchInfo = ref(null)
let chart = null

// 中国地图GeoJSON数据（简化版）
const chinaGeoJson = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": { "name": "广东" },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [109.5, 21.0], [110.0, 21.0], [111.0, 21.0], [112.0, 21.5],
          [113.0, 22.0], [114.0, 22.5], [115.0, 23.0], [116.0, 23.5],
          [117.0, 24.0], [117.0, 25.0], [116.5, 25.0], [115.5, 24.5],
          [114.5, 24.0], [113.5, 23.5], [112.5, 23.0], [111.5, 22.5],
          [110.5, 22.0], [109.5, 21.5], [109.5, 21.0]
        ]]
      }
    }
  ]
}

onMounted(async () => {
  // 获取牧场信息
  try {
    const response = await axios.get('/api/ranch/location')
    if (response.data.success) {
      ranchInfo.value = response.data.data
    }
  } catch (error) {
    ranchInfo.value = {
      name: '海陵岛智慧海洋牧场',
      longitude: 111.9,
      latitude: 21.6,
      area: '500公顷',
      depth: '15-30米',
      description: '广东省阳江市海陵岛附近海域'
    }
  }

  setTimeout(initMap, 200)
})

const initMap = () => {
  if (!mapRef.value) return

  console.log('🗺️ 开始初始化中国地图...')

  // 注册中国地图
  echarts.registerMap('china', chinaGeoJson)

  chart = echarts.init(mapRef.value)

  const option = {
    backgroundColor: 'transparent',
    
    // 地理坐标系
    geo: {
      map: 'china',
      roam: true,  // 允许缩放和平移
      zoom: 1.2,
      center: [111.9, 21.6],  // 中心点设为海陵岛
      
      // 地图样式
      itemStyle: {
        areaColor: '#1e3a5f',  // 陆地颜色（深蓝色）
        borderColor: '#4ecdc4',  // 边界颜色（青色）
        borderWidth: 2
      },
      
      // 高亮样式
      emphasis: {
        itemStyle: {
          areaColor: '#2c5282',
          borderColor: '#64b5f6',
          borderWidth: 3
        },
        label: {
          show: true,
          color: '#fff',
          fontSize: 14
        }
      },
      
      // 标签
      label: {
        show: false
      }
    },
    
    // 系列数据
    series: [
      // 海陵岛牧场标注（脉冲动画）
      {
        type: 'effectScatter',
        coordinateSystem: 'geo',
        zlevel: 2,
        rippleEffect: {
          brushType: 'stroke',
          period: 3,
          scale: 5
        },
        label: {
          show: true,
          formatter: '{b}',
          position: 'top',
          color: '#fff',
          fontSize: 16,
          fontWeight: 'bold',
          backgroundColor: 'rgba(255, 107, 107, 0.9)',
          padding: [8, 16],
          borderRadius: 6,
          shadowBlur: 10,
          shadowColor: 'rgba(255, 107, 107, 0.5)'
        },
        itemStyle: {
          color: '#ff6b6b',
          shadowBlur: 30,
          shadowColor: '#ff6b6b'
        },
        symbolSize: 25,
        data: [
          {
            name: ranchInfo.value?.name || '海陵岛海洋牧场',
            value: [
              ranchInfo.value?.longitude || 111.9,
              ranchInfo.value?.latitude || 21.6,
              100
            ]
          }
        ]
      },
      
      // 牧场范围圆圈
      {
        type: 'scatter',
        coordinateSystem: 'geo',
        zlevel: 1,
        symbol: 'circle',
        symbolSize: 80,
        itemStyle: {
          color: 'rgba(78, 205, 196, 0.15)',
          borderColor: '#4ecdc4',
          borderWidth: 2,
          shadowBlur: 20,
          shadowColor: 'rgba(78, 205, 196, 0.5)'
        },
        data: [
          {
            name: '牧场范围',
            value: [
              ranchInfo.value?.longitude || 111.9,
              ranchInfo.value?.latitude || 21.6
            ]
          }
        ]
      },
      
      // 附近城市参照点
      {
        type: 'scatter',
        coordinateSystem: 'geo',
        symbolSize: 10,
        itemStyle: {
          color: '#90caf9',
          borderColor: '#fff',
          borderWidth: 1.5
        },
        label: {
          show: true,
          position: 'right',
          color: '#90caf9',
          fontSize: 12,
          fontWeight: '500',
          backgroundColor: 'rgba(13, 71, 161, 0.6)',
          padding: [4, 8],
          borderRadius: 4
        },
        data: [
          { name: '阳江市', value: [111.98, 21.85] },
          { name: '广州市', value: [113.26, 23.13] },
          { name: '深圳市', value: [114.06, 22.55] },
          { name: '珠海市', value: [113.58, 22.27] },
          { name: '湛江市', value: [110.36, 21.27] }
        ]
      }
    ]
  }

  chart.setOption(option)
  
  console.log('✅ 中国地图配置设置成功')
  
  // 窗口大小改变时重新渲染
  window.addEventListener('resize', handleResize)
  
  // 2秒后自动聚焦到牧场位置
  setTimeout(() => {
    focusRanch()
  }, 2000)
  
  console.log('🗺️ 中国地图初始化完成！')
}

// 聚焦中国
const focusChina = () => {
  if (!chart) return
  chart.setOption({
    geo: {
      center: [105, 35],
      zoom: 1.2
    }
  })
}

// 聚焦广东
const focusGuangdong = () => {
  if (!chart) return
  chart.setOption({
    geo: {
      center: [113.5, 23.0],
      zoom: 5
    }
  })
}

// 聚焦牧场
const focusRanch = () => {
  if (!chart) return
  chart.setOption({
    geo: {
      center: [111.9, 21.6],
      zoom: 8
    }
  })
}

// 窗口大小改变
const handleResize = () => {
  if (chart) {
    chart.resize()
  }
}

onUnmounted(() => {
  if (chart) {
    chart.dispose()
  }
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.china-map-container {
  width: 100%;
  height: 100%;
  min-height: 600px;
  position: relative;
  background: linear-gradient(135deg, #0a1929 0%, #1a2332 100%);
  overflow: hidden;
}

.map-chart {
  width: 100%;
  height: 100%;
  min-height: 600px;
}

.ranch-info {
  position: absolute;
  top: 20px;
  left: 20px;
  background: rgba(30, 41, 59, 0.95);
  padding: 20px;
  border-radius: 12px;
  color: #fff;
  min-width: 280px;
  max-width: 320px;
  border: 1px solid rgba(100, 181, 246, 0.4);
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 10;
  animation: slideIn 0.6s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(-30px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.ranch-info h3 {
  color: #ff6b6b;
  margin-bottom: 12px;
  font-size: 18px;
  border-bottom: 2px solid rgba(255, 107, 107, 0.3);
  padding-bottom: 8px;
  font-weight: 600;
}

.ranch-info p {
  margin: 8px 0;
  font-size: 14px;
  line-height: 1.8;
}

.ranch-info strong {
  color: #64b5f6;
  font-weight: 600;
}

.map-controls {
  position: absolute;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 10;
}

.map-controls :deep(.el-button) {
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}
</style>
