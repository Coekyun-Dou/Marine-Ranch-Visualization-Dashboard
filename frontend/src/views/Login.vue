<template>
  <div class="login-container">
    <!-- 背景动画 -->
    <div class="bg-animation">
      <div class="wave wave1"></div>
      <div class="wave wave2"></div>
      <div class="wave wave3"></div>
    </div>

    <!-- 登录卡片 -->
    <div class="login-card">
      <div class="login-header">
        <div class="logo">
          <span class="logo-icon">🌊</span>
        </div>
        <h1 class="title">海穹慧眼</h1>
        <p class="subtitle">智慧海洋牧场可视化监控平台</p>
      </div>

      <el-form 
        ref="loginFormRef" 
        :model="loginForm" 
        :rules="rules" 
        class="login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginForm.username"
            placeholder="请输入用户名"
            size="large"
            clearable
          >
            <template #prefix>
              <el-icon><User /></el-icon>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            show-password
            @keyup.enter="handleLogin"
          >
            <template #prefix>
              <el-icon><Lock /></el-icon>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item>
          <el-checkbox v-model="loginForm.remember">记住密码</el-checkbox>
        </el-form-item>

        <el-form-item>
          <el-button 
            type="primary" 
            size="large" 
            class="login-btn"
            :loading="loading"
            @click="handleLogin"
          >
            {{ loading ? '登录中...' : '登 录' }}
          </el-button>
        </el-form-item>
      </el-form>

      <div class="login-footer">
        <p class="demo-tip">
          <el-icon><InfoFilled /></el-icon>
          演示账号：admin / 123456
        </p>
      </div>
    </div>

    <!-- 版权信息 -->
    <div class="copyright">
      <p>© 2025 海穹慧眼：智慧海洋牧场可视化平台 | 广东海洋大学AI应用创新团队研发</p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, InfoFilled } from '@element-plus/icons-vue'

const router = useRouter()
const loginFormRef = ref(null)
const loading = ref(false)

const loginForm = reactive({
  username: '',
  password: '',
  remember: false
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在 6 到 20 个字符', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  try {
    const valid = await loginFormRef.value.validate()
    if (valid) {
      loading.value = true
      
      // 简单的演示登录验证
      if (loginForm.username === 'admin' && loginForm.password === '123456') {
        // 保存登录状态
        localStorage.setItem('isLoggedIn', 'true')
        localStorage.setItem('username', loginForm.username)
        
        console.log('✅ 登录信息已保存')
        console.log('📍 使用 window.location 直接跳转...')
        
        ElMessage.success('登录成功！正在跳转...')
        
        // 直接使用最可靠的方式跳转，不依赖路由
        setTimeout(() => {
          window.location.href = '/'
        }, 800)
        
      } else {
        ElMessage.error('用户名或密码错误！')
        loading.value = false
      }
    }
  } catch (error) {
    console.error('❌ 表单验证失败:', error)
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #0a1929 0%, #1a2332 50%, #0d2838 100%);
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  overflow: hidden;
}

/* 背景动画 */
.bg-animation {
  position: absolute;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.wave {
  position: absolute;
  bottom: 0;
  left: 50%;
  width: 200%;
  height: 200%;
  transform: translateX(-50%);
  border-radius: 45%;
  opacity: 0.1;
}

.wave1 {
  background: linear-gradient(180deg, transparent, #1976d2);
  animation: wave 10s linear infinite;
}

.wave2 {
  background: linear-gradient(180deg, transparent, #64b5f6);
  animation: wave 15s linear infinite;
  animation-delay: -5s;
}

.wave3 {
  background: linear-gradient(180deg, transparent, #0d47a1);
  animation: wave 20s linear infinite;
  animation-delay: -10s;
}

@keyframes wave {
  0% {
    transform: translateX(-50%) rotate(0deg);
  }
  100% {
    transform: translateX(-50%) rotate(360deg);
  }
}

/* 登录卡片 */
.login-card {
  width: 450px;
  background: rgba(30, 41, 59, 0.9);
  backdrop-filter: blur(20px);
  border-radius: 20px;
  padding: 50px 40px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.1);
  position: relative;
  z-index: 1;
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
}

.logo {
  margin-bottom: 20px;
}

.logo-icon {
  font-size: 64px;
  display: inline-block;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.title {
  font-size: 32px;
  color: #fff;
  margin-bottom: 8px;
  font-weight: 600;
  letter-spacing: 2px;
}

.subtitle {
  font-size: 16px;
  color: #90caf9;
  letter-spacing: 4px;
}

.login-form {
  margin-top: 30px;
}

.login-btn {
  width: 100%;
  height: 48px;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: 2px;
  background: linear-gradient(90deg, #1976d2 0%, #64b5f6 100%);
  border: none;
  transition: all 0.3s ease;
}

.login-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(25, 118, 210, 0.4);
}

.login-footer {
  margin-top: 20px;
}

.demo-tip {
  text-align: center;
  color: #90caf9;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 12px;
  background: rgba(25, 118, 210, 0.1);
  border-radius: 8px;
  border: 1px solid rgba(100, 181, 246, 0.2);
}

/* 版权信息 */
.copyright {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
  z-index: 1;
}

/* 响应式 */
@media (max-width: 768px) {
  .login-card {
    width: 90%;
    padding: 40px 30px;
  }
}
</style>

