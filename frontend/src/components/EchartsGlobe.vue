<template>
  <div class="echarts-globe-container">
    <div ref="globeRef" class="globe-chart"></div>
    <div class="ranch-info" v-if="ranchInfo">
      <h3>{{ ranchInfo.name }}</h3>
      <p><strong>位置:</strong> {{ ranchInfo.description }}</p>
      <p><strong>经度:</strong> {{ ranchInfo.longitude }}°E</p>
      <p><strong>纬度:</strong> {{ ranchInfo.latitude }}°N</p>
      <p><strong>面积:</strong> {{ ranchInfo.area }}</p>
      <p><strong>水深:</strong> {{ ranchInfo.depth }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import 'echarts-gl'
import axios from 'axios'

// 导入世界地图数据
import worldJson from '../assets/world.json'

const globeRef = ref(null)
const ranchInfo = ref(null)
let chart = null

onMounted(async () => {
  // 获取牧场位置信息
  try {
    const response = await axios.get('/api/ranch/location')
    if (response.data.success) {
      ranchInfo.value = response.data.data
    }
  } catch (error) {
    console.error('获取牧场信息失败:', error)
    ranchInfo.value = {
      name: '海陵岛智慧海洋牧场',
      longitude: 111.9,
      latitude: 21.6,
      area: '500公顷',
      depth: '15-30米',
      description: '广东省阳江市海陵岛附近海域'
    }
  }

  initGlobe()
})

const initGlobe = () => {
  if (!globeRef.value) {
    console.error('❌ globeRef 不存在')
    return
  }

  // 确保容器有宽高
  const rect = globeRef.value.getBoundingClientRect()
  console.log('📐 容器尺寸:', rect.width, 'x', rect.height)
  
  if (rect.width < 100 || rect.height < 100) {
    console.error('❌ 容器尺寸异常，延迟初始化...')
    setTimeout(initGlobe, 500)
    return
  }

  console.log('✅ 开始初始化 ECharts GL...')
  
  try {
    chart = echarts.init(globeRef.value)
    console.log('✅ ECharts 实例创建成功')
    
    // 注册世界地图（如果有数据）
    if (worldJson && worldJson.features) {
      echarts.registerMap('world', worldJson)
      console.log('✅ 世界地图数据已注册')
    }
  } catch (error) {
    console.error('❌ ECharts 初始化失败:', error)
    return
  }

  const option = {
    backgroundColor: 'transparent',
    
    // 3D地球配置
    globe: {
      // 地球基础颜色（深蓝色海洋）
      baseColor: '#0a4f6e',
      
      // 高度
      globeRadius: 100,
      globeOuterRadius: 150,
      
      // 地球大气层效果
      atmosphere: {
        show: true,
        offset: 10,
        color: '#64b5f6',
        glowPower: 8,
        innerGlowPower: 5
      },
      
      // 光照效果
      light: {
        ambient: {
          intensity: 0.6
        },
        main: {
          intensity: 1.8,
          shadow: false,
          alpha: 55,
          beta: 10
        }
      },
      
      // 视角控制
      viewControl: {
        autoRotate: true,
        autoRotateSpeed: 10,
        autoRotateAfterStill: 3,
        distance: 250,
        minDistance: 180,
        maxDistance: 600,
        alpha: 40,
        beta: 0,
        animation: true,
        animationDurationUpdate: 1000,
        animationEasingUpdate: 'cubicInOut'
      },
      
      // 地球表面配置（使用lambert光照模型，更真实）
      shading: 'lambert',
      lambertMaterial: {
        detailTexture: '#2c3e50',  // 陆地颜色（深灰色）
        textureTiling: 1
      }
    },
    
    // 标注点配置
    series: [
      {
        type: 'scatter3D',
        coordinateSystem: 'globe',
        blendMode: 'lighter',
        symbolSize: 8,
        itemStyle: {
          color: '#ff6b6b',
          opacity: 1,
          borderWidth: 2,
          borderColor: '#fff'
        },
        label: {
          show: true,
          position: 'top',
          formatter: '{b}',
          color: '#fff',
          fontSize: 14,
          backgroundColor: 'rgba(0,0,0,0.7)',
          padding: [4, 8],
          borderRadius: 4
        },
        emphasis: {
          label: {
            show: true
          },
          itemStyle: {
            color: '#ff0000'
          }
        },
        data: [
          {
            name: ranchInfo.value?.name || '海陵岛海洋牧场',
            value: [
              ranchInfo.value?.longitude || 111.9,
              ranchInfo.value?.latitude || 21.6,
              0
            ]
          }
        ]
      },
      
      // 附近参照点（广东省主要城市）
      {
        type: 'scatter3D',
        coordinateSystem: 'globe',
        symbolSize: 5,
        itemStyle: {
          color: '#90caf9',
          opacity: 0.6
        },
        label: {
          show: false
        },
        data: [
          { name: '广州', value: [113.3, 23.1, 0] },
          { name: '深圳', value: [114.1, 22.5, 0] },
          { name: '珠海', value: [113.5, 22.2, 0] }
        ]
      }
    ]
  }

  try {
    chart.setOption(option)
    console.log('✅ ECharts 配置设置成功')
  } catch (error) {
    console.error('❌ ECharts 配置失败:', error)
    return
  }

  // 窗口大小改变时重新渲染
  window.addEventListener('resize', handleResize)
  
  // 3秒后聚焦到牧场位置
  setTimeout(() => {
    focusOnRanch()
  }, 3000)
  
  console.log('🌍 ECharts 3D地球初始化完成！')
}

// 聚焦到牧场位置
const focusOnRanch = () => {
  if (!chart) return
  
  chart.setOption({
    globe: {
      viewControl: {
        alpha: 40,
        beta: -20,  // 转向广东方向
        distance: 180,
        animation: true,
        animationDurationUpdate: 2000,
        animationEasingUpdate: 'cubicInOut'
      }
    }
  })
}

// 窗口大小改变
const handleResize = () => {
  if (chart) {
    try {
      chart.resize()
    } catch (error) {
      console.error('❌ 图表 resize 失败:', error)
    }
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
.echarts-globe-container {
  width: 100%;
  height: 100%;
  min-height: 600px;
  position: relative;
  background: radial-gradient(circle at center, #1a1a2e 0%, #0a0a0f 100%);
}

.globe-chart {
  width: 100%;
  height: 100%;
  min-height: 600px;
}

.ranch-info {
  position: absolute;
  top: 20px;
  left: 20px;
  background: rgba(30, 41, 59, 0.9);
  padding: 20px;
  border-radius: 10px;
  color: #fff;
  min-width: 280px;
  border: 1px solid rgba(100, 181, 246, 0.3);
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  z-index: 10;
}

.ranch-info h3 {
  color: #64b5f6;
  margin-bottom: 12px;
  font-size: 18px;
  border-bottom: 2px solid rgba(100, 181, 246, 0.3);
  padding-bottom: 8px;
}

.ranch-info p {
  margin: 8px 0;
  font-size: 14px;
  line-height: 1.5;
}

.ranch-info strong {
  color: #90caf9;
}
</style>

