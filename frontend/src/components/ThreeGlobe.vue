<template>
  <div class="three-globe-container" ref="containerRef">
    <div class="loading-overlay" v-if="loading">
      <div class="loading-spinner"></div>
      <div class="loading-text">正在加载高清卫星纹理...</div>
    </div>
    
    <div class="ranch-info" v-if="ranchInfo">
      <h3>{{ ranchInfo.name }}</h3>
      <div class="info-row">
        <span class="label">位置：</span>
        <span class="value">{{ ranchInfo.description }}</span>
      </div>
      <div class="info-row">
        <span class="label">坐标：</span>
        <span class="value">{{ ranchInfo.longitude }}°E, {{ ranchInfo.latitude }}°N</span>
      </div>
      <div class="info-stats">
        <div class="stat">
          <div class="num">{{ ranchInfo.area }}</div>
          <div class="txt">海域面积</div>
        </div>
        <div class="stat">
          <div class="num">{{ ranchInfo.depth }}</div>
          <div class="txt">平均水深</div>
        </div>
      </div>
    </div>
    
    <div class="controls">
      <div class="control-btn" @click="resetCamera" title="重置视角">
        ⟲
      </div>
      <div class="control-btn" @click="toggleRotation" :title="autoRotate ? '暂停旋转' : '开始旋转'">
        {{ autoRotate ? '⏸' : '▶' }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'
import axios from 'axios'

const containerRef = ref(null)
const loading = ref(true)
const ranchInfo = ref(null)
const autoRotate = ref(true)

// Three.js 变量
let scene, camera, renderer, controls
let earth, clouds, stars, marker
let animationId

// 牧场坐标（海陵岛）
const RANCH_POS = { lng: 111.9, lat: 21.6 }

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

  // 初始化 3D 场景
  initThree()
  animate()
  
  window.addEventListener('resize', onWindowResize)
})

onUnmounted(() => {
  if (animationId) cancelAnimationFrame(animationId)
  window.removeEventListener('resize', onWindowResize)
  
  // 清理资源
  if (renderer) {
    renderer.dispose()
    renderer.forceContextLoss()
  }
  if (scene) {
    scene.traverse((object) => {
      if (object.geometry) object.geometry.dispose()
      if (object.material) {
        if (Array.isArray(object.material)) {
          object.material.forEach(m => m.dispose())
        } else {
          object.material.dispose()
        }
      }
      if (object.type === 'Texture') object.dispose()
    })
  }
})

const initThree = () => {
  if (!containerRef.value) return

  const width = containerRef.value.clientWidth
  const height = containerRef.value.clientHeight

  // 1. 场景
  scene = new THREE.Scene()
  scene.background = new THREE.Color(0x020509) // 深空背景

  // 2. 相机
  camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000)
  camera.position.z = 22
  camera.position.y = 5

  // 3. 渲染器
  renderer = new THREE.WebGLRenderer({ 
    antialias: true,
    alpha: true
  })
  renderer.setSize(width, height)
  renderer.setPixelRatio(window.devicePixelRatio)
  // 开启阴影映射
  renderer.shadowMap.enabled = true
  containerRef.value.appendChild(renderer.domElement)

  // 4. 控制器
  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.05
  controls.rotateSpeed = 0.5
  controls.minDistance = 10
  controls.maxDistance = 50
  controls.autoRotate = true
  controls.autoRotateSpeed = 0.8

  // 5. 加载纹理并创建地球
  const textureLoader = new THREE.TextureLoader()
  
  // 预加载所有纹理
  Promise.all([
    loadTexture(textureLoader, '/textures/earth_map.jpg'),
    loadTexture(textureLoader, '/textures/earth_spec.jpg'),
    loadTexture(textureLoader, '/textures/earth_normal.jpg'),
    loadTexture(textureLoader, '/textures/earth_clouds.png')
  ]).then(([map, spec, normal, cloudMap]) => {
    createRealEarth(map, spec, normal)
    createRealClouds(cloudMap)
    createStars()
    createAtmosphereGlow()
    createMarker()
    loading.value = false
  }).catch(err => {
    console.error('纹理加载失败，回退到纯色模式', err)
    // 如果加载失败（比如用户没运行下载脚本），回退到简单模式
    createSimpleEarth()
    loading.value = false
  })

  // 6. 灯光系统
  const ambientLight = new THREE.AmbientLight(0x333333)
  scene.add(ambientLight)

  // 主光源（模拟太阳）
  const sunLight = new THREE.DirectionalLight(0xffffff, 1.2)
  sunLight.position.set(50, 20, 30)
  sunLight.castShadow = true
  scene.add(sunLight)
  
  // 补光（蓝色边缘光）
  const rimLight = new THREE.SpotLight(0x4455ff, 1.5)
  rimLight.position.set(-20, 20, 30)
  rimLight.lookAt(0,0,0)
  scene.add(rimLight)
}

