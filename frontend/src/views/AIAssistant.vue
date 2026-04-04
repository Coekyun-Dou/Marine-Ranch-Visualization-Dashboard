<template>
  <div class="ai-assistant-container">
    <!-- 顶部导航栏 -->
    <header class="dashboard-header">
      <div class="header-content">
        <div class="logo-area">
          <span class="logo-icon">🤖</span>
          <h1>智慧海洋牧场 - AI管理助手</h1>
        </div>
        
        <nav class="nav-menu">
          <router-link to="/" class="nav-item">
            <el-icon><Odometer /></el-icon>
            <span>综合监控</span>
          </router-link>
          <router-link to="/water-quality" class="nav-item">
            <el-icon><Goblet /></el-icon>
            <span>水质监控</span>
          </router-link>
          <router-link to="/fish-monitor" class="nav-item">
            <el-icon><Camera /></el-icon>
            <span>鱼群监控</span>
          </router-link>
          <router-link to="/hydro-monitor" class="nav-item">
            <el-icon><Compass /></el-icon>
            <span>水文检测</span>
          </router-link>
          <router-link to="/ai-assistant" class="nav-item active">
            <el-icon><ChatDotRound /></el-icon>
            <span>AI助手</span>
          </router-link>
        </nav>

        <div class="status-area">
          <el-tag :type="connected ? 'success' : 'danger'" effect="dark">
            {{ connected ? '🟢 AI在线' : '🔴 AI离线' }}
          </el-tag>
          <span class="time">{{ currentTime }}</span>
          <el-dropdown @command="handleCommand">
            <div class="user-info">
              <el-icon><User /></el-icon>
              <span>{{ username }}</span>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </header>

    <!-- 主体内容 -->
    <main class="assistant-main">
      <!-- 左侧面板：快捷操作 -->
      <aside class="left-panel">
        <div class="panel-section">
          <div class="section-title">
            <el-icon><Management /></el-icon>
            <span>快捷功能</span>
          </div>
          
          <div class="quick-actions">
            <el-button 
              v-for="action in quickActions" 
              :key="action.id"
              :type="action.type"
              :icon="action.icon"
              @click="sendQuickQuestion(action.question)"
              class="action-btn"
            >
              {{ action.label }}
            </el-button>
          </div>
        </div>

        <div class="panel-section">
          <div class="section-title">
            <el-icon><Document /></el-icon>
            <span>数据上传</span>
          </div>
          
          <el-upload
            class="upload-area"
            drag
            :auto-upload="false"
            :on-change="handleFileUpload"
            accept=".csv,.xlsx,.xls"
          >
            <el-icon class="el-icon--upload"><upload-filled /></el-icon>
            <div class="el-upload__text">
              拖拽文件到此处或<em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                支持 CSV、Excel 格式的监测数据
              </div>
            </template>
          </el-upload>
        </div>

        <div class="panel-section">
          <div class="section-title">
            <el-icon><DataLine /></el-icon>
            <span>当前环境数据</span>
          </div>
          
          <div class="current-data">
            <div class="data-item">
              <span class="label">水温：</span>
              <span class="value">{{ sensorData.temperature || '--' }}°C</span>
            </div>
            <div class="data-item">
              <span class="label">pH值：</span>
              <span class="value">{{ sensorData.ph || '--' }}</span>
            </div>
            <div class="data-item">
              <span class="label">溶氧量：</span>
              <span class="value">{{ sensorData.oxygen || '--' }}mg/L</span>
            </div>
          </div>
        </div>
      </aside>

      <!-- 中间：对话区域 -->
      <section class="chat-area">
        <div class="chat-header">
          <h2>💬 智能对话</h2>
          <el-button @click="clearChat" :icon="Delete" size="small">清空对话</el-button>
        </div>
        
        <div class="messages-container" ref="messagesContainer">
          <div v-if="messages.length === 0" class="welcome-message">
            <el-icon class="welcome-icon"><ChatDotRound /></el-icon>
            <h3>欢迎使用AI管理助手</h3>
            <p>我可以帮助您：</p>
            <ul>
              <li>📊 分析水质、水文监测数据</li>
              <li>🐟 提供养殖管理建议</li>
              <li>⚠️ 预警异常情况</li>
              <li>💡 回答养殖相关问题</li>
            </ul>
            <p class="tip">请在下方输入您的问题，或使用左侧快捷功能</p>
          </div>

          <div 
            v-for="(msg, index) in messages" 
            :key="index" 
            :class="['message-item', msg.role]"
          >
            <div class="message-avatar">
              <el-icon v-if="msg.role === 'user'"><User /></el-icon>
              <el-icon v-else><Avatar /></el-icon>
            </div>
            <div class="message-content">
              <div class="message-header">
                <span class="sender">{{ msg.role === 'user' ? '您' : 'AI助手' }}</span>
                <span class="time">{{ msg.time }}</span>
              </div>
              <div class="message-text" v-html="formatMessage(msg.content)"></div>
            </div>
          </div>

          <div v-if="isLoading" class="message-item assistant">
            <div class="message-avatar">
              <el-icon><Avatar /></el-icon>
            </div>
            <div class="message-content">
              <div class="typing-indicator">
                <span></span><span></span><span></span>
              </div>
            </div>
          </div>
        </div>

        <div class="input-area">
          <el-input
            v-model="inputMessage"
            type="textarea"
            :rows="3"
            placeholder="请输入您的问题..."
            @keydown.enter.ctrl="sendMessage"
          />
          <div class="input-actions">
            <span class="tip-text">Ctrl + Enter 发送</span>
            <el-button 
              type="primary" 
              :icon="Position" 
              @click="sendMessage"
              :loading="isLoading"
              :disabled="!inputMessage.trim()"
            >
              发送
            </el-button>
          </div>
        </div>
      </section>

      <!-- 右侧：数据分析结果 -->
      <aside class="right-panel">
        <div class="panel-section">
          <div class="section-title">
            <el-icon><TrendCharts /></el-icon>
            <span>数据分析摘要</span>
          </div>
          
          <div v-if="analysisResult" class="analysis-result">
            <el-alert 
              :title="analysisResult.title" 
              :type="analysisResult.type"
              :closable="false"
              show-icon
            >
              <p>{{ analysisResult.summary }}</p>
            </el-alert>
            
            <div class="result-details">
              <div v-for="item in analysisResult.details" :key="item.label" class="detail-item">
                <span class="detail-label">{{ item.label }}：</span>
                <span class="detail-value" :class="item.status">{{ item.value }}</span>
              </div>
            </div>
          </div>
          
          <div v-else class="no-analysis">
            <el-empty description="暂无分析结果" :image-size="80" />
          </div>
        </div>

        <div class="panel-section">
          <div class="section-title">
            <el-icon><WarningFilled /></el-icon>
            <span>智能建议</span>
          </div>
          
          <div v-if="suggestions.length > 0" class="suggestions-list">
            <div v-for="(sugg, idx) in suggestions" :key="idx" class="suggestion-item">
              <el-icon class="sugg-icon" :color="sugg.color">
                <component :is="sugg.icon" />
              </el-icon>
              <div class="sugg-content">
                <div class="sugg-title">{{ sugg.title }}</div>
                <div class="sugg-desc">{{ sugg.description }}</div>
              </div>
            </div>
          </div>
          
          <div v-else class="no-suggestions">
            <el-empty description="暂无建议" :image-size="60" />
          </div>
        </div>
      </aside>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  Odometer, Goblet, Camera, Compass, ChatDotRound, 
  User, SwitchButton, Management, Document, DataLine,
  Delete, Position, Avatar, TrendCharts, WarningFilled,
  UploadFilled, Bell, Setting, Warning, CircleCheck
} from '@element-plus/icons-vue'
import axios from 'axios'
import { io } from 'socket.io-client'

