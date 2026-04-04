<template>
  <div class="current-chart" ref="chartRef"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const chartRef = ref(null)
let chart = null
let currentSpeedData = []
let timeData = []
const MAX_DATA = 30

onMounted(() => {
  initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (chart) {
    chart.dispose()
  }
  window.removeEventListener('resize', handleResize)
})

const initChart = () => {
  if (!chartRef.value) return
  
  chart = echarts.init(chartRef.value)
  
  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(10, 25, 41, 0.9)',
      borderColor: '#64b5f6',
      textStyle: {
        color: '#fff'
      },
      formatter: (params) => {
        const p = params[0]
        return `${p.name}<br/>流速: ${p.value} m/s`
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: timeData,
      boundaryGap: false,
      axisLine: {
        lineStyle: {
          color: '#64b5f6'
        }
      },
      axisLabel: {
        color: '#90caf9'
      }
    },
    yAxis: {
      type: 'value',
      name: '流速(m/s)',
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
    series: [
      {
        name: '流速',
        type: 'line',
        smooth: true,
        data: currentSpeedData,
        itemStyle: {
          color: '#00e676'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(0, 230, 118, 0.5)' },
            { offset: 1, color: 'rgba(0, 230, 118, 0.1)' }
          ])
        },
        markLine: {
          silent: true,
          lineStyle: {
            color: '#ff5252',
            type: 'dashed'
          },
          data: [
            { yAxis: 0.8, label: { formatter: '警戒值' } }
          ]
        }
      }
    ]
  }
  
  chart.setOption(option)
}

const updateData = (currentData) => {
  if (!currentData) return
  
  const now = new Date()
  const timeStr = now.toLocaleTimeString()
  
  timeData.push(timeStr)
  currentSpeedData.push(parseFloat(currentData.speed))
  
  if (timeData.length > MAX_DATA) {
    timeData.shift()
    currentSpeedData.shift()
  }
  
  if (chart) {
    chart.setOption({
      xAxis: {
        data: timeData
      },
      series: [
        { data: currentSpeedData }
      ]
    })
  }
}

const handleResize = () => {
  if (chart) {
    chart.resize()
  }
}

defineExpose({ updateData })
</script>

<style scoped>
.current-chart {
  width: 100%;
  height: 320px;
}
</style>