const loadTexture = (loader, url) => {
  return new Promise((resolve, reject) => {
    loader.load(
      url,
      (texture) => resolve(texture),
      undefined,
      (err) => reject(err)
    )
  })
}

const createRealEarth = (map, spec, normal) => {
  const geometry = new THREE.SphereGeometry(5, 64, 64)
  const material = new THREE.MeshPhongMaterial({
    map: map,             // 地表纹理
    specularMap: spec,    // 高光纹理（控制海洋反光，陆地哑光）
    normalMap: normal,    // 法线纹理（模拟山脉地形）
    specular: new THREE.Color(0x333333), // 反光颜色
    shininess: 15         // 反光亮度
  })
  
  earth = new THREE.Mesh(geometry, material)
  scene.add(earth)
}

const createRealClouds = (cloudMap) => {
  const geometry = new THREE.SphereGeometry(5.05, 64, 64)
  const material = new THREE.MeshLambertMaterial({
    map: cloudMap,
    transparent: true,
    opacity: 0.8,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide
  })
  
  clouds = new THREE.Mesh(geometry, material)
  scene.add(clouds)
}

// 回退模式（如果纹理不存在）
const createSimpleEarth = () => {
  const geometry = new THREE.SphereGeometry(5, 64, 64)
  const material = new THREE.MeshPhongMaterial({
    color: 0x1c4e8a,
    emissive: 0x001122,
    specular: 0x111111,
    shininess: 10
  })
  earth = new THREE.Mesh(geometry, material)
  scene.add(earth)
}

const createAtmosphereGlow = () => {
  // 大气辉光 Shader
  const vertexShader = `
    varying vec3 vNormal;
    void main() {
      vNormal = normalize(normalMatrix * normal);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `
  const fragmentShader = `
    varying vec3 vNormal;
    void main() {
      float intensity = pow(0.6 - dot(vNormal, vec3(0, 0, 1.0)), 4.0);
      gl_FragColor = vec4(0.3, 0.6, 1.0, 1.0) * intensity;
    }
  `
  
  const geometry = new THREE.SphereGeometry(5.2, 64, 64)
  const material = new THREE.ShaderMaterial({
    vertexShader,
    fragmentShader,
    side: THREE.BackSide,
    blending: THREE.AdditiveBlending,
    transparent: true
  })
  
  const glow = new THREE.Mesh(geometry, material)
  scene.add(glow)
}

const createStars = () => {
  const geometry = new THREE.BufferGeometry()
  const count = 3000
  const positions = new Float32Array(count * 3)
  
  for(let i = 0; i < count * 3; i += 3) {
    const r = 40 + Math.random() * 60
    const theta = Math.random() * Math.PI * 2
    const phi = Math.acos(2 * Math.random() - 1)
    
    positions[i] = r * Math.sin(phi) * Math.cos(theta)
    positions[i+1] = r * Math.sin(phi) * Math.sin(theta)
    positions[i+2] = r * Math.cos(phi)
  }
  
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
  const material = new THREE.PointsMaterial({
    size: 0.15,
    color: 0xffffff,
    transparent: true,
    opacity: 0.8
  })
  
  stars = new THREE.Points(geometry, material)
  scene.add(stars)
}

const latLngToVector3 = (lat, lng, radius) => {
  const phi = (90 - lat) * (Math.PI / 180)
  const theta = (lng + 180) * (Math.PI / 180)
  
  const x = -(radius * Math.sin(phi) * Math.cos(theta))
  const z = radius * Math.sin(phi) * Math.sin(theta)
  const y = radius * Math.cos(phi)
  
  return new THREE.Vector3(x, y, z)
}