const router = useRouter()
const username = ref(localStorage.getItem('username') || 'Admin')
const connected = ref(true)
const currentTime = ref('')
const messages = ref([])
const inputMessage = ref('')
const isLoading = ref(false)
const messagesContainer = ref(null)
const sensorData = ref({})
const analysisResult = ref(null)
const suggestions = ref([])
const uploadedData = ref(null)

let socket = null
let timeInterval = null

// 快捷操作
const quickActions = [
  {
    id: 'analyze',
    label: '分析当前水质',
    type: 'primary',
    icon: DataLine,
    question: '请分析当前的水质数据，给出评估和建议'
  },
  {
    id: 'forecast',
    label: '天气影响预测',
    type: 'warning',
    icon: Warning,
    question: '根据当前水文数据，分析未来天气可能的影响'
  },
  {
    id: 'feeding',
    label: '投喂建议',
    type: 'success',
    icon: Bell,
    question: '根据当前环境数据，给出今天的投喂建议'
  },
  {
    id: 'optimization',
    label: '养殖优化',
    type: 'info',
    icon: Setting,
    question: '如何优化当前的养殖环境？'
  }
]

onMounted(() => {
  // 连接 WebSocket 获取实时数据
  socket = io('http://localhost:3000')
  
  socket.on('connect', () => {
    connected.value = true
  })
  
  socket.on('sensorData', (data) => {
    sensorData.value = data
  })
  
  socket.on('disconnect', () => {
    connected.value = false
  })
  
  // 更新时间
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
  
  // 加载历史对话（如果有）
  loadChatHistory()
})

