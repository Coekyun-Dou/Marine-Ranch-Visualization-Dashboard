<template>
  <div class="fish-distribution">
    <div ref="chartRef" class="chart-container"></div>
    <div class="distribution-stats">
      <div class="stat-row" v-for="item in fishData" :key="item.name">
        <span class="fish-name">{{ item.name }}</span>
        <div class="progress-bar">
          <div 
            class="progress-fill" 
            :style="{ width: getPercentage(item.value) + '%' }"
          ></div>
        </div>
        <span class="fish-count">{{ item.value }}</span>
      </div>
      <div class="total-count">
        <span>总数量:</span>
        <span class="total-value">{{ totalCount }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  fishData: {
    type: Array,
    default: () => []
  }
})

const chartRef = ref(null)
let chartInstance = null

const totalCount = computed(() => {
  return props.fishData.reduce((sum, item) => sum + item.value, 0)
})

const getPercentage = (value) => {
  if (totalCount.value === 0) return 0
  return ((value / totalCount.value) * 100).toFixed(1)
}

const initChart = () => {
  if (!chartRef.value) return

  chartInstance = echarts.init(chartRef.value)

  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)',
      backgroundColor: 'rgba(30, 41, 59, 0.9)',
      borderColor: '#64b5f6',
      textStyle: {
        color: '#fff'
      }
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'center',
      textStyle: {
        color: '#90caf9',
        fontSize: 12
      }
    },
    series: [
      {
        name: '鱼类分布',
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['60%', '50%'],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#1e293b',
          borderWidth: 2
        },
        label: {
          show: true,
          formatter: '{b}\n{d}%',
          color: '#fff',
          fontSize: 11
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 14,
            fontWeight: 'bold'
          },
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        },
        labelLine: {
          show: true,
          lineStyle: {
            color: '#64b5f6'
          }
        },
        data: [],
        color: ['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf', '#ffd93d']
      }
    ]
  }

  chartInstance.setOption(option)
}

const updateChart = () => {
  if (!chartInstance) return

  chartInstance.setOption({
    series: [
      {
        data: props.fishData
      }
    ]
  })
}

// 监听数据变化
watch(
  () => props.fishData,
  () => {
    updateChart()
  },
  { deep: true }
)

// 窗口大小改变时重新调整图表
const handleResize = () => {
  if (chartInstance) {
    chartInstance.resize()
  }
}

onMounted(() => {
  initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (chartInstance) {
    chartInstance.dispose()
  }
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.fish-distribution {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.chart-container {
  width: 100%;
  height: 280px;
}

.distribution-stats {
  background: rgba(13, 71, 161, 0.2);
  padding: 15px;
  border-radius: 8px;
  border: 1px solid rgba(100, 181, 246, 0.2);
}

.stat-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.fish-name {
  width: 60px;
  font-size: 13px;
  color: #90caf9;
  flex-shrink: 0;
}

.progress-bar {
  flex: 1;
  height: 18px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 9px;
  overflow: hidden;
  position: relative;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #64b5f6 0%, #1976d2 100%);
  border-radius: 9px;
  transition: width 0.5s ease;
  box-shadow: 0 0 10px rgba(100, 181, 246, 0.5);
}

.fish-count {
  width: 50px;
  text-align: right;
  font-size: 13px;
  font-weight: 600;
  color: #fff;
  flex-shrink: 0;
}

.total-count {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(100, 181, 246, 0.3);
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  color: #90caf9;
}

.total-value {
  font-size: 18px;
  font-weight: 700;
  color: #64b5f6;
}
</style>