const createMarker = () => {
  const radius = 5
  const position = latLngToVector3(RANCH_POS.lat, RANCH_POS.lng, radius)
  
  // 1. 标记点球体
  const sphereGeo = new THREE.SphereGeometry(0.08, 16, 16)
  const sphereMat = new THREE.MeshBasicMaterial({ color: 0xff3333 })
  const sphere = new THREE.Mesh(sphereGeo, sphereMat)
  sphere.position.copy(position)
  scene.add(sphere)

  // 2. 光柱
  const geometry = new THREE.CylinderGeometry(0.02, 0.02, 1.5, 8)
  geometry.translate(0, 0.75, 0)
  geometry.rotateX(Math.PI / 2)
  
  const material = new THREE.MeshBasicMaterial({
    color: 0xff3333,
    transparent: true,
    opacity: 0.8
  })
  
  marker = new THREE.Mesh(geometry, material)
  marker.position.copy(position)
  marker.lookAt(new THREE.Vector3(0, 0, 0))
  scene.add(marker)
  
  // 3. 动态波纹圈
  const ringGeometry = new THREE.RingGeometry(0.1, 0.15, 32)
  const ringMaterial = new THREE.MeshBasicMaterial({
    color: 0xff3333,
    transparent: true,
    opacity: 0.8,
    side: THREE.DoubleSide
  })
  const ring = new THREE.Mesh(ringGeometry, ringMaterial)
  ring.position.copy(latLngToVector3(RANCH_POS.lat, RANCH_POS.lng, radius + 0.01))
  ring.lookAt(new THREE.Vector3(0, 0, 0))
  scene.add(ring)
  
  // 动画中用到
  ring.userData = { scale: 1 }
  marker.userData = { ring: ring }
}

const animate = () => {
  animationId = requestAnimationFrame(animate)
  
  if (controls && autoRotate.value) {
    controls.update()
  }
  
  if (renderer && scene && camera) {
    renderer.render(scene, camera)
  }
  
  // 云层独立旋转（比地球稍快）
  if (clouds) {
    clouds.rotation.y += 0.0003
  }
  
  // 地球本体由 controls 自动旋转，不需要手动加
  
  // 波纹扩散动画
  if (marker && marker.userData.ring) {
    const ring = marker.userData.ring
    ring.userData.scale += 0.02
    if (ring.userData.scale > 2.5) ring.userData.scale = 1
    
    ring.scale.setScalar(ring.userData.scale)
    ring.material.opacity = 1 - (ring.userData.scale - 1) / 1.5
  }
}

const onWindowResize = () => {
  if (!containerRef.value || !camera || !renderer) return
  
  const width = containerRef.value.clientWidth
  const height = containerRef.value.clientHeight
  
  camera.aspect = width / height
  camera.updateProjectionMatrix()
  
  renderer.setSize(width, height)
}

const resetCamera = () => {
  if (controls) controls.reset()
}

const toggleRotation = () => {
  autoRotate.value = !autoRotate.value
  if (controls) controls.autoRotate = autoRotate.value
}
</script>

<style scoped>
.three-globe-container {
  width: 100%;
  height: 100%;
  min-height: 600px;
  position: relative;
  background: radial-gradient(circle at center, #0a121e 0%, #000000 100%); /* 更深邃的背景 */
  overflow: hidden;
}

.loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.loading-spinner {
  width: 50px;
  height: 50px;
  border: 3px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  border-top-color: #fff;
  animation: spin 1s ease-in-out infinite;
  margin-bottom: 20px;
}

.loading-text {
  color: #fff;
  font-family: 'Microsoft YaHei';
  font-size: 14px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* 保持原有样式 */
.ranch-info {
  position: absolute;
  top: 20px;
  left: 20px;
  background: rgba(10, 15, 20, 0.85);
  padding: 20px;
  border-radius: 8px;
  color: #fff;
  min-width: 260px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.ranch-info h3 {
  color: #fff;
  margin-bottom: 15px;
  font-size: 18px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding-bottom: 10px;
}

.info-row {
  display: flex;
  margin-bottom: 8px;
  font-size: 13px;
}

.info-row .label {
  color: #aaa;
  width: 50px;
}

.info-row .value {
  color: #fff;
  flex: 1;
}

.info-stats {
  display: flex;
  justify-content: space-between;
  margin-top: 15px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 15px;
}

.stat {
  text-align: center;
  flex: 1;
}

.stat .num {
  font-size: 20px;
  font-weight: bold;
  color: #4facfe;
  margin-bottom: 4px;
}

.stat .txt {
  font-size: 12px;
  color: #aaa;
}

.controls {
  position: absolute;
  bottom: 30px;
  right: 30px;
  display: flex;
  gap: 10px;
  z-index: 10;
}

.control-btn {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 18px;
}

.control-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}
</style>