onUnmounted(() => {
  if (socket) {
    socket.disconnect()
  }
  if (timeInterval) {
    clearInterval(timeInterval)
  }
})

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleString('zh-CN', { 
    month: '2-digit', 
    day: '2-digit', 
    hour: '2-digit', 
    minute: '2-digit' 
  })
}

const handleCommand = (command) => {
  if (command === 'logout') {
    localStorage.removeItem('token')
    localStorage.removeItem('username')
    router.push('/login')
  }
}

// 发送消息
const sendMessage = async () => {
  if (!inputMessage.value.trim() || isLoading.value) return
  
  const userMessage = inputMessage.value.trim()
  
  // 添加用户消息
  messages.value.push({
    role: 'user',
    content: userMessage,
    time: new Date().toLocaleTimeString('zh-CN')
  })
  
  inputMessage.value = ''
  scrollToBottom()
  isLoading.value = true
  
  try {
    // 准备上下文数据
    const context = {
      sensorData: sensorData.value,
      uploadedData: uploadedData.value,
      timestamp: new Date().toISOString()
    }
    
    // 调用后端AI接口
    const response = await axios.post('http://localhost:3000/api/ai/chat', {
      message: userMessage,
      context: context
    })
    
    // 添加AI回复
    messages.value.push({
      role: 'assistant',
      content: response.data.reply,
      time: new Date().toLocaleTimeString('zh-CN')
    })
    
    // 更新分析结果和建议
    if (response.data.analysis) {
      analysisResult.value = response.data.analysis
    }
    if (response.data.suggestions) {
      suggestions.value = response.data.suggestions
    }
    
    scrollToBottom()
    saveChatHistory()
  } catch (error) {
    console.error('发送消息失败:', error)
    ElMessage.error('AI响应失败，请稍后重试')
    
    // 添加错误提示
    messages.value.push({
      role: 'assistant',
      content: '抱歉，我现在无法回答您的问题，请稍后重试。',
      time: new Date().toLocaleTimeString('zh-CN')
    })
  } finally {
    isLoading.value = false
  }
}

// 快捷问题
const sendQuickQuestion = (question) => {
  inputMessage.value = question
  sendMessage()
}

// 清空对话
const clearChat = () => {
  messages.value = []
  analysisResult.value = null
  suggestions.value = []
  localStorage.removeItem('chatHistory')
  ElMessage.success('对话已清空')
}

// 滚动到底部
const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  })
}

// 格式化消息（支持换行和简单Markdown）
const formatMessage = (content) => {
  return content
    .replace(/\n/g, '<br>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/`(.*?)`/g, '<code>$1</code>')
}

// 文件上传处理
const handleFileUpload = (file) => {
  ElMessage.info('正在解析文件...')
  
  const reader = new FileReader()
  reader.onload = async (e) => {
    try {
      const content = e.target.result
      
      // 简单的CSV解析
      const lines = content.split('\n')
      const data = lines.slice(1).map(line => {
        const values = line.split(',')
        return {
          timestamp: values[0],
          temperature: parseFloat(values[1]),
          ph: parseFloat(values[2]),
          oxygen: parseFloat(values[3])
        }
      }).filter(item => !isNaN(item.temperature))
      
      uploadedData.value = data
      
      ElMessage.success('文件上传成功')
      
      // 自动发起分析
      inputMessage.value = '请分析我上传的监测数据，给出详细的评估和建议'
      sendMessage()
    } catch (error) {
      console.error('文件解析失败:', error)
      ElMessage.error('文件格式不正确')
    }
  }
  
  reader.readAsText(file.raw)
}

// 保存对话历史
const saveChatHistory = () => {
  localStorage.setItem('chatHistory', JSON.stringify(messages.value.slice(-20))) // 只保存最近20条
}

// 加载对话历史
const loadChatHistory = () => {
  const history = localStorage.getItem('chatHistory')
  if (history) {
    messages.value = JSON.parse(history)
  }
}
</script>

<style scoped>
.ai-assistant-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  overflow: hidden;
}

