<template>
  <div class="login-container">
    <div class="login-card">
      <h1>智慧海洋牧场</h1>
      <p>临时简化登录页（用于测试）</p>
      
      <div class="form">
        <input 
          v-model="username" 
          placeholder="用户名" 
          @keyup.enter="login"
        />
        <input 
          v-model="password" 
          type="password" 
          placeholder="密码"
          @keyup.enter="login"
        />
        <button @click="login">登录</button>
      </div>
      
      <div class="tip">
        默认账号：admin / 123456
      </div>
      
      <div class="debug" v-if="debugInfo">
        <h3>调试信息：</h3>
        <pre>{{ debugInfo }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const username = ref('admin')
const password = ref('123456')
const debugInfo = ref('')

const login = () => {
  debugInfo.value = '开始登录...\n'
  
  if (username.value === 'admin' && password.value === '123456') {
    debugInfo.value += '✓ 账号密码正确\n'
    
    localStorage.setItem('isLoggedIn', 'true')
    localStorage.setItem('username', username.value)
    debugInfo.value += '✓ 已保存到 localStorage\n'
    
    debugInfo.value += '尝试方式1: window.location.href\n'
    
    // 直接使用 window.location（最可靠的方式）
    setTimeout(() => {
      window.location.href = '/'
    }, 1000)
  } else {
    debugInfo.value += '✗ 账号或密码错误\n'
    alert('用户名或密码错误！')
  }
}
</script>

<style scoped>
.login-container {
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #0a1929 0%, #1a2332 100%);
}

.login-card {
  background: rgba(30, 41, 59, 0.9);
  padding: 40px;
  border-radius: 16px;
  width: 400px;
  color: #fff;
}

h1 {
  text-align: center;
  margin-bottom: 10px;
  color: #64b5f6;
}

p {
  text-align: center;
  margin-bottom: 30px;
  color: #90caf9;
  font-size: 14px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

input {
  padding: 12px;
  border: 1px solid rgba(100, 181, 246, 0.3);
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 14px;
}

input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

button {
  padding: 12px;
  background: linear-gradient(90deg, #1976d2 0%, #64b5f6 100%);
  border: none;
  border-radius: 6px;
  color: #fff;
  font-size: 16px;
  cursor: pointer;
  font-weight: 600;
}

button:hover {
  opacity: 0.9;
}

.tip {
  text-align: center;
  margin-top: 20px;
  color: #90caf9;
  font-size: 13px;
  padding: 10px;
  background: rgba(25, 118, 210, 0.1);
  border-radius: 6px;
}

.debug {
  margin-top: 20px;
  padding: 15px;
  background: rgba(0, 0, 0, 0.3);
  border-radius: 6px;
  font-size: 12px;
}

.debug h3 {
  margin-bottom: 10px;
  color: #ffc107;
}

.debug pre {
  color: #4caf50;
  white-space: pre-wrap;
  word-wrap: break-word;
}
</style>



