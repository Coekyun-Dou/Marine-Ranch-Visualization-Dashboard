<template>
  <div class="trend-chart">
    <div ref="chartRef" class="chart-container"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  historyData: {
    type: Object,
    default: () => ({
      timestamps: [],
      temperature: [],
      ph: [],
      dissolvedOxygen: []
    })
  }
})

const chartRef = ref(null)
let chartInstance = null

const initChart = () => {
  if (!chartRef.value) return

  chartInstance = echarts.init(chartRef.value)

  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        label: {
          backgroundColor: '#6a7985'
        }
      },
      backgroundColor: 'rgba(30, 41, 59, 0.9)',
      borderColor: '#64b5f6',
      textStyle: {
        color: '#fff'
      }
    },
    legend: {
      data: ['水温', 'pH值', '溶氧量'],
      textStyle: {
        color: '#90caf9'
      },
      top: 10
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: [],
      axisLine: {
        lineStyle: {
          color: '#64b5f6'
        }
      },
      axisLabel: {
        color: '#90caf9',
        fontSize: 10
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '水温(°C) / 溶氧(mg/L)',
        position: 'left',
        axisLine: {
          lineStyle: {
            color: '#64b5f6'
          }
        },
        axisLabel: {
          color: '#90caf9'
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(100, 181, 246, 0.1)'
          }
        }
      },
      {
        type: 'value',
        name: 'pH值',
        position: 'right',
        min: 6,
        max: 10,
        axisLine: {
          lineStyle: {
            color: '#64b5f6'
          }
        },
        axisLabel: {
          color: '#90caf9'
        },
        splitLine: {
          show: false
        }
      }
    ],
    series: [
      {
        name: '水温',
        type: 'line',
        smooth: true,
        data: [],
        itemStyle: {
          color: '#ff6b6b'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(255, 107, 107, 0.3)' },
            { offset: 1, color: 'rgba(255, 107, 107, 0.05)' }
          ])
        }
      },
      {
        name: 'pH值',
        type: 'line',
        smooth: true,
        yAxisIndex: 1,
        data: [],
        itemStyle: {
          color: '#4ecdc4'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(78, 205, 196, 0.3)' },
            { offset: 1, color: 'rgba(78, 205, 196, 0.05)' }
          ])
        }
      },
      {
        name: '溶氧量',
        type: 'line',
        smooth: true,
        data: [],
        itemStyle: {
          color: '#ffe66d'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(255, 230, 109, 0.3)' },
            { offset: 1, color: 'rgba(255, 230, 109, 0.05)' }
          ])
        }
      }
    ]
  }

  chartInstance.setOption(option)
}

const updateChart = () => {
  if (!chartInstance) return

  chartInstance.setOption({
    xAxis: {
      data: props.historyData.timestamps
    },
    series: [
      { data: props.historyData.temperature },
      { data: props.historyData.ph },
      { data: props.historyData.dissolvedOxygen }
    ]
  })
}

// 监听数据变化
watch(
  () => props.historyData,
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
.trend-chart {
  width: 100%;
  height: 100%;
}

.chart-container {
  width: 100%;
  height: 320px;
}
</style>



