import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import App from './App.vue'
import router from './router'

console.log('🚀 应用初始化开始...')

const app = createApp(App)

// 注册所有图标
console.log('📦 注册 Element Plus 图标...')
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

console.log('🔌 安装 Element Plus...')
app.use(ElementPlus)

console.log('🗺️ 安装 Vue Router...')
app.use(router)

console.log('📱 挂载应用到 #app...')
app.mount('#app')

console.log('✅ 应用启动成功！')
console.log('当前路由:', router.currentRoute.value.path)