/* 顶部导航 */
.dashboard-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.header-content {
  max-width: 100%;
  padding: 15px 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-icon {
  font-size: 32px;
}

.logo-area h1 {
  margin: 0;
  font-size: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.nav-menu {
  display: flex;
  gap: 10px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: 8px;
  text-decoration: none;
  color: #666;
  transition: all 0.3s;
  font-size: 14px;
}

.nav-item:hover {
  background: rgba(102, 126, 234, 0.1);
  color: #667eea;
}

.nav-item.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.status-area {
  display: flex;
  align-items: center;
  gap: 15px;
}

.time {
  color: #666;
  font-size: 14px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  padding: 6px 12px;
  border-radius: 6px;
  transition: all 0.3s;
}

.user-info:hover {
  background: rgba(0, 0, 0, 0.05);
}

/* 主体内容 */
.assistant-main {
  flex: 1;
  display: flex;
  gap: 20px;
  padding: 20px;
  overflow: hidden;
}

/* 左侧面板 */
.left-panel {
  width: 280px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  overflow-y: auto;
}

.panel-section {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 15px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: bold;
  color: #333;
  margin-bottom: 12px;
  font-size: 14px;
}

.quick-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.action-btn {
  width: 100%;
  justify-content: flex-start;
}

.upload-area {
  width: 100%;
}

.current-data {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.data-item {
  display: flex;
  justify-content: space-between;
  padding: 8px;
  background: rgba(102, 126, 234, 0.05);
  border-radius: 6px;
  font-size: 13px;
}

.data-item .label {
  color: #666;
}

.data-item .value {
  font-weight: bold;
  color: #667eea;
}

/* 对话区域 */
.chat-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.chat-header {
  padding: 15px 20px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-header h2 {
  margin: 0;
  font-size: 18px;
  color: #333;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.welcome-message {
  text-align: center;
  color: #666;
  padding: 40px 20px;
}

.welcome-icon {
  font-size: 48px;
  color: #667eea;
  margin-bottom: 15px;
}

.welcome-message h3 {
  margin: 15px 0;
  color: #333;
}

.welcome-message ul {
  text-align: left;
  display: inline-block;
  margin: 20px 0;
}

.welcome-message li {
  margin: 8px 0;
}

.tip {
  color: #999;
  font-size: 13px;
  margin-top: 20px;
}

.message-item {
  display: flex;
  gap: 12px;
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-item.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}

.message-item.user .message-avatar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.message-item.assistant .message-avatar {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  color: white;
}

.message-content {
  max-width: 70%;
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.message-item.user .message-content {
  align-items: flex-end;
}

.message-header {
  display: flex;
  gap: 10px;
  align-items: center;
  font-size: 12px;
  color: #999;
}

.message-item.user .message-header {
  flex-direction: row-reverse;
}

.message-text {
  padding: 12px 16px;
  border-radius: 12px;
  line-height: 1.6;
  font-size: 14px;
}

.message-item.user .message-text {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-bottom-right-radius: 4px;
}

.message-item.assistant .message-text {
  background: #f5f5f5;
  color: #333;
  border-bottom-left-radius: 4px;
}

.typing-indicator {
  padding: 12px 16px;
  background: #f5f5f5;
  border-radius: 12px;
  border-bottom-left-radius: 4px;
  display: flex;
  gap: 4px;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #999;
  animation: typing 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.5;
  }
  30% {
    transform: translateY(-10px);
    opacity: 1;
  }
}

.input-area {
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  padding: 15px 20px;
}

.input-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 10px;
}

.tip-text {
  font-size: 12px;
  color: #999;
}

/* 右侧面板 */
.right-panel {
  width: 320px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  overflow-y: auto;
}

.analysis-result {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.result-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 10px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 8px 12px;
  background: rgba(0, 0, 0, 0.02);
  border-radius: 6px;
  font-size: 13px;
}

.detail-label {
  color: #666;
}

.detail-value {
  font-weight: bold;
}

.detail-value.normal {
  color: #67c23a;
}

.detail-value.warning {
  color: #e6a23c;
}

.detail-value.danger {
  color: #f56c6c;
}

.suggestions-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.suggestion-item {
  display: flex;
  gap: 10px;
  padding: 12px;
  background: rgba(102, 126, 234, 0.05);
  border-radius: 8px;
  border-left: 3px solid #667eea;
}

.sugg-icon {
  font-size: 20px;
  flex-shrink: 0;
}

.sugg-content {
  flex: 1;
}

.sugg-title {
  font-weight: bold;
  color: #333;
  font-size: 13px;
  margin-bottom: 4px;
}

.sugg-desc {
  font-size: 12px;
  color: #666;
  line-height: 1.5;
}

.no-analysis,
.no-suggestions {
  padding: 20px;
  text-align: center;
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb {
  background: rgba(102, 126, 234, 0.3);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(102, 126, 234, 0.5);
}
</style>

