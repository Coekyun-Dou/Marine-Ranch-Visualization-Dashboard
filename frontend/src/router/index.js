import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { title: '登录 - 智慧海洋牧场' }
  },
  {
    path: '/login-simple',
    name: 'LoginSimple',
    component: () => import('../views/LoginSimple.vue'),
    meta: { title: '简化登录（测试）' }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('../views/Dashboard.vue').catch(err => {
      console.error('❌ Dashboard 组件加载失败:', err)
      return import('../views/Login.vue') // 加载失败时回退到登录页
    }),
    meta: { title: '综合监控 - 智慧海洋牧场', requiresAuth: true }
  },
  {
    path: '/water-quality',
    name: 'WaterQuality',
    component: () => import('../views/WaterQuality.vue').catch(err => {
      console.error('❌ WaterQuality 组件加载失败:', err)
      return import('../views/Dashboard.vue')
    }),
    meta: { title: '水质监控 - 智慧海洋牧场', requiresAuth: true }
  },
  {
    path: '/fish-monitor',
    name: 'FishMonitor',
    component: () => import('../views/FishMonitor.vue').catch(err => {
      console.error('❌ FishMonitor 组件加载失败:', err)
      return import('../views/Dashboard.vue')
    }),
    meta: { title: '鱼群监控 - 智慧海洋牧场', requiresAuth: true }
  },
  {
    path: '/hydro-monitor',
    name: 'HydroMonitor',
    component: () => import('../views/HydroMonitor.vue').catch(err => {
      console.error('❌ HydroMonitor 组件加载失败:', err)
      return import('../views/Dashboard.vue')
    }),
    meta: { title: '水文检测 - 智慧海洋牧场', requiresAuth: true }
  },
  {
    path: '/ai-assistant',
    name: 'AIAssistant',
    component: () => import('../views/AIAssistant.vue').catch(err => {
      console.error('❌ AIAssistant 组件加载失败:', err)
      return import('../views/Dashboard.vue')
    }),
    meta: { title: 'AI管理助手 - 智慧海洋牧场', requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫（简单的登录检查）
router.beforeEach((to, from, next) => {
  console.log('路由跳转:', from.path, '->', to.path)
  
  // 更新页面标题
  document.title = to.meta.title || '智慧海洋牧场可视化平台'
  
  // 检查是否需要登录
  if (to.meta.requiresAuth) {
    const isLoggedIn = localStorage.getItem('isLoggedIn')
    console.log('登录状态:', isLoggedIn)
    
    if (!isLoggedIn || isLoggedIn !== 'true') {
      console.log('未登录，跳转到登录页')
      next('/login')
    } else {
      console.log('已登录，允许访问')
      next()
    }
  } else {
    // 如果已登录且访问登录页，重定向到首页
    if (to.path === '/login') {
      const isLoggedIn = localStorage.getItem('isLoggedIn')
      if (isLoggedIn === 'true') {
        console.log('已登录，从登录页重定向到首页')
        next('/')
        return
      }
    }
    next()
  }
})

// 路由错误处理
router.onError((error) => {
  console.error('路由错误:', error)
})

export default router

