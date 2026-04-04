<template>
  <div class="cesium-container">
    <div id="cesiumContainer" ref="cesiumContainer"></div>
    <div class="ranch-info" v-if="ranchInfo">
      <h3>{{ ranchInfo.name }}</h3>
      <p><strong>经度:</strong> {{ ranchInfo.longitude }}°E</p>
      <p><strong>纬度:</strong> {{ ranchInfo.latitude }}°N</p>
      <p><strong>面积:</strong> {{ ranchInfo.area }}</p>
      <p><strong>水深:</strong> {{ ranchInfo.depth }}</p>
      <p class="description">{{ ranchInfo.description }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import * as Cesium from 'cesium'
import axios from 'axios'

const cesiumContainer = ref(null)
const ranchInfo = ref(null)
let viewer = null

onMounted(async () => {
  // 获取牧场位置信息
  try {
    const response = await axios.get('/api/ranch/location')
    if (response.data.success) {
      ranchInfo.value = response.data.data
      initCesium()
    }
  } catch (error) {
    console.error('获取牧场信息失败:', error)
    // 使用默认位置：广东省阳江市海陵岛附近海域
    ranchInfo.value = {
      name: '海陵岛智慧海洋牧场',
      longitude: 111.9,
      latitude: 21.6,
      area: '500公顷',
      depth: '15-30米',
      description: '位于广东省阳江市海陵岛附近海域'
    }
    initCesium()
  }
})

const initCesium = () => {
  try {
    // 配置Cesium Ion访问令牌
    Cesium.Ion.defaultAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlYWE1OWUxNy1mMWZiLTQzYjYtYTQ0OS1kMWFjYmFkNjc5YzYiLCJpZCI6NTc3MzMsImlhdCI6MTYyNzg5Nzk3Mn0.XcKpgANiY19MC4bdFUXMVEBToBmqS8kuYpUlxJHYZxk'

    // 创建Cesium Viewer - 使用Cesium Ion默认底图（最稳定）
    viewer = new Cesium.Viewer(cesiumContainer.value, {
      animation: false,
      timeline: false,
      fullscreenButton: false,
      geocoder: false,
      homeButton: true,
      sceneModePicker: false,
      baseLayerPicker: false,
      navigationHelpButton: false,
      infoBox: true,
      selectionIndicator: true,
      shouldAnimate: false
      // 不指定 imageryProvider，使用 Cesium Ion 默认的全球卫星影像
    })
    
    // 移除版权信息
    viewer.cesiumWidget.creditContainer.style.display = 'none'
    
    // 禁用地下模式
    viewer.scene.globe.depthTestAgainstTerrain = false
    
    console.log('✅ Cesium viewer 初始化成功')
  } catch (error) {
    console.error('Cesium初始化失败:', error)
    return
  }

  // 添加牧场标注
  const position = Cesium.Cartesian3.fromDegrees(
    ranchInfo.value.longitude,
    ranchInfo.value.latitude,
    0
  )

  // 添加点标记
  viewer.entities.add({
    name: ranchInfo.value.name,
    position: position,
    point: {
      pixelSize: 20,
      color: Cesium.Color.fromCssColorString('#FF6B6B'),
      outlineColor: Cesium.Color.WHITE,
      outlineWidth: 3,
      heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
    },
    label: {
      text: ranchInfo.value.name,
      font: '16px Microsoft YaHei',
      fillColor: Cesium.Color.WHITE,
      outlineColor: Cesium.Color.BLACK,
      outlineWidth: 2,
      style: Cesium.LabelStyle.FILL_AND_OUTLINE,
      verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
      pixelOffset: new Cesium.Cartesian2(0, -20),
      heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
    }
  })

  // 添加圆形区域表示牧场范围
  viewer.entities.add({
    name: '牧场范围',
    position: position,
    ellipse: {
      semiMinorAxis: 3000,
      semiMajorAxis: 3000,
      material: Cesium.Color.fromCssColorString('#4ECDC4').withAlpha(0.3),
      outline: true,
      outlineColor: Cesium.Color.fromCssColorString('#4ECDC4'),
      outlineWidth: 2,
      heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
    }
  })

  // 添加养殖网箱（示例）
  const cagePositions = [
    [ranchInfo.value.longitude + 0.01, ranchInfo.value.latitude + 0.01],
    [ranchInfo.value.longitude - 0.01, ranchInfo.value.latitude + 0.01],
    [ranchInfo.value.longitude + 0.01, ranchInfo.value.latitude - 0.01],
    [ranchInfo.value.longitude - 0.01, ranchInfo.value.latitude - 0.01]
  ]

  cagePositions.forEach((pos, index) => {
    viewer.entities.add({
      name: `网箱 ${index + 1}`,
      position: Cesium.Cartesian3.fromDegrees(pos[0], pos[1], 0),
      box: {
        dimensions: new Cesium.Cartesian3(200, 200, 100),
        material: Cesium.Color.fromCssColorString('#FFE66D').withAlpha(0.6),
        outline: true,
        outlineColor: Cesium.Color.fromCssColorString('#FFE66D')
      }
    })
  })

  // 设置相机视角 - 分两步：先看全球，再聚焦到牧场
  
  // 第一步：显示完整地球（从太空视角）
  viewer.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(
      ranchInfo.value.longitude,
      ranchInfo.value.latitude,
      20000000  // 2000万米高度，可以看到整个地球
    ),
    orientation: {
      heading: Cesium.Math.toRadians(0),
      pitch: Cesium.Math.toRadians(-90),  // 俯视
      roll: 0.0
    },
    duration: 2
  })
  
  // 第二步：3秒后聚焦到牧场区域
  setTimeout(() => {
    viewer.camera.flyTo({
      destination: Cesium.Cartesian3.fromDegrees(
        ranchInfo.value.longitude,
        ranchInfo.value.latitude,
        100000  // 10万米高度，可以看到中国南部沿海
      ),
      orientation: {
        heading: Cesium.Math.toRadians(0),
        pitch: Cesium.Math.toRadians(-60),  // 倾斜角度
        roll: 0.0
      },
      duration: 3
    })
  }, 3000)

  // 添加动态水波效果（可选）
  addWaveEffect()
}

// 添加水波动画效果
const addWaveEffect = () => {
  if (!viewer || !ranchInfo.value) return

  let waveRadius = 1000
  const maxRadius = 5000
  const minRadius = 1000

  setInterval(() => {
    waveRadius += 50
    if (waveRadius > maxRadius) {
      waveRadius = minRadius
    }

    const existingWave = viewer.entities.getById('waveEffect')
    if (existingWave) {
      viewer.entities.remove(existingWave)
    }

    viewer.entities.add({
      id: 'waveEffect',
      position: Cesium.Cartesian3.fromDegrees(
        ranchInfo.value.longitude,
        ranchInfo.value.latitude,
        0
      ),
      ellipse: {
        semiMinorAxis: waveRadius,
        semiMajorAxis: waveRadius,
        material: Cesium.Color.fromCssColorString('#00BCD4').withAlpha(
          1 - (waveRadius - minRadius) / (maxRadius - minRadius)
        ),
        outline: true,
        outlineColor: Cesium.Color.fromCssColorString('#00BCD4').withAlpha(
          1 - (waveRadius - minRadius) / (maxRadius - minRadius)
        ),
        heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
      }
    })
  }, 100)
}
</script>

<style scoped>
.cesium-container {
  width: 100%;
  height: 100%;
  position: relative;
}

#cesiumContainer {
  width: 100%;
  height: 100%;
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

.description {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(100, 181, 246, 0.2);
  font-style: italic;
  color: #b0bec5;
}
</style>

